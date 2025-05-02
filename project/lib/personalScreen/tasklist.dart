
import 'package:flutter/material.dart';
import 'package:project/services/api_task.dart';
import 'package:project/models/task_model.dart';
import 'package:project/models/goals_model.dart'; // Your goal model file.
import 'package:project/services/goal_service.dart'; // Your GoalService.
import 'package:project/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';  // Import the intl package
import 'package:project/personalScreen/goal_task_detail.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/notification_model.dart';


class TaskScreen extends StatefulWidget {
  final int? highlightedTaskId;
  final int? highlightedGoalId;

  const TaskScreen({Key? key, this.highlightedTaskId, this.highlightedGoalId}) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Future<Map<String, List<TaskModel>>> _tasksFuture;
  late Future<List<Goal>> _goalsFuture;

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Scroll controller for the task tables
  final ScrollController _activeTasksScrollController = ScrollController();
  final ScrollController _completedTasksScrollController = ScrollController();

  List<TaskModel> _filteredActiveTasks = [];
  List<TaskModel> _filteredCompletedTasks = [];
  Map<String, List<TaskModel>> _allTasks = {"active": [], "completed": []};

  // Variables to track the highlighted task and goal
  int? _highlightedTaskId;
  int? _highlightedGoalId;
  // Animation controller for the highlighted elements
  bool _isHighlighting = false;

  // Goals state variables.
  List<Goal> _allGoals = [];
  List<Goal> _filteredGoals = [];

  // Scroll controller for goals
  final ScrollController _goalsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Set the highlighted IDs from the widget parameters
    _highlightedTaskId = widget.highlightedTaskId;
    _highlightedGoalId = widget.highlightedGoalId;

