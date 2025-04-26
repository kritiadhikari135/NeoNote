// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:project/services/local_storage.dart';
// import 'package:project/models/task_model.dart';
// import 'package:intl/intl.dart';

// class GoalTaskService {
//   final String baseUrl = "http://127.0.0.1:8000/gt/";

//   // Fetch authentication headers
//   Future<Map<String, String>> _getHeaders() async {
//     String? token = await LocalStorage.getToken();

//     if (token == null || token.isEmpty) {
//       print("⚠️ No token found. User is unauthorized.");
//       return {"Content-Type": "application/json"};
//     }

//     print("✅ Using Token: Bearer $token");

//     return {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $token", // Ensure the correct format
//     };
//   }

//   // Fetch Tasks for a Specific Goal
// Future<List<TaskModel>> fetchTasksForGoal(int goalId) async {
//   final response = await http.get(
//     Uri.parse("${baseUrl}goals/$goalId/tasks/"),
//     headers: await _getHeaders(),
//   );

//   if (response.statusCode == 200) {
//     try {
//       final List<dynamic> data = jsonDecode(response.body);
//       print("✅ Tasks fetched for goal ID $goalId: $data"); // Debug log
//       return data.map((task) => TaskModel.fromJson(task)).toList();
//     } catch (e) {
//       print("❌ Error parsing tasks: $e");
//       print("Response body: ${response.body}"); // Log the response body for debugging
//       throw Exception("Failed to parse tasks: ${response.body}");
//     }
//   } else if (response.statusCode == 404) {
//     print("⚠️ No tasks found for goal ID: $goalId");
//     return [];
//   } else {
//     print("❌ Failed to load tasks: ${response.statusCode}, Body: ${response.body}");
//     throw Exception("Failed to load tasks: ${response.body}");
//   }
// }
//   // Create Task for a Specific Goal
// Future<void> createTaskForGoal(
//     String title, String priority, String dueDate, String status, int goalId) async {
//   if (title.isEmpty) {
//     throw Exception("Task title cannot be empty");
//   }
//   if (priority.isEmpty) {
//     throw Exception("Task priority cannot be empty");
//   }
//   if (status.isEmpty) {
//     throw Exception("Task status cannot be empty");
//   }

//   final response = await http.post(
//     Uri.parse("${baseUrl}tasks/"),
//     headers: await _getHeaders(),
//     body: jsonEncode({
//       "title": title,
//       "priority": priority,
//       "due_date": dueDate,
//       "status": status,
//       "goal": goalId,
//     }),
//   );

//   if (response.statusCode != 201) {
//     print("❌ Error creating task: ${response.statusCode}, Body: ${response.body}");
//     throw Exception('Failed to create task');
//   } else {
//     print("✅ Task created successfully for goal ID $goalId");
//   }
// }
//   // Update Task
//  Future<void> updateTask(int id, String title, String priority, String dueDate, String status) async {
//   if (title.isEmpty) {
//     throw Exception("Task title cannot be empty");
//   }
//   if (priority.isEmpty) {
//     throw Exception("Task priority cannot be empty");
//   }
//   if (status.isEmpty) {
//     throw Exception("Task status cannot be empty");
//   }

//   final response = await http.put(
//     Uri.parse("${baseUrl}tasks/$id/"),
//     headers: await _getHeaders(),
//     body: jsonEncode({
//       "title": title,
//       "priority": priority,
//       "due_date": dueDate,
//       "status": status,
//     }),
//   );

//   if (response.statusCode != 200) {
//     print("❌ Error updating task ID $id: ${response.statusCode}, Body: ${response.body}");
//     throw Exception('Failed to update task');
//   } else {
//     print("✅ Task ID $id updated successfully");
//   }
// }

//   // Delete Task
// Future<void> deleteTask(int id) async {
//   final response = await http.delete(
//     Uri.parse("${baseUrl}tasks/$id/"),
//     headers: await _getHeaders(),
//   );

//   if (response.statusCode != 204 && response.statusCode != 200) {
//     print("❌ Error deleting task ID $id: ${response.statusCode}, Body: ${response.body}");
//     throw Exception('Failed to delete task');
//   } else {
//     print("✅ Task ID $id deleted successfully");
//   }
// }
// }


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:project/services/local_storage.dart';
// import 'package:project/models/task_model.dart';

// class GoalTaskService {
//   final String baseUrl = "http://127.0.0.1:8000/gt/";

//   // Fetch authentication headers
//   Future<Map<String, String>> _getHeaders() async {
//     String? token = await LocalStorage.getToken();

//     if (token == null || token.isEmpty) {
//       print("⚠️ No token found. User is unauthorized.");
//       return {"Content-Type": "application/json"};
//     }

//     return {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $token",
//     };
//   }

