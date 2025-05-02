
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/goal_task.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  final int? highlightedTaskId;

  const GoalDetailScreen({
    Key? key,
    required this.goal,
    this.highlightedTaskId,
  }) : super(key: key);

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalTaskService _apiService = GoalTaskService();
  late Future<Map<String, List<TaskModel>>> _tasksFuture;

  // For task highlighting
  int? _highlightedTaskId;
  bool _isHighlighting = false;
  final ScrollController _activeTasksScrollController = ScrollController();
  final ScrollController _completedTasksScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<TaskModel> _filteredActiveTasks = [];
  List<TaskModel> _filteredCompletedTasks = [];
  Map<String, List<TaskModel>> _allTasks = {"active": [], "completed": []};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);

    // Check if we need to highlight a task
    if (widget.highlightedTaskId != null) {
      _highlightedTaskId = widget.highlightedTaskId;
      _isHighlighting = true;

      // Schedule scrolling to the highlighted task after the UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedTask();

        // Set a timer to remove the highlighting after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isHighlighting = false;
            });
          }
        });
      });
    }
  }

  // Method to scroll to the highlighted task
  void _scrollToHighlightedTask() {
    if (_highlightedTaskId == null) return;

    // Check if the task is in the active tasks list
    int activeIndex = _allTasks["active"]!.indexWhere((task) => task.id == _highlightedTaskId);
    if (activeIndex != -1) {
      // Calculate the position to scroll to
      double position = activeIndex * 60.0; // Approximate height of each row

      // Scroll to the position with animation
      _activeTasksScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Check if the task is in the completed tasks list
    int completedIndex = _allTasks["completed"]!.indexWhere((task) => task.id == _highlightedTaskId);
    if (completedIndex != -1) {
      // Calculate the position to scroll to
      double position = completedIndex * 60.0; // Approximate height of each row

      // Scroll to the position with animation
      _completedTasksScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
    _tasksFuture.then((tasks) {
      // Sort active tasks by dateCreated in descending order (newest first)
      if (tasks["active"] != null && tasks["active"]!.isNotEmpty) {
        tasks["active"]!.sort((a, b) {
          DateTime dateA = DateTime.parse(a.dateCreated);
          DateTime dateB = DateTime.parse(b.dateCreated);
          return dateB.compareTo(dateA); // Descending order (newest first)
        });
      }

      setState(() {
        _allTasks = tasks;
        _filterTasks(_searchController.text);

        // If we have a highlighted task ID, check if it's in the loaded tasks
        if (_highlightedTaskId != null && _isHighlighting) {
          // Schedule scrolling to the highlighted task
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToHighlightedTask();
          });
        }
      });
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    _filterTasks(query);
  }

  void _filterTasks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredActiveTasks = _allTasks["active"] ?? [];
        _filteredCompletedTasks = _allTasks["completed"] ?? [];
      });
    } else {
      setState(() {
        _filteredActiveTasks = _allTasks["active"]?.where((task) {
          return task.title.toLowerCase().contains(query) ||
              task.status.toLowerCase().contains(query) ||
              task.priority.toLowerCase().contains(query) ||
              (task.dueDate != null && task.dueDate!.toString().contains(query));
        }).toList() ??
            [];
        _filteredCompletedTasks = _allTasks["completed"]?.where((task) {
          return task.title.toLowerCase().contains(query) ||
              task.status.toLowerCase().contains(query) ||
              task.priority.toLowerCase().contains(query) ||
              (task.dueDate != null && task.dueDate!.toString().contains(query));
        }).toList() ??
            [];
      });
    }

    // Ensure active tasks maintain their sort order (newest first)
    if (_filteredActiveTasks.isNotEmpty) {
      _filteredActiveTasks.sort((a, b) {
        DateTime dateA = DateTime.parse(a.dateCreated);
        DateTime dateB = DateTime.parse(b.dateCreated);
        return dateB.compareTo(dateA); // Descending order (newest first)
      });
    }
  }

  void _toggleTaskCompletion(TaskModel task) async {
    String newStatus = task.status == "completed" ? "pending" : "completed";

    // If task is being marked as completed, remove any reminder
    bool? hasReminder = newStatus == "completed" ? false : task.hasReminder;
    DateTime? reminderDateTime = newStatus == "completed" ? null : task.reminderDateTime;

    try {
      await _apiService.updateTask(
        task.id,
        task.title,
        task.priority,
        task.dueDate!,
        newStatus,
        widget.goal.id,
        widget.goal.user,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime,
      );

      // If the task was completed, remove any associated notification
      if (newStatus == "completed" && task.hasReminder) {
        try {
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          await notificationProvider.removeTaskReminderNotification(task.id);
        } catch (e) {
          print('Warning: Could not access NotificationProvider to remove notification: $e');
          // Continue even if notification removal fails
        }
      }

      _loadTasks();
    } catch (e) {
      _showErrorDialog("Failed to update task: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Error", style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColoredLabel(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'on_hold':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  // Helper function to format TimeOfDay to 12-hour format with AM/PM
  String _formatTimeOfDayTo12Hour(TimeOfDay timeOfDay) {
    final int hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final String minute = timeOfDay.minute < 10 ? '0${timeOfDay.minute}' : '${timeOfDay.minute}';
    final String period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  void _addTask() async {
  TextEditingController titleController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();
  String selectedPriority = "medium";
  String selectedStatus = "pending";
  DateTime selectedDate = DateTime.now();

  // Reminder variables
  bool? hasReminder = false;
  DateTime? reminderDateTime;

  // For time picker with AM/PM format
  TimeOfDay? reminderTime = TimeOfDay.now();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text("Add Task", style: TextStyle(color: Colors.indigo)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: TextStyle(color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: dueDateController,
                    decoration: InputDecoration(
                      labelText: "Due Date",
                      labelStyle: TextStyle(color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: ColorScheme.light(primary: Colors.indigo),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: "Priority",
                      labelStyle: TextStyle(color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['low', 'medium', 'high'].map((String priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority.toUpperCase(), style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedPriority = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: "Status",
                      labelStyle: TextStyle(color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['pending', 'in_progress', 'on_hold', 'cancelled', 'completed']
                        .map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedStatus = newValue!;

                        // If task is marked as completed, disable reminder
                        if (selectedStatus == "completed") {
                          hasReminder = false;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 24),

                  // Only show reminder toggle for non-completed tasks
                  if (selectedStatus != "completed")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications, color: Color(0xFF255DE1)),
                            SizedBox(width: 8),
                            Text(
                              'Set Reminder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: hasReminder ?? false,
                          activeColor: Color(0xFF255DE1),
                          onChanged: (value) {
                            setStateDialog(() {
                              hasReminder = value;
                              if (value && reminderDateTime == null) {
                                // Set a default reminder time (current time + 2 minutes)
                                reminderDateTime = DateTime.now().add(const Duration(minutes: 2));
                                reminderTime = TimeOfDay.fromDateTime(reminderDateTime!);
                              }
                            });
                          },
                        ),
                      ],
                    ),

                  // Show reminder date/time picker if reminder is enabled
                  if ((hasReminder ?? false) && selectedStatus != "completed") ...[
                    SizedBox(height: 16),
                    // Reminder Date and Time
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          // Date Picker
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reminderDateTime != null
                                      ? DateFormat('MMM d, yyyy').format(reminderDateTime!)
                                      : 'Select Date',
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Get current date/time for validation
                                  final DateTime now = DateTime.now();

                                  // Show date picker with current date as minimum
                                  DateTime initialDate;
                                  if (reminderDateTime != null) {
                                    // If reminder date is in the past, use current date
                                    initialDate = reminderDateTime!.isBefore(now) ? now : reminderDateTime!;
                                  } else {
                                    initialDate = now;
                                  }

                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: now, // Can't pick dates in the past
                                    lastDate: DateTime(2100),
                                  );

                                  if (pickedDate != null) {
                                    // Combine the picked date with the current time
                                    final TimeOfDay currentTime = reminderTime ?? TimeOfDay.now();

                                    // Create a new DateTime with the picked date and current time
                                    final newDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      currentTime.hour,
                                      currentTime.minute,
                                    );

                                    setStateDialog(() {
                                      reminderDateTime = newDateTime;
                                    });
                                  }
                                },
                                child: Text('Change'),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Time Picker
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reminderTime != null
                                      ? _formatTimeOfDayTo12Hour(reminderTime!)
                                      : 'Select Time',
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Show time picker with 12-hour format
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: reminderTime ?? TimeOfDay.now(),
                                    builder: (BuildContext context, Widget? child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: false, // Use 12-hour format
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (pickedTime != null) {
                                    // Update the time part of the reminderDateTime
                                    DateTime newDateTime;
                                    if (reminderDateTime != null) {
                                      newDateTime = DateTime(
                                        reminderDateTime!.year,
                                        reminderDateTime!.month,
                                        reminderDateTime!.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                    } else {
                                      // If no date was set yet, use today's date
                                      final now = DateTime.now();
                                      newDateTime = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                    }

                                    setStateDialog(() {
                                      reminderTime = pickedTime;
                                      reminderDateTime = newDateTime;
                                    });
                                  }
                                },
                                child: Text('Change'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    _showErrorDialog("Title is required.");
                    return;
                  }
                  if (dueDateController.text.isEmpty) {
                    _showErrorDialog("Due Date is required.");
                    return;
                  }

                  // Validate reminder time is in the future
                  if ((hasReminder ?? false) && reminderDateTime != null) {
                    final now = DateTime.now();
                    if (reminderDateTime!.isBefore(now)) {
                      _showErrorDialog("Reminder time must be in the future.");
                      return;
                    }
                  }

                  try {
                    // Create the task with reminder information
                    final task = await _apiService.createTaskForGoal(
                      titleController.text,
                      selectedPriority,
                      dueDateController.text,
                      selectedStatus,
                      widget.goal.id,
                      widget.goal.user, // Pass the user ID
                      hasReminder: hasReminder,
                      reminderDateTime: reminderDateTime,
                    );

                    // Add notification if reminder is set
                    if ((hasReminder ?? false) && reminderDateTime != null) {
                      try {
                        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                        // Create a GoalTask object for the notification
                        final goalTask = GoalTask(
                          id: task.id,
                          title: task.title,
                          status: task.status,
                          priority: task.priority,
                          dueDate: task.dueDate != null ? DateTime.parse(task.dueDate) : null,
                          dateCreated: DateTime.parse(task.dateCreated),
                          goal: widget.goal.id,
                          hasReminder: task.hasReminder,
                          reminderDateTime: task.reminderDateTime,
                        );

                        await notificationProvider.addGoalTaskReminderNotification(goalTask);
                      } catch (e) {
                        print('Warning: Could not access NotificationProvider: $e');
                        // Continue without adding notification
                      }
                    }

                    Navigator.pop(context);
                    // Reload tasks to show the new task at the top of the active tasks list
                    _loadTasks();
                  } catch (e) {
                    _showErrorDialog("Failed to create task: $e");
                  }
                },
                child: Text("Add", style: TextStyle(color: Colors.indigo)),
              ),
            ],
          );
        }
      );
    },
  );
}



  void _updateTask(TaskModel task) async {
    DateTime selectedDate;
    if (task.dueDate is String) {
      selectedDate = DateTime.parse(task.dueDate as String);
    } else if (task.dueDate is DateTime) {
      selectedDate = task.dueDate as DateTime;
    } else {
      selectedDate = DateTime.now();
    }

    // Initialize due date text.
    String dueDateText = "";
    if (task.dueDate != null) {
      if (task.dueDate is String) {
        dueDateText =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(task.dueDate as String));
      } else if (task.dueDate is DateTime) {
        dueDateText = DateFormat('yyyy-MM-dd').format(task.dueDate as DateTime);
      }
    }

    TextEditingController titleController =
        TextEditingController(text: task.title);
    TextEditingController dueDateController =
        TextEditingController(text: dueDateText);
    String selectedPriority = task.priority;
    String selectedStatus = task.status;

    // Reminder variables
    bool? hasReminder = task.hasReminder;
    DateTime? reminderDateTime = task.reminderDateTime;

    // For time picker with AM/PM format
    TimeOfDay? reminderTime = reminderDateTime != null
        ? TimeOfDay(hour: reminderDateTime.hour, minute: reminderDateTime.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text("Update Task", style: TextStyle(color: Colors.indigo)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        labelStyle: TextStyle(color: Colors.indigo),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: dueDateController,
                      decoration: InputDecoration(
                        labelText: "Due Date",
                        labelStyle: TextStyle(color: Colors.indigo),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(primary: Colors.indigo),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDate = pickedDate;
                            dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        labelText: "Priority",
                        labelStyle: TextStyle(color: Colors.indigo),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['low', 'medium', 'high'].map((String priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority.toUpperCase(), style: TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateDialog(() {
                            selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Status",
                        labelStyle: TextStyle(color: Colors.indigo),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['pending', 'in_progress', 'on_hold', 'cancelled', 'completed']
                          .map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateDialog(() {
                            selectedStatus = newValue;

                            // If task is marked as completed, disable reminder
                            if (selectedStatus == "completed") {
                              hasReminder = false;
                            }
                          });
                        }
                      },
                    ),
                    SizedBox(height: 24),

                    // Only show reminder toggle for non-completed tasks
                    if (selectedStatus != "completed")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications, color: Color(0xFF255DE1)),
                              SizedBox(width: 8),
                              Text(
                                'Set Reminder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: hasReminder ?? false,
                            activeColor: Color(0xFF255DE1),
                            onChanged: (value) {
                              setStateDialog(() {
                                hasReminder = value;
                                if (value && reminderDateTime == null) {
                                  // Set a default reminder time (current time + 2 minutes)
                                  reminderDateTime = DateTime.now().add(const Duration(minutes: 2));
                                  reminderTime = TimeOfDay.fromDateTime(reminderDateTime!);
                                }
                              });
                            },
                          ),
                        ],
                      ),

                    // Show reminder date/time picker if reminder is enabled
                    if ((hasReminder ?? false) && selectedStatus != "completed") ...[
                      SizedBox(height: 16),
                      // Reminder Date and Time
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            // Date Picker
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reminderDateTime != null
                                        ? DateFormat('MMM d, yyyy').format(reminderDateTime!)
                                        : 'Select Date',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Get current date/time for validation
                                    final DateTime now = DateTime.now();

                                    // Show date picker with current date as minimum
                                    DateTime initialDate;
                                    if (reminderDateTime != null) {
                                      // If reminder date is in the past, use current date
                                      initialDate = reminderDateTime!.isBefore(now) ? now : reminderDateTime!;
                                    } else {
                                      initialDate = now;
                                    }

                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: now, // Can't pick dates in the past
                                      lastDate: DateTime(2100),
                                    );

                                    if (pickedDate != null) {
                                      // Combine the picked date with the current time
                                      final TimeOfDay currentTime = reminderTime ?? TimeOfDay.now();

                                      // Create a new DateTime with the picked date and current time
                                      final newDateTime = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        currentTime.hour,
                                        currentTime.minute,
                                      );

                                      setStateDialog(() {
                                        reminderDateTime = newDateTime;
                                      });
                                    }
                                  },
                                  child: Text('Change'),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Time Picker
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reminderTime != null
                                        ? _formatTimeOfDayTo12Hour(reminderTime!)
                                        : 'Select Time',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Show time picker with 12-hour format
                                    TimeOfDay? pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: reminderTime ?? TimeOfDay.now(),
                                      builder: (BuildContext context, Widget? child) {
                                        return MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                            alwaysUse24HourFormat: false, // Use 12-hour format
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedTime != null) {
                                      // Update the time part of the reminderDateTime
                                      DateTime newDateTime;
                                      if (reminderDateTime != null) {
                                        newDateTime = DateTime(
                                          reminderDateTime!.year,
                                          reminderDateTime!.month,
                                          reminderDateTime!.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      } else {
                                        // If no date was set yet, use today's date
                                        final now = DateTime.now();
                                        newDateTime = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      }

                                      setStateDialog(() {
                                        reminderTime = pickedTime;
                                        reminderDateTime = newDateTime;
                                      });
                                    }
                                  },
                                  child: Text('Change'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      _showErrorDialog("Title is required.");
                      return;
                    }

                    // Validate reminder time is in the future
                    if ((hasReminder ?? false) && reminderDateTime != null) {
                      final now = DateTime.now();
                      if (reminderDateTime!.isBefore(now)) {
                        _showErrorDialog("Reminder time must be in the future.");
                        return;
                      }
                    }

                    try {
                      // Check if reminder status has changed
                      bool reminderChanged = task.hasReminder != hasReminder ||
                          (task.reminderDateTime?.toString() != reminderDateTime?.toString());

                      // Update the task with reminder information
                      await _apiService.updateTask(
                        task.id,
                        titleController.text,
                        selectedPriority,
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        selectedStatus,
                        widget.goal.id, // Pass the goal ID
                        widget.goal.user, // Pass the user ID
                        hasReminder: hasReminder,
                        reminderDateTime: reminderDateTime,
                      );

                      // Update notification if reminder is set or removed
                      if (reminderChanged) {
                        try {
                          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                          // If reminder is enabled, add or update notification
                          if ((hasReminder ?? false) && reminderDateTime != null) {
                            // Create a GoalTask object for the notification
                            final updatedTask = GoalTask(
                              id: task.id,
                              title: titleController.text,
                              status: selectedStatus,
                              priority: selectedPriority,
                              dueDate: selectedDate,
                              dateCreated: DateTime.parse(task.dateCreated),
                              goal: widget.goal.id,
                              hasReminder: hasReminder ?? false,
                              reminderDateTime: reminderDateTime,
                            );

                            await notificationProvider.addGoalTaskReminderNotification(updatedTask);
                          } else {
                            // If reminder was removed, remove any existing notification
                            await notificationProvider.removeTaskReminderNotification(task.id);
                          }
                        } catch (e) {
                          print('Warning: Could not access NotificationProvider to update notification: $e');
                          // Continue with task update even if notification update fails
                        }
                      }

                      Navigator.pop(context);
                      _loadTasks();
                    } catch (e) {
                      _showErrorDialog("Failed to update task: $e");
                    }
                  },
                  child: Text("Update", style: TextStyle(color: Colors.indigo)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteTask(TaskModel task) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Confirm Delete", style: TextStyle(color: Colors.red)),
          content: Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.indigo)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _apiService.deleteTask(task.id);
                  _loadTasks();
                } catch (e) {
                  _showErrorDialog("Failed to delete task: $e");
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }




