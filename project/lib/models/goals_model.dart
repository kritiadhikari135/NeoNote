
// ================================================================================================================
import 'dart:convert';

// class Goal {
//   final int id;
//   final String title;
//   final DateTime startDate;
//   final DateTime completionDate;
//   final bool isCompleted;
//   final DateTime? completionTime;
//   final int user;
//   final String createdBy;
//   final DateTime createdAt;
//   final String? lastModifiedBy;
//   final DateTime lastModifiedAt;
//   final List<GoalTask> tasks;

//   Goal({
//     required this.id,
//     required this.title,
//     required this.startDate,
//     required this.completionDate,
//     required this.isCompleted,
//     this.completionTime,
//     required this.user,
//     required this.createdBy,
//     required this.createdAt,
//     this.lastModifiedBy,
//     required this.lastModifiedAt,
//     required this.tasks,
//   });

//   factory Goal.fromJson(Map<String, dynamic> json) {
//     var tasksFromJson = json['tasks'] as List<dynamic>? ?? [];
//     List<GoalTask> taskList = tasksFromJson.map((task) => GoalTask.fromJson(task)).toList();

//     return Goal(
//       id: json['id'],
//       title: json['title'],
//       startDate: DateTime.parse(json['start_date']),
//       completionDate: DateTime.parse(json['completion_date']),
//       isCompleted: json['is_completed'],
//       completionTime: json['completion_time'] != null
//           ? DateTime.parse(json['completion_time'])
//           : null,
//       user: json['user'],
//       createdBy: json['created_by'],
//       createdAt: DateTime.parse(json['created_at']),
//       lastModifiedBy: json['last_modified_by'],
//       lastModifiedAt: DateTime.parse(json['last_modified_at']),
//       tasks: taskList,
//     );
//   }

//   static List<Goal> fromJsonList(String jsonString) {
//     final List<dynamic> jsonData = jsonDecode(jsonString);
//     return jsonData.map((json) => Goal.fromJson(json)).toList();
//   }

//   double completionPercentage() {
//     if (tasks.isEmpty) return 0;
//     int completedTasks = tasks.where((task) => task.status == 'completed').length;
//     return (completedTasks / tasks.length) * 100;
//   }
// }
class Goal {
  int id;
  String title;
  DateTime startDate;
  DateTime completionDate;
  bool isCompleted; // Removed `final` to make it mutable
  DateTime? completionTime; // Removed `final` to make it mutable
  int user;
  String createdBy;
  DateTime createdAt;
  String? lastModifiedBy;
  DateTime lastModifiedAt;
  List<GoalTask> tasks;

  Goal({
    required this.id,
    required this.title,
    required this.startDate,
    required this.completionDate,
    required this.isCompleted,
    this.completionTime,
    required this.user,
    required this.createdBy,
    required this.createdAt,
    this.lastModifiedBy,
    required this.lastModifiedAt,
    required this.tasks,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    var tasksFromJson = json['tasks'] as List<dynamic>? ?? [];
    List<GoalTask> taskList = tasksFromJson.map((task) => GoalTask.fromJson(task)).toList();

    return Goal(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      completionDate: DateTime.parse(json['completion_date']),
      isCompleted: json['is_completed'],
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time'])
          : null,
      user: json['user'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      lastModifiedBy: json['last_modified_by'],
      lastModifiedAt: DateTime.parse(json['last_modified_at']),
      tasks: taskList,
    );
  }

  static List<Goal> fromJsonList(String jsonString) {
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((json) => Goal.fromJson(json)).toList();
  }

  double completionPercentage() {
    if (tasks.isEmpty) return 0;
    int completedTasks = tasks.where((task) => task.status == 'completed').length;
    return (completedTasks / tasks.length) * 100;
  }
}

class GoalTask {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime dateCreated;
  final int goal; // Add this field if needed

  GoalTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.dateCreated,
    required this.goal, // Add this to the constructor
  });

  factory GoalTask.fromJson(Map<String, dynamic> json) {
    return GoalTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Task',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      dateCreated: DateTime.parse(json['date_created']),
      goal: json['goal'], // Parse the goal field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'date_created': dateCreated.toIso8601String(),
      'goal': goal, // Include the goal field in the JSON
    };
  }
}