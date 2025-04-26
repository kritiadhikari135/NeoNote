
import 'package:flutter/material.dart';
import 'package:project/services/api_task.dart';
import 'package:project/models/task_model.dart';
import 'package:project/models/goals_model.dart'; // Your goal model file.
import 'package:project/services/goal_service.dart'; // Your GoalService.
import 'package:project/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';  // Import the intl package
import 'package:project/personalScreen/goal_task_detail.dart';


class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Future<Map<String, List<TaskModel>>> _tasksFuture;
  late Future<List<Goal>> _goalsFuture;

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<TaskModel> _filteredActiveTasks = [];
  List<TaskModel> _filteredCompletedTasks = [];
  Map<String, List<TaskModel>> _allTasks = {"active": [], "completed": []};

  // Goals state variables.
  List<Goal> _allGoals = [];
  List<Goal> _filteredGoals = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadGoals();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _apiService.fetchTasks();
    _tasksFuture.then((tasks) {
      setState(() {
        _allTasks = tasks;
        _filterTasks(_searchController.text);
      });
    });
  }

  void _loadGoals() {
    _goalsFuture = GoalService.fetchGoals();
    _goalsFuture.then((goals) {
      setState(() {
        _allGoals = goals;
        _filteredGoals = goals;
      });
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Add Task", style: TextStyle(color: Colors.indigo)),
          content: Column(
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
                  setState(() {
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
                    setState(() {
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
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
              ),
            ],
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
                await _apiService.createTask(
                  titleController.text,
                  selectedPriority,
                  dueDateController.text,
                  selectedStatus,
                );
                Navigator.pop(context);
                _loadTasks();
              },
              child: Text("Add", style: TextStyle(color: Colors.indigo)),
            ),
          ],
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Update Task", style: TextStyle(color: Colors.indigo)),
          content: Column(
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
                  setState(() {
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
                    setState(() {
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
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
              ),
            ],
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
                await _apiService.updateTask(
                  task.id,
                  titleController.text,
                  selectedPriority,
                  dueDateController.text,
                  selectedStatus,
                );
                Navigator.pop(context);
                _loadTasks();
              },
              child: Text("Update", style: TextStyle(color: Colors.indigo)),
            ),
          ],
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
    await _apiService.updateTask(
      task.id,
      task.title,
      task.priority,
      task.dueDate,
      newStatus,
    );
    _loadTasks();
  }


 Widget _buildGoalCard(Goal goal) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              goal.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
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
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.indigo[50]),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          "",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Task Title",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Date Created",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Status",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Priority",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Due Date",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Actions",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                    ],
                                    rows: activeTasks.map(
                                      (task) => DataRow(
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
                                          DataCell(Text(task.title)),
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
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Colors.indigo),
                                                  onPressed: () => _updateTask(task),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteTask(task.id),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).toList(),
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
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.indigo[50]),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          "",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Task Title",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Date Created",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Status",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Priority",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Due Date",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Actions",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                        ),
                                      ),
                                    ],
                                    rows: completedTasks.map(
                                      (task) => DataRow(
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
                                          DataCell(Text(task.title)),
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
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Colors.indigo),
                                                  onPressed: () => _updateTask(task),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteTask(task.id),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).toList(),
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