@override
Widget build(BuildContext context) {
  return CustomScaffold(
    selectedPage: widget.goal.title,
    onItemSelected: (page) {},
    body: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar with Back Arrow, Goal Title, and Centered Search Bar
            Container(
              color: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back Arrow
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Navigate back
                    },
                  ),
                  // Goal Title
                  Text(
                    widget.goal.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(), // Push the search bar to the center
                  // Centered Search Bar
                  Container(
                    width: 200, // Make the search bar shorter
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: Colors.indigo),
                      ),
                    ),
                  ),
                  Spacer(), // Push the search bar to the center

                ],
              ),
            ),
            // Task List
            Expanded(
              child: FutureBuilder<Map<String, List<TaskModel>>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Error: ${snapshot.error}",
                              style: TextStyle(color: Colors.red)),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Check if both active and completed task lists are empty.
                    if (_filteredActiveTasks.isEmpty &&
                        _filteredCompletedTasks.isEmpty) {
                      return Center(
                        child: Text(
                          "No task available",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Tasks Section
                          if (_filteredActiveTasks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Active Tasks",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  controller: _activeTasksScrollController,
                                  child: DataTable(
                                    headingRowColor:
                                        MaterialStateProperty.all(Colors.indigo[50]),
                                  columns: [
                                    DataColumn(label: Text("")),
                                    DataColumn(label: Text("Task Title")),
                                    DataColumn(label: Text("Status")),
                                    DataColumn(label: Text("Priority")),
                                    DataColumn(label: Text("Due Date")),
                                    DataColumn(label: Text("Reminder")),
                                    DataColumn(label: Text("Actions")),
                                  ],
                                  rows: _filteredActiveTasks.map((task) {
                                    return DataRow(
                                      color: _highlightedTaskId == task.id && _isHighlighting
                                          ? MaterialStateProperty.all(Colors.red.withOpacity(0.2))
                                          : null,
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            activeColor: Colors.indigo,
                                            value: task.status == "completed",
                                            onChanged: (bool? value) {
                                              _toggleTaskCompletion(task);
                                            },
                                          ),
                                        ),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 150),
                                            child: _highlightedTaskId == task.id && _isHighlighting
                                                ? Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.red, width: 2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      task.title,
                                                      overflow: TextOverflow.visible,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    task.title,
                                                    overflow: TextOverflow.visible,
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                          ),
                                        ),
                                        DataCell(_buildColoredLabel(
                                            task.status,
                                            _getStatusColor(task.status))),
                                        DataCell(_buildColoredLabel(
                                            task.priority,
                                            _getPriorityColor(task.priority))),
                                        DataCell(
                                          Text(
                                            task.dueDate != null
                                                ? DateFormat('yyyy-MM-dd').format(
                                                    task.dueDate is String
                                                        ? DateTime.parse(
                                                            task.dueDate as String)
                                                        : task.dueDate as DateTime)
                                                : "No Due Date",
                                          ),
                                        ),
                                        DataCell(
                                          task.hasReminder && task.reminderDateTime != null
                                              ? Row(
                                                  children: [
                                                    Icon(
                                                      Icons.notifications_active,
                                                      color: Colors.orange,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      DateFormat('MMM d, h:mm a').format(task.reminderDateTime!),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  "None",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.indigo),
                                                onPressed: () =>
                                                    _updateTask(task),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteTask(task),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          // Completed Tasks Section
                          if (_filteredCompletedTasks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Completed Tasks",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  controller: _completedTasksScrollController,
                                  child: DataTable(
                                    headingRowColor:
                                        MaterialStateProperty.all(Colors.indigo[50]),
                                  columns: [
                                    DataColumn(label: Text("")),
                                    DataColumn(label: Text("Task Title")),
                                    DataColumn(label: Text("Status")),
                                    DataColumn(label: Text("Priority")),
                                    DataColumn(label: Text("Due Date")),
                                    DataColumn(label: Text("Actions")),
                                  ],
                                  rows: _filteredCompletedTasks.map((task) {
                                    return DataRow(
                                      color: _highlightedTaskId == task.id && _isHighlighting
                                          ? MaterialStateProperty.all(Colors.red.withOpacity(0.2))
                                          : null,
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            activeColor: Colors.indigo,
                                            value: task.status == "completed",
                                            onChanged: (bool? value) {
                                              _toggleTaskCompletion(task);
                                            },
                                          ),
                                        ),
                                        DataCell(
                                          _highlightedTaskId == task.id && _isHighlighting
                                              ? Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.red, width: 2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    task.title,
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                )
                                              : Text(task.title)
                                        ),
                                        DataCell(_buildColoredLabel(
                                            task.status,
                                            _getStatusColor(task.status))),
                                        DataCell(_buildColoredLabel(
                                            task.priority,
                                            _getPriorityColor(task.priority))),
                                        DataCell(
                                          Text(
                                            task.dueDate != null
                                                ? DateFormat('yyyy-MM-dd').format(
                                                    task.dueDate is String
                                                        ? DateTime.parse(
                                                            task.dueDate as String)
                                                        : task.dueDate as DateTime)
                                                : "No Due Date",
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.indigo),
                                                onPressed: () =>
                                                    _updateTask(task),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteTask(task),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.indigo,
            onPressed: _addTask,
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

}