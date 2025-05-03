
import 'dart:convert';
import 'package:project/services/goal_service.dart';
import 'package:project/services/goal_task.dart';


class Goal {
  int id;
  String title;
  DateTime startDate;
  DateTime completionDate;
  bool isCompleted; // Removed `final` to make it mutable
  DateTime? completionTime; // Removed `final` to make it mutable
  bool hasReminder; // Added for reminder functionality
  DateTime? reminderDateTime; // Added for reminder functionality
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
    this.hasReminder = false,
    this.reminderDateTime,
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

    // Parse the reminder date time and print it for debugging
    DateTime? reminderDateTime;
    if (json['reminder_date_time'] != null) {
      // Parse the reminder date time from the server
      String reminderDateTimeStr = json['reminder_date_time'];

      // Create a DateTime object from the string
      reminderDateTime = DateTime.parse(reminderDateTimeStr);
      // print('GOAL MODEL - Current time zone offset: ${now.timeZoneOffset}');
      // print('GOAL MODEL - Time difference: ${reminderDateTime.difference(now)}');
      // print('GOAL MODEL - Time difference in minutes: ${reminderDateTime.difference(now).inMinutes}');
      // print('GOAL MODEL - Time difference in seconds: ${reminderDateTime.difference(now).inSeconds}');
    }

    return Goal(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      completionDate: DateTime.parse(json['completion_date']),
      isCompleted: json['is_completed'],
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time'])
          : null,
      hasReminder: json['has_reminder'] ?? false,
      reminderDateTime: reminderDateTime,
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

  // Method to fetch tasks if needed
  Future<void> fetchTasksIfNeeded() async {
    // Always fetch the latest tasks to ensure we have up-to-date data
    try {
      final updatedGoal = await GoalService.fetchGoalById(id);

      // Update tasks regardless of whether they were empty before
      tasks = updatedGoal.tasks;

      // If we still have no tasks, try to fetch them directly using the GoalTaskService
      if (tasks.isEmpty) {
        try {
          final taskService = GoalTaskService();
          final taskMap = await taskService.fetchTasksForGoal(id);

          List<GoalTask> allTasks = [];

          // Convert active tasks to GoalTask objects
          if (taskMap["active"] != null) {
            for (var task in taskMap["active"]!) {
              allTasks.add(GoalTask(
                id: task.id,
                title: task.title,
                status: task.status,
                priority: task.priority,
                dueDate: task.dueDate.isNotEmpty ? DateTime.parse(task.dueDate) : null,
                dateCreated: DateTime.parse(task.dateCreated),
                goal: id,
                hasReminder: task.hasReminder,
                reminderDateTime: task.reminderDateTime,
              ));
            }
          }

          // Convert completed tasks to GoalTask objects
          if (taskMap["completed"] != null) {
            for (var task in taskMap["completed"]!) {
              allTasks.add(GoalTask(
                id: task.id,
                title: task.title,
                status: task.status,
                priority: task.priority,
                dueDate: task.dueDate.isNotEmpty ? DateTime.parse(task.dueDate) : null,
                dateCreated: DateTime.parse(task.dateCreated),
                goal: id,
                hasReminder: task.hasReminder,
                reminderDateTime: task.reminderDateTime,
              ));
            }
          }

          // Update the tasks list
          tasks = allTasks;
        } catch (directFetchError) {
          // Silently handle errors
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  double completionPercentage() {
    // If this is a completed goal, return 100%
    if (isCompleted) return 100.0;

    // Count completed tasks
    int completedTasks = 0;
    int totalTasks = tasks.length;

    // If there are no tasks, return 0
    if (totalTasks == 0) return 0.0;

    for (var task in tasks) {
      if (task.status == 'completed') {
        completedTasks++;
      }
    }

    // Calculate percentage and ensure it's between 0 and 100
    double percentage = (completedTasks / totalTasks) * 100;
    return percentage.clamp(0.0, 100.0);
  }
}

class GoalTask {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime dateCreated;
  final int goal;
  final bool hasReminder;
  final DateTime? reminderDateTime;

  GoalTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.dateCreated,
    required this.goal,
    this.hasReminder = false,
    this.reminderDateTime,
  });

  factory GoalTask.fromJson(Map<String, dynamic> json) {
    // Parse reminder date time if available
    DateTime? reminderDateTime;
    if (json['reminder_date_time'] != null) {
      try {
        reminderDateTime = DateTime.parse(json['reminder_date_time']);
      } catch (e) {
        // Silently handle parsing errors
      }
    }

    // Handle has_reminder field - convert to boolean
    bool hasReminder = false;
    if (json['has_reminder'] != null) {
      // If it's already a boolean, use it directly
      if (json['has_reminder'] is bool) {
        hasReminder = json['has_reminder'];
      }
      // If it's a string, convert it to boolean
      else if (json['has_reminder'] is String) {
        hasReminder = json['has_reminder'].toLowerCase() == 'true';
      }
      // If it's a number, treat non-zero as true
      else if (json['has_reminder'] is num) {
        hasReminder = json['has_reminder'] != 0;
      }
    }

    return GoalTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Task',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      dateCreated: DateTime.parse(json['date_created']),
      goal: json['goal'],
      hasReminder: hasReminder,
      reminderDateTime: reminderDateTime,
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
      'goal': goal,
      'has_reminder': hasReminder,
      'reminder_date_time': reminderDateTime?.toIso8601String(),
    };
  }
}