//   // Validate task fields
//   void _validateTaskFields(String title, String priority, String status) {
//     if (title.isEmpty) {
//       throw Exception("Task title cannot be empty");
//     }
//     if (priority.isEmpty) {
//       throw Exception("Task priority cannot be empty");
//     }
//     if (status.isEmpty) {
//       throw Exception("Task status cannot be empty");
//     }
//   }

//   // Fetch Tasks for a Specific Goal
//   Future<List<TaskModel>> fetchTasksForGoal(int goalId) async {
//     final response = await http.get(
//       Uri.parse("${baseUrl}goals/$goalId/tasks/"),
//       headers: await _getHeaders(),
//     );

//     if (response.statusCode == 200) {
//       try {
//         final List<dynamic> data = jsonDecode(response.body);
//         if (data.isEmpty) {
//           print("⚠️ No tasks found for goal ID $goalId.");
//           return [];
//         }
//         print("✅ Tasks fetched for goal ID $goalId: $data");
//         return data.map((task) => TaskModel.fromJson(task)).toList();
//       } catch (e) {
//         print("❌ Error parsing tasks: $e");
//         throw Exception("Failed to parse tasks. Error: $e");
//       }
//     } else if (response.statusCode == 404) {
//       print("⚠️ No tasks found for goal ID: $goalId");
//       return [];
//     } else {
//       print("❌ Failed to load tasks: ${response.statusCode}, Body: ${response.body}");
//       throw Exception("Failed to load tasks. Status code: ${response.statusCode}");
//     }
//   }

//   // Create Task for a Specific Goal
//   Future<void> createTaskForGoal(
//       String title, String priority, String dueDate, String status, int goalId) async {
//     _validateTaskFields(title, priority, status);

//     final response = await http.post(
//       Uri.parse("${baseUrl}tasks/"),
//       headers: await _getHeaders(),
//       body: jsonEncode({
//         "title": title,
//         "priority": priority,
//         "due_date": dueDate,
//         "status": status,
//         "goal": goalId,
//       }),
//     );

//     if (response.statusCode != 201) {
//       print("❌ Error creating task: ${response.statusCode}, Body: ${response.body}");
//       throw Exception('Failed to create task');
//     } else {
//       print("✅ Task created successfully for goal ID $goalId");
//     }
//   }

//   // Update Task
//   Future<void> updateTask(int id, String title, String priority, String dueDate, String status) async {
//     _validateTaskFields(title, priority, status);

//     final response = await http.put(
//       Uri.parse("${baseUrl}tasks/$id/"),
//       headers: await _getHeaders(),
//       body: jsonEncode({
//         "title": title,
//         "priority": priority,
//         "due_date": dueDate,
//         "status": status,
//       }),
//     );

//     if (response.statusCode != 200) {
//       print("❌ Error updating task ID $id: ${response.statusCode}, Body: ${response.body}");
//       throw Exception('Failed to update task');
//     } else {
//       print("✅ Task ID $id updated successfully");
//     }
//   }

//   // Delete Task
//   Future<void> deleteTask(int id) async {
//     final response = await http.delete(
//       Uri.parse("${baseUrl}tasks/$id/"),
//       headers: await _getHeaders(),
//     );

//     if (response.statusCode != 204 && response.statusCode != 200) {
//       print("❌ Error deleting task ID $id: ${response.statusCode}, Body: ${response.body}");
//       throw Exception('Failed to delete task');
//     } else {
//       print("✅ Task ID $id deleted successfully");
//     }
//   }

//   // Fetch a Single Task by ID
//   Future<TaskModel> fetchTaskById(int taskId) async {
//     final response = await http.get(
//       Uri.parse("${baseUrl}tasks/$taskId/"),
//       headers: await _getHeaders(),
//     );

//     if (response.statusCode == 200) {
//       try {
//         final data = jsonDecode(response.body);
//         print("✅ Task fetched: $data");
//         return TaskModel.fromJson(data);
//       } catch (e) {
//         print("❌ Error parsing task: $e");
//         throw Exception("Failed to parse task. Error: $e");
//       }
//     } else {
//       print("❌ Failed to fetch task ID $taskId: ${response.statusCode}, Body: ${response.body}");
//       throw Exception("Failed to fetch task. Status code: ${response.statusCode}");
//     }
//   }
// }

// =============================================----=========================---------

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';
import 'package:project/models/task_model.dart';
import 'package:intl/intl.dart'; // Import the intl package

class GoalTaskService {
  final String baseUrl = "http://127.0.0.1:8000/gt/";

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
      "Authorization": "Bearer $token", // Ensure the correct format
    };
  }

  // Fetch Active & Completed Tasks for a Specific Goal
 Future<Map<String, List<TaskModel>>> fetchTasksForGoal(int goalId) async {
  final response = await http.get(
    Uri.parse("${baseUrl}goals/$goalId/tasks/"),
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
  } else if (response.statusCode == 404) {
    print("⚠️ No tasks found for goal ID: $goalId");
    return {"active": [], "completed": []}; // Return empty lists instead of throwing an error
  } else {
    print("❌ Failed to load tasks for goal ID $goalId: ${response.statusCode}, Body: ${response.body}");
    throw Exception("Failed to load tasks");
  }
}