    // If a task or goal is highlighted, set the highlighting flag
    if (_highlightedTaskId != null || _highlightedGoalId != null) {
      _isHighlighting = true;

      // Schedule to turn off highlighting after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isHighlighting = false;
          });
        }
      });
    }

    _loadTasks();
    _loadGoals();
    _searchController.addListener(_onSearchChanged);

    // Wait for the UI to build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If a task is highlighted, scroll to it
      if (_highlightedTaskId != null) {
        _scrollToHighlightedTask();
      }

      // If a goal is highlighted, scroll to it
      if (_highlightedGoalId != null) {
        _scrollToHighlightedGoal();
      }
    });
  }

  // Method to scroll to the highlighted task
  void _scrollToHighlightedTask() {
    if (_highlightedTaskId == null) return;

    // Find the task in active tasks
    int activeIndex = _filteredActiveTasks.indexWhere((task) => task.id == _highlightedTaskId);

    if (activeIndex != -1) {
      // Task is in active tasks, scroll to it
      // Calculate the position (each row is approximately 70 pixels high)
      double position = activeIndex * 70.0;

      // Scroll to the position with animation
      _activeTasksScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Check if task is in completed tasks
      int completedIndex = _filteredCompletedTasks.indexWhere((task) => task.id == _highlightedTaskId);

      if (completedIndex != -1) {
        // Task is in completed tasks, scroll to it
        // First scroll to the completed tasks section
        // Then scroll to the specific task

        // Scroll to the completed tasks section first
        _activeTasksScrollController.animateTo(
          _activeTasksScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ).then((_) {
          // Then scroll to the specific task in the completed tasks
          double position = completedIndex * 70.0;

          _completedTasksScrollController.animateTo(
            position,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  // Method to scroll to the highlighted goal
  void _scrollToHighlightedGoal() {
    if (_highlightedGoalId == null || _filteredGoals.isEmpty) return;

    // Find the index of the highlighted goal
    int goalIndex = _filteredGoals.indexWhere((goal) => goal.id == _highlightedGoalId);

    if (goalIndex != -1) {
      // Calculate the position (each goal card is approximately 100 pixels wide plus margin)
      double position = goalIndex * 120.0;

      // Scroll to the position with animation
      _goalsScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _activeTasksScrollController.dispose();
    _completedTasksScrollController.dispose();
    _goalsScrollController.dispose();

    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _apiService.fetchTasks();
    _tasksFuture.then((tasks) {
      setState(() {
        _allTasks = tasks;
        _filterTasks(_searchController.text);
      });

      // If a task is highlighted, try to scroll to it after tasks are loaded
      if (_highlightedTaskId != null) {
        // Wait for the UI to update with the new tasks
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToHighlightedTask();
          }
        });
      }
    });
  }

  void _loadGoals() {
    _goalsFuture = GoalService.fetchGoals();
    _goalsFuture.then((goals) {
      setState(() {
        _allGoals = goals;
        _filteredGoals = goals;
      });

      // If a goal is highlighted, try to scroll to it after goals are loaded
      if (_highlightedGoalId != null) {
        // Wait for the UI to update with the new goals
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToHighlightedGoal();
          }
        });
      }
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text;
    _filterTasks(query);
    _filterGoals(query);
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
          final lowerQuery = query.toLowerCase();
          return task.title.toLowerCase().contains(lowerQuery) ||
              task.status.toLowerCase().contains(lowerQuery) ||
              task.priority.toLowerCase().contains(lowerQuery) ||
              task.dueDate.toLowerCase().contains(lowerQuery);
        }).toList() ??
            [];
        _filteredCompletedTasks = _allTasks["completed"]?.where((task) {
          final lowerQuery = query.toLowerCase();
          return task.title.toLowerCase().contains(lowerQuery) ||
              task.status.toLowerCase().contains(lowerQuery) ||
              task.priority.toLowerCase().contains(lowerQuery) ||
              task.dueDate.toLowerCase().contains(lowerQuery);
        }).toList() ??
            [];
      });
    }
  }

  void _filterGoals(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredGoals = _allGoals;
      });
    } else {
      setState(() {
        _filteredGoals = _allGoals.where((goal) {
          return goal.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
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
                          child: Text(priority, style: TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedPriority = newValue!;
                        });
                      },
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
                                        ? formatTimeOfDayTo12Hour(reminderTime!)
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

                    // Create the task
                    final task = await _apiService.createTask(
                      titleController.text,
                      selectedPriority,
                      dueDateController.text,
                      selectedStatus,
                      hasReminder: hasReminder,
                      reminderDateTime: reminderDateTime,
                    );

                    // Add notification if reminder is set
                    if ((hasReminder ?? false) && reminderDateTime != null) {
                      try {
                        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                        await notificationProvider.addTaskReminderNotification(task);
                      } catch (e) {
                        print('Warning: Could not access NotificationProvider: $e');
                        // Continue without adding notification
                      }
                    }

                    Navigator.pop(context);
                    _loadTasks();
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

  void _deleteTask(int id) async {
    await _apiService.deleteTask(id);
    _loadTasks();
  }

  void _updateTask(TaskModel task) async {
    TextEditingController titleController = TextEditingController(text: task.title);
    TextEditingController dueDateController = TextEditingController(text: task.dueDate);
    String selectedPriority = task.priority;
    String selectedStatus = task.status;
    DateTime selectedDate = DateTime.parse(task.dueDate);

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
                          child: Text(priority, style: TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedPriority = newValue!;
                        });
                      },
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
                            dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                            selectedDate = pickedDate;
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
                                        ? formatTimeOfDayTo12Hour(reminderTime!)
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

                    // Check if reminder status has changed
                    bool reminderChanged = task.hasReminder != hasReminder ||
                        (task.reminderDateTime?.toString() != reminderDateTime?.toString());

                    // Update the task
                    await _apiService.updateTask(
                      task.id,
                      titleController.text,
                      selectedPriority,
                      dueDateController.text,
                      selectedStatus,
                      hasReminder: hasReminder,
                      reminderDateTime: reminderDateTime,
                    );

                    // Update notification if reminder is set or removed
                    if (reminderChanged) {
                      try {
                        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                        // If reminder is enabled, add or update notification
                        if ((hasReminder ?? false) && reminderDateTime != null) {
                          // Create a temporary task model with updated values for the notification
                          final updatedTask = TaskModel(
                            id: task.id,
                            title: titleController.text,
                            status: selectedStatus,
                            priority: selectedPriority,
                            dueDate: dueDateController.text,
                            dateCreated: task.dateCreated,
                            hasReminder: hasReminder,
                            reminderDateTime: reminderDateTime,
                          );

                          await notificationProvider.addTaskReminderNotification(updatedTask);
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

  /// Helpers for colored labels
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

  /// Returns a widget with a colored box (label style) for status or priority
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

  void _toggleTaskCompletion(TaskModel task) async {
    String newStatus = task.status == "completed" ? "pending" : "completed";

    // If task is being marked as completed, remove any reminder
    bool? hasReminder = newStatus == "completed" ? false : task.hasReminder;
    DateTime? reminderDateTime = newStatus == "completed" ? null : task.reminderDateTime;

    await _apiService.updateTask(
      task.id,
      task.title,
      task.priority,
      task.dueDate,
      newStatus,
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
  }


 Widget _buildGoalCard(Goal goal) {
    // Check if this goal should be highlighted
    bool shouldHighlight = _highlightedGoalId == goal.id && _isHighlighting;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailScreen(goal: goal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Card(
          elevation: shouldHighlight ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: shouldHighlight
                ? BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              goal.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.w500,
                color: shouldHighlight ? Colors.red : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the goals section.
  Widget _buildGoalsSection() {
    if (_filteredGoals.isEmpty) return SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.indigo),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Goals",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: Scrollbar(
              controller: _goalsScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _goalsScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _filteredGoals.length,
                itemBuilder: (context, index) {
                  final goal = _filteredGoals[index];
                  return _buildGoalCard(goal);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScaffold(
          selectedPage: "Task List",
          onItemSelected: (page) {
            setState(() {}); // Navigate between pages if needed
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header bar with left "Task List" and centered search bar.
              Container(
                color: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Task List",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 300,
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
                    ),
                  ],
                ),
              ),
              // Goals section right below the header.
              _buildGoalsSection(),
              // Tasks section
              Expanded(
                child: FutureBuilder<Map<String, List<TaskModel>>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error loading tasks"));
                    } else {
                      final activeTasks = _filteredActiveTasks;
                      final completedTasks = _filteredCompletedTasks;

                      if (activeTasks.isEmpty && completedTasks.isEmpty) {
                        return Center(
                          child: Text(
                            "No tasks available",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        controller: _activeTasksScrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Active Tasks Section
                            if (activeTasks.isNotEmpty) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    "Active Tasks",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                                  ),
                                ),
                              ),
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.75, // Responsive width based on screen size
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(Colors.indigo[50]),
                                      columnSpacing: 8, // Minimal spacing between columns
                                      horizontalMargin: 12,
                                      // Set a fixed height for rows
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 80,
                                    columns: [
                                      DataColumn(
                                        label: Container(
                                          width: 40, // Checkbox column
                                          child: Text(
                                            "",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 150, // Task title column
                                          child: Text(
                                            "Task Title",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 140, // Date created column
                                          child: Text(
                                            "Date Created",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Status column
                                          child: Text(
                                            "Status",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 80, // Priority column
                                          child: Text(
                                            "Priority",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Due date column
                                          child: Text(
                                            "Due Date",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 140, // Reminder column
                                          child: Text(
                                            "Reminder",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Actions column
                                          child: Text(
                                            "Actions",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: activeTasks.map(
                                      (task) => DataRow(
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
                                          DataCell(
                                            Text(
                                              DateFormat('yyyy-MM-dd hh:mm:ss a')
                                                  .format(DateTime.parse(task.dateCreated).toLocal()),
                                            ),
                                          ),
                                          DataCell(
                                            _buildColoredLabel(
                                              task.status,
                                              _getStatusColor(task.status),
                                            ),
                                          ),
                                          DataCell(
                                            _buildColoredLabel(
                                              task.priority,
                                              _getPriorityColor(task.priority),
                                            ),
                                          ),
                                          DataCell(Text(task.dueDate)),
                                          DataCell(
                                            task.hasReminder && task.reminderDateTime != null
                                                ? Row(
                                                    children: [
                                                      Icon(Icons.notifications_active,
                                                           color: Colors.indigo,
                                                           size: 16),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        DateFormat('MMM d, yyyy - hh:mm a')
                                                            .format(task.reminderDateTime!),
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  )
                                                : Text('None'),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _updateTask(task),
                                                  ),
                                                  SizedBox(width: 4),
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _deleteTask(task.id),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            // Completed Tasks Section
                            if (completedTasks.isNotEmpty) ...[
                              SizedBox(height: 20),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    "Completed Tasks",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                                  ),
                                ),
                              ),
                              Center(
                                child: SingleChildScrollView(
                                  controller: _completedTasksScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.65, // Reduced width since we removed the reminder column
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(Colors.indigo[50]),
                                      columnSpacing: 8, // Minimal spacing between columns
                                      horizontalMargin: 12,
                                      // Set a fixed height for rows
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 80,
                                    columns: [
                                      DataColumn(
                                        label: Container(
                                          width: 40, // Checkbox column
                                          child: Text(
                                            "",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 180, // Task title column - increased width
                                          child: Text(
                                            "Task Title",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 140, // Date created column
                                          child: Text(
                                            "Date Created",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Status column
                                          child: Text(
                                            "Status",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 80, // Priority column
                                          child: Text(
                                            "Priority",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Due date column
                                          child: Text(
                                            "Due Date",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100, // Actions column
                                          child: Text(
                                            "Actions",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: completedTasks.map(
                                      (task) => DataRow(
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
                                          DataCell(
                                            Text(
                                              DateFormat('yyyy-MM-dd hh:mm:ss a')
                                                  .format(DateTime.parse(task.dateCreated).toLocal()),
                                            ),
                                          ),
                                          DataCell(
                                            _buildColoredLabel(
                                              task.status,
                                              _getStatusColor(task.status),
                                            ),
                                          ),
                                          DataCell(
                                            _buildColoredLabel(
                                              task.priority,
                                              _getPriorityColor(task.priority),
                                            ),
                                          ),
                                          DataCell(Text(task.dueDate)),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _updateTask(task),
                                                  ),
                                                  SizedBox(width: 4),
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _deleteTask(task.id),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
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
        ),
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
    );
  }
}





// ============================================================================================================================================

// Helper function to format TimeOfDay to 12-hour format with AM/PM
String formatTimeOfDayTo12Hour(TimeOfDay timeOfDay) {
  final int hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
  final String minute = timeOfDay.minute < 10 ? '0${timeOfDay.minute}' : '${timeOfDay.minute}';
  final String period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

