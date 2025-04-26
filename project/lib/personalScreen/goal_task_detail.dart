
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:project/models/goals_model.dart';
// import 'package:project/models/task_model.dart';
// import 'package:project/services/goal_task.dart';
// import 'package:project/widgets/custom_scaffold.dart'; 

// class GoalDetailScreen extends StatefulWidget {
//   final Goal goal;

//   const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

//   @override
//   _GoalDetailScreenState createState() => _GoalDetailScreenState();
// }


// class _GoalDetailScreenState extends State<GoalDetailScreen> {
//   final GoalTaskService _apiService = GoalTaskService();
//   late Future<Map<String, List<TaskModel>>> _tasksFuture;
//   final TextEditingController _searchController = TextEditingController();
//   List<TaskModel> _filteredTasks = [];
//   List<TaskModel> _allTasks = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadTasks();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _loadTasks() {
//     setState(() {
//       _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
//     });
//     _tasksFuture.then((tasks) {
//       setState(() {
//         _allTasks = [...tasks['active'] ?? [], ...tasks['completed'] ?? []];
//         _filteredTasks = _allTasks;
//       });
//     });
//   }

//   void _onSearchChanged() {
//     String query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredTasks = _allTasks.where((task) {
//         return task.title.toLowerCase().contains(query) ||
//             task.status.toLowerCase().contains(query) ||
//             task.priority.toLowerCase().contains(query) ||
//             (task.dueDate != null && task.dueDate!.toString().contains(query));
//       }).toList();
//     });
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           title: Text("Error", style: TextStyle(color: Colors.red)),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text("OK", style: TextStyle(color: Colors.indigo)),
//             ),
//           ],
//         );
//       },
//     );
//   }


// void _toggleTaskCompletion(TaskModel task) async {
//   String newStatus = task.status == "completed" ? "pending" : "completed";
//   try {
//     await _apiService.updateTask(
//       task.id,
//       task.title,
//       task.priority,
//       task.dueDate!, // Pass the DateTime object directly
//       newStatus,
//       widget.goal.id, // Pass the goal ID
//       widget.goal.user, // Pass the user ID
//     );
//     _loadTasks();
//   } catch (e) {
//     _showErrorDialog("Failed to update task: $e");
//   }
// }

//   Widget _buildColoredLabel(String text, Color textColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: textColor.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: textColor,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'in_progress':
//         return Colors.blue;
//       case 'on_hold':
//         return Colors.grey;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.black;
//     }
//   }

//   Color _getPriorityColor(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high':
//         return Colors.red;
//       case 'medium':
//         return Colors.orange;
//       case 'low':
//         return Colors.green;
//       default:
//         return Colors.black;
//     }
//   }


//   void _addTask() async {
//   TextEditingController titleController = TextEditingController();
//   TextEditingController dueDateController = TextEditingController();
//   String selectedPriority = "medium";
//   String selectedStatus = "pending";
//   DateTime selectedDate = DateTime.now();

//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: Text("Add Task", style: TextStyle(color: Colors.indigo)),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: InputDecoration(
//                   labelText: "Title",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               SizedBox(height: 8),
//               TextField(
//                 controller: dueDateController,
//                 decoration: InputDecoration(
//                   labelText: "Due Date",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 readOnly: true,
//                 onTap: () async {
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2101),
//                     builder: (context, child) {
//                       return Theme(
//                         data: ThemeData.light().copyWith(
//                           colorScheme: ColorScheme.light(primary: Colors.indigo),
//                         ),
//                         child: child!,
//                       );
//                     },
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//                       selectedDate = pickedDate;
//                     });
//                   }
//                 },
//               ),
//               SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: selectedPriority,
//                 decoration: InputDecoration(
//                   labelText: "Priority",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 items: ['low', 'medium', 'high'].map((String priority) {
//                   return DropdownMenuItem<String>(
//                     value: priority,
//                     child: Text(priority.toUpperCase(), style: TextStyle(color: Colors.black)),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     selectedPriority = newValue!;
//                   });
//                 },
//               ),
//               SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: selectedStatus,
//                 decoration: InputDecoration(
//                   labelText: "Status",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 items: ['pending', 'in_progress', 'on_hold', 'cancelled', 'completed']
//                     .map((String status) {
//                   return DropdownMenuItem<String>(
//                     value: status,
//                     child: Text(
//                       status.replaceAll('_', ' ').toUpperCase(),
//                       style: TextStyle(color: Colors.black),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     selectedStatus = newValue!;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               if (titleController.text.isEmpty) {
//                 _showErrorDialog("Title is required.");
//                 return;
//               }
//               if (dueDateController.text.isEmpty) {
//                 _showErrorDialog("Due Date is required.");
//                 return;
//               }
//               try {
//                 await _apiService.createTaskForGoal(
//                   titleController.text,
//                   selectedPriority,
//                   dueDateController.text,
//                   selectedStatus,
//                   widget.goal.id,
//                   widget.goal.user, // Pass the user ID
//                 );
//                 Navigator.pop(context);
//                 _loadTasks();
//               } catch (e) {
//                 _showErrorDialog("Failed to create task: $e");
//               }
//             },
//             child: Text("Add", style: TextStyle(color: Colors.indigo)),
//           ),
//         ],
//       );
//     },
//   );
// }