Future<TaskModel> createTaskForGoal(
    String title, String priority, String dueDate, String status, int goalId, int userId) async {
  final DateTime now = DateTime.now().toUtc().add(Duration(hours: 5, minutes: 45)); // Nepal Time (UTC+05:45)
  final String formattedDate = DateFormat('yyyy-MM-dd hh:mm:ss a').format(now);

  final response = await http.post(
    Uri.parse("${baseUrl}tasks/"),
    headers: await _getHeaders(),
    body: jsonEncode({
      "title": title,
      "priority": priority,
      "due_date": dueDate,
      "status": status,
      "goal": goalId,
      "user": userId, // Include the user ID
      "date_created": formattedDate,
    }),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    return TaskModel.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create task: ${response.body}');
  }
}
  // Create Task for a Specific Goal
//  Future<TaskModel> createTaskForGoal(
//     String title, String priority, String dueDate, String status, int goalId) async {
//   final DateTime now = DateTime.now().toUtc().add(Duration(hours: 5, minutes: 45)); // Nepal Time (UTC+05:45)
//   final String formattedDate = DateFormat('yyyy-MM-dd hh:mm:ss a').format(now);

//   final response = await http.post(
//     Uri.parse("${baseUrl}tasks/"),
//     headers: await _getHeaders(),
//     body: jsonEncode({
//       "title": title,
//       "priority": priority,
//       "due_date": dueDate,
//       "status": status,
//       "goal": goalId,
//       "date_created": formattedDate, // Use Nepal Time
//     }),
//   );

//   print("🔍 Request Body: ${jsonEncode({
//     "title": title,
//     "priority": priority,
//     "due_date": dueDate,
//     "status": status,
//     "goal": goalId,
//     "date_created": formattedDate,
//   })}");
//   print("🔍 Response Status Code: ${response.statusCode}");
//   print("🔍 Response Body: ${response.body}");

//   if (response.statusCode == 201 || response.statusCode == 200) {
//     print("✅ Task created successfully for goal ID $goalId");
//     return TaskModel.fromJson(jsonDecode(response.body));
//   } else {
//     print("❌ Error creating task for goal ID $goalId: ${response.statusCode}, Body: ${response.body}");
//     throw Exception('Failed to create task');
//   }
// }
  // Update Task
  // Future<void> updateTask(int id, String title, String priority, String dueDate, String status) async {
  //   final response = await http.put(
  //     Uri.parse("${baseUrl}tasks/$id/"),
  //     headers: await _getHeaders(),
  //     body: jsonEncode({
  //       "title": title,
  //       "priority": priority,
  //       "due_date": dueDate,
  //       "status": status,
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     print("✅ Task ID $id updated successfully");
  //   } else {
  //     print("❌ Error updating task ID $id: ${response.statusCode}, Body: ${response.body}");
  //     throw Exception('Failed to update task');
  //   }
  // }
Future<void> updateTask(
    int id, String title, String priority, String dueDate, String status, int goalId, int userId) async {
  final response = await http.put(
    Uri.parse("${baseUrl}tasks/$id/"),
    headers: await _getHeaders(),
    body: jsonEncode({
      "title": title,
      "priority": priority,
      "due_date": dueDate,
      "status": status,
      "goal": goalId, // Include the goal field
      "user": userId, // Include the user field
    }),
  );

  if (response.statusCode == 200) {
    print("✅ Task ID $id updated successfully");
  } else {
    print("❌ Error updating task ID $id: ${response.statusCode}, Body: ${response.body}");
    throw Exception('Failed to update task');
  }
}
  // Delete Task
  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse("${baseUrl}tasks/$id/"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      print("✅ Task ID $id deleted successfully");
    } else {
      print("❌ Error deleting task ID $id: ${response.statusCode}, Body: ${response.body}");
      throw Exception('Failed to delete task');
    }
  }

  // Fetch a Single Task by ID
  Future<TaskModel> fetchTaskById(int taskId) async {
    final response = await http.get(
      Uri.parse("${baseUrl}tasks/$taskId/"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print("✅ Task fetched: $data");
        return TaskModel.fromJson(data);
      } catch (e) {
        print("❌ Error parsing task: $e");
        throw Exception("Failed to parse task. Error: $e");
      }
    } else {
      print("❌ Failed to fetch task ID $taskId: ${response.statusCode}, Body: ${response.body}");
      throw Exception("Failed to fetch task. Status code: ${response.statusCode}");
    }
  }
}