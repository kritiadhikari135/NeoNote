
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';
import 'package:project/models/task_model.dart';
import 'package:intl/intl.dart';  // Import the intl package

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/task/";

  // Fetch authentication headers
  Future<Map<String, String>> _getHeaders() async {
    String? token = await LocalStorage.getToken();

    if (token == null || token.isEmpty) {
      print("⚠️ No token found. User is unauthorized.");
      return {"Content-Type": "application/json"};
    }

    print("✅ Using Token: Bearer $token");

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",  // Ensure the correct format
    };
  }

  // Fetch Active & Completed Tasks
  Future<Map<String, List<TaskModel>>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("${baseUrl}tasks/"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<TaskModel> activeTasks = (data['active_tasks'] as List)
          .map((task) => TaskModel.fromJson(task))
          .toList();
      List<TaskModel> completedTasks = (data['completed_tasks'] as List)
          .map((task) => TaskModel.fromJson(task))
          .toList();

      return {"active": activeTasks, "completed": completedTasks};
    } else {
      throw Exception("Failed to load tasks");
    }
  }

  // Create Task
  Future<TaskModel> createTask(
    String title,
    String priority,
    String dueDate,
    String status,
    {bool? hasReminder = false,
    DateTime? reminderDateTime}
  ) async {
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 5, minutes: 45)); // Nepal Time (UTC+05:45)
    final String formattedDate = DateFormat('yyyy-MM-dd hh:mm:ss a').format(now);

    final Map<String, dynamic> taskData = {
      "title": title,
      "priority": priority,
      "due_date": dueDate,
      "status": status,
      "date_created": formattedDate,  // Use Nepal Time
      "has_reminder": hasReminder,
    };

    // Add reminder date time if it exists
    if ((hasReminder ?? false) && reminderDateTime != null) {
      taskData["reminder_date_time"] = reminderDateTime.toIso8601String();
    }

    final response = await http.post(
      Uri.parse("${baseUrl}tasks/"),
      headers: await _getHeaders(),
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  // Update Task
  Future<void> updateTask(
    int id,
    String title,
    String priority,
    String dueDate,
    String status,
    {bool? hasReminder = false,
    DateTime? reminderDateTime}
  ) async {
    final Map<String, dynamic> taskData = {
      "title": title,
      "priority": priority,
      "due_date": dueDate,
      "status": status,
      "has_reminder": hasReminder,
    };

    // Add reminder date time if it exists
    if ((hasReminder ?? false) && reminderDateTime != null) {
      taskData["reminder_date_time"] = reminderDateTime.toIso8601String();
    }

    final response = await http.put(
      Uri.parse("${baseUrl}tasks/$id/"),
      headers: await _getHeaders(),
      body: jsonEncode(taskData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  // Delete Task
  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse("${baseUrl}tasks/$id/"),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }
}