//   void _updateTask(TaskModel task) async {
 
//     DateTime selectedDate;
//     if (task.dueDate is String) {
//       selectedDate = DateTime.parse(task.dueDate as String);
//     } else if (task.dueDate is DateTime) {
//       selectedDate = task.dueDate as DateTime;
//     } else {
//       selectedDate = DateTime.now();
//     }

//     // Initialize due date text.
//     String dueDateText = "";
//     if (task.dueDate != null) {
//       if (task.dueDate is String) {
//         dueDateText =
//             DateFormat('yyyy-MM-dd').format(DateTime.parse(task.dueDate as String));
//       } else if (task.dueDate is DateTime) {
//         dueDateText = DateFormat('yyyy-MM-dd').format(task.dueDate as DateTime);
//       }
//     }

//     TextEditingController titleController =
//         TextEditingController(text: task.title);
//     TextEditingController dueDateController =
//         TextEditingController(text: dueDateText);
//     String selectedPriority = task.priority;
//     String selectedStatus = task.status;
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: Text("Update Task", style: TextStyle(color: Colors.indigo)),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: InputDecoration(
//                   labelText: "Title",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               SizedBox(height: 8),
//               TextField(
//                 controller: dueDateController,
//                 decoration: InputDecoration(
//                   labelText: "Due Date",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 readOnly: true,
//                 onTap: () async {
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: selectedDate,
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2101),
//                     builder: (context, child) {
//                       return Theme(
//                         data: ThemeData.light().copyWith(
//                           colorScheme: ColorScheme.light(primary: Colors.indigo),
//                         ),
//                         child: child!,
//                       );
//                     },
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       selectedDate = pickedDate;
//                       dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//                     });
//                   }
//                 },
//               ),
//               SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: selectedPriority,
//                 decoration: InputDecoration(
//                   labelText: "Priority",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 items: ['low', 'medium', 'high'].map((String priority) {
//                   return DropdownMenuItem<String>(
//                     value: priority,
//                     child: Text(priority.toUpperCase(), style: TextStyle(color: Colors.black)),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   if (newValue != null) {
//                     setState(() {
//                       selectedPriority = newValue;
//                     });
//                   }
//                 },
//               ),
//               SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: selectedStatus,
//                 decoration: InputDecoration(
//                   labelText: "Status",
//                   labelStyle: TextStyle(color: Colors.indigo),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 items: ['pending', 'in_progress', 'on_hold', 'cancelled', 'completed']
//                     .map((String status) {
//                   return DropdownMenuItem<String>(
//                     value: status,
//                     child: Text(
//                       status.replaceAll('_', ' ').toUpperCase(),
//                       style: TextStyle(color: Colors.black),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   if (newValue != null) {
//                     setState(() {
//                       selectedStatus = newValue;
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               if (titleController.text.isEmpty) {
//                 _showErrorDialog("Title is required.");
//                 return;
//               }
//               try {
//                 await _apiService.updateTask(
//                   task.id,
//                   titleController.text,
//                   selectedPriority,
//                   DateFormat('yyyy-MM-dd').format(selectedDate),
//                   selectedStatus,
//                   widget.goal.id, // Pass the goal ID
//                   widget.goal.user, // Pass the user ID
//                 );
//                 Navigator.pop(context);
//                 _loadTasks();
//               } catch (e) {
//                 _showErrorDialog("Failed to update task: $e");
//               }
//             },
//             child: Text("Update", style: TextStyle(color: Colors.indigo)),
//           ),
//         ],
//       );
//     },
//   );
// }

//   void _deleteTask(TaskModel task) async {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           title: Text("Confirm Delete", style: TextStyle(color: Colors.red)),
//           content: Text("Are you sure you want to delete this task?"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Cancel", style: TextStyle(color: Colors.indigo)),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 try {
//                   await _apiService.deleteTask(task.id);
//                   _loadTasks();
//                 } catch (e) {
//                   _showErrorDialog("Failed to delete task: $e");
//                 }
//               },
//               child: Text("Delete", style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       selectedPage: widget.goal.title,
//       onItemSelected: (page) {},
//       body: Stack(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Search Bar
//               Container(
//                 color: Colors.indigo,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: "Search tasks...",
//                     contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                     prefixIcon: Icon(Icons.search, color: Colors.indigo),
//                   ),
//                 ),
//               ),
//               // Task List
//               Expanded(
//                 child: FutureBuilder<Map<String, List<TaskModel>>>(
//                   future: _tasksFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(child: CircularProgressIndicator());
//                     } else if (snapshot.hasError) {
//                       return Center(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text("Error: ${snapshot.error}",
//                                 style: TextStyle(color: Colors.red)),
//                             SizedBox(height: 8),
//                             ElevatedButton(
//                               onPressed: _loadTasks,
//                               child: Text("Retry"),
//                             ),
//                           ],
//                         ),
//                       );
//                     } else {
//                       if (_filteredTasks.isEmpty) {
//                         return Center(
//                           child: Text(
//                             "No tasks available",
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey),
//                           ),
//                         );
//                       }
//                       return SingleChildScrollView(
//                         child: DataTable(
//                           headingRowColor:
//                               MaterialStateProperty.all(Colors.indigo[50]),
//                           columns: [
//                             DataColumn(label: Text("")),
//                             DataColumn(label: Text("Task Title")),
//                             DataColumn(label: Text("Status")),
//                             DataColumn(label: Text("Priority")),
//                             DataColumn(label: Text("Due Date")),
//                             DataColumn(label: Text("Actions")),
//                           ],
//                           rows: _filteredTasks.map((task) {
//                             return DataRow(
//                               cells: [
//                                 DataCell(
//                                   Checkbox(
//                                     activeColor: Colors.indigo,
//                                     value: task.status == "completed",
//                                     onChanged: (bool? value) {
//                                       _toggleTaskCompletion(task);
//                                     },
//                                   ),
//                                 ),
//                                 DataCell(Text(task.title)),
//                                 DataCell(_buildColoredLabel(
//                                     task.status, _getStatusColor(task.status))),
//                                 DataCell(_buildColoredLabel(
//                                     task.priority,
//                                     _getPriorityColor(task.priority))),
//                                 DataCell(
//                                   Text(
//                                     () {
//                                       if (task.dueDate == null)
//                                         return "No Due Date";
//                                       DateTime parsedDueDate;
//                                       if (task.dueDate is String) {
//                                         parsedDueDate =
//                                             DateTime.parse(task.dueDate as String);
//                                       } else {
//                                         parsedDueDate = task.dueDate as DateTime;
//                                       }
//                                       return DateFormat('yyyy-MM-dd')
//                                           .format(parsedDueDate);
//                                     }(),
//                                   ),
//                                 ),
//                                 DataCell(
//                                   Row(
//                                     children: [
//                                       IconButton(
//                                         icon: Icon(Icons.edit, color: Colors.indigo),
//                                         onPressed: () => _updateTask(task),
//                                       ),
//                                       IconButton(
//                                         icon:
//                                             Icon(Icons.delete, color: Colors.red),
//                                         onPressed: () => _deleteTask(task),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             );
//                           }).toList(),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//           // Floating Action Button
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: FloatingActionButton(
//               backgroundColor: Colors.indigo,
//               onPressed: _addTask,
//               child: Icon(Icons.add, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// ============================================================================================================================


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/goal_task.dart';
import 'package:project/widgets/custom_scaffold.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalTaskService _apiService = GoalTaskService();
  late Future<Map<String, List<TaskModel>>> _tasksFuture;
  final TextEditingController _searchController = TextEditingController();
  List<TaskModel> _filteredActiveTasks = [];
  List<TaskModel> _filteredCompletedTasks = [];
  Map<String, List<TaskModel>> _allTasks = {"active": [], "completed": []};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);
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
      setState(() {
        _allTasks = tasks;
        _filterTasks(_searchController.text);
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
  }

  void _toggleTaskCompletion(TaskModel task) async {
    String newStatus = task.status == "completed" ? "pending" : "completed";
    try {
      await _apiService.updateTask(
        task.id,
        task.title,
        task.priority,
        task.dueDate!,
        newStatus,
        widget.goal.id,
        widget.goal.user,
      );
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
                    setState(() {
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
                  setState(() {
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
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
              ),
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
              try {
                await _apiService.createTaskForGoal(
                  titleController.text,
                  selectedPriority,
                  dueDateController.text,
                  selectedStatus,
                  widget.goal.id,
                  widget.goal.user, // Pass the user ID
                );
                Navigator.pop(context);
                _loadTasks();
              } catch (e) {
                _showErrorDialog("Failed to create task: $e");
              }
            },
            child: Text("Add", style: TextStyle(color: Colors.indigo)),
          ),
        ],
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
  showDialog(
    context: context,
    builder: (context) {
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
                    setState(() {
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
                    setState(() {
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
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
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
              try {
                await _apiService.updateTask(
                  task.id,
                  titleController.text,
                  selectedPriority,
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                  selectedStatus,
                  widget.goal.id, // Pass the goal ID
                  widget.goal.user, // Pass the user ID
                );
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
                                  rows: _filteredActiveTasks.map((task) {
                                    return DataRow(
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
                                            child: Text(
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