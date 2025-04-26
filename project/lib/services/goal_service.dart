// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/goals_model.dart';
// import '../services/local_storage.dart';

// class GoalService {
//   static const String baseUrl = 'http://127.0.0.1:8000/gt';
//   static const String goalEndpoint = '/goals/';

//   // Update current time to match your system
//   static final DateTime currentTime = DateTime.parse('2025-02-22 10:40:46');
//   static const String currentUser = 'Anilbk777';
//   static const int userId = 14;  // Add user ID from your JWT token

//   // Format date to YYYY-MM-DD
//   static String _formatDate(DateTime date) {
//     return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//   }

//   // Get headers with JWT token
//   static Future<Map<String, String>> _getAuthHeaders() async {
//     final token = await LocalStorage.getToken();
//     if (token == null) {
//       throw Exception('Authentication token not found. Please login again.');
//     }

//     return {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//   }

//   // Debug method to check the current endpoint
//   static void debugEndpoint() {
//     print('🔍 Current API endpoint: $baseUrl$goalEndpoint');
//     print('🔍 Example full URL: http://127.0.0.1:8000/gt/goals/');
//   }

//   // Fetch all goals
//   static Future<List<Goal>> fetchGoals() async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Fetching goals with token...');
//       debugEndpoint();

//       final response = await http.get(
//         Uri.parse(baseUrl + goalEndpoint),
//         headers: headers,
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           List<dynamic> data = json.decode(response.body);
//           print('✅ Successfully fetched ${data.length} goals');
//           return data.map((json) => Goal.fromJson(json)).toList();
        
//         case 401:
//           print('🔒 Authentication failed. Token might be expired.');
//           await LocalStorage.clearToken();
//           throw Exception('Your session has expired. Please login again.');
        
//         default:
//           throw Exception('Failed to load goals: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error fetching goals: $e');
//       throw Exception('Failed to load goals: $e');
//     }
//   }

//   // Create a new goal
//   static Future<Goal> createGoal({
//     required String title,
//     required DateTime startDate,
//     required DateTime completionDate,
//   }) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Creating new goal: $title');

//       final response = await http.post(
//         Uri.parse(baseUrl + goalEndpoint),
//         headers: headers,
//         body: json.encode({
//           'title': title,
//           'start_date': _formatDate(startDate),  // Format date correctly
//           'completion_date': _formatDate(completionDate),  // Format date correctly
//           'is_completed': false,
//           'user': userId,  // Add required user field
//           'created_by': currentUser,
//           'created_at': currentTime.toIso8601String(),
//         }),
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       if (response.statusCode == 201) {
//         print('✅ Goal created successfully');
//         return Goal.fromJson(json.decode(response.body));
//       } else if (response.statusCode == 400) {
//         final error = json.decode(response.body);
//         throw Exception('Invalid goal data: ${error.toString()}');
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to create goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error creating goal: $e');
//       throw Exception('Failed to create goal: $e');
//     }
//   }

//   // Update an existing goal
//   static Future<Goal> updateGoal({
//     required int goalId,
//     required String title,
//     required DateTime startDate,
//     required DateTime completionDate,
//     required bool isCompleted,
//     DateTime? completionTime,
//   }) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Updating goal #$goalId');

//       final response = await http.put(
//         Uri.parse('$baseUrl$goalEndpoint$goalId/'),
//         headers: headers,
//         body: json.encode({
//           'title': title,
//           'start_date': _formatDate(startDate),  // Format date correctly
//           'completion_date': _formatDate(completionDate),  // Format date correctly
//           'is_completed': isCompleted,
//           'completion_time': completionTime != null ? _formatDate(completionTime) : null,
//           'user': userId,  // Add required user field
//           'last_modified_by': currentUser,
//           'last_modified_at': currentTime.toIso8601String(),
//         }),
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         print('✅ Goal updated successfully');
//         return Goal.fromJson(json.decode(response.body));
//       } else if (response.statusCode == 400) {
//         final error = json.decode(response.body);
//         throw Exception('Invalid goal data: ${error.toString()}');
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to update goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error updating goal: $e');
//       throw Exception('Failed to update goal: $e');
//     }
//   }

//   // Delete a goal
//   static Future<void> deleteGoal(int goalId) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Deleting goal #$goalId');

//       final response = await http.delete(
//         Uri.parse('$baseUrl$goalEndpoint$goalId/'),
//         headers: headers,
//       );

//       print('📥 Response status: ${response.statusCode}');

//       if (response.statusCode == 204) {
//         print('✅ Goal deleted successfully');
//         return;
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to delete goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error deleting goal: $e');
//       throw Exception('Failed to delete goal: $e');
//     }
//   }
// }


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/goals_model.dart';
// import '../services/local_storage.dart';

// class GoalService {
//   static const String baseUrl = 'http://127.0.0.1:8000/gt';
//   static const String goalEndpoint = '/goals/';
  
//   // Updated current time to match your system
//   static final DateTime currentTime = DateTime.parse('2025-02-22 14:06:49');
//   static const String currentUser = 'Anilbk777';
//   static const int userId = 14;

//   // Format date to YYYY-MM-DD
//   static String _formatDate(DateTime date) {
//     return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//   }

//   // Format date to YYYY-MM-DD HH:MM:SS
//   static String _formatDateTime(DateTime date) {
//     return "${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
//   }

//   // Get headers with JWT token
//   static Future<Map<String, String>> _getAuthHeaders() async {
//     final token = await LocalStorage.getToken();
//     if (token == null) {
//       throw Exception('Authentication token not found. Please login again.');
//     }

//     return {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//   }

//   // Debug method to check the current endpoint
//   static void debugEndpoint() {
//     print('🔍 Current API endpoint: $baseUrl$goalEndpoint');
//     print('🔍 Example full URL: http://127.0.0.1:8000/gt/goals/');
//   }

//   // Fetch goals for a specific user
//   static Future<List<Goal>> fetchGoals() async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Fetching goals with token...');
//       debugEndpoint();

//       final response = await http.get(
//         Uri.parse('$baseUrl$goalEndpoint?user=$userId'),
//         headers: headers,
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           List<dynamic> data = json.decode(response.body);
//           print('✅ Successfully fetched ${data.length} goals');
//           return data.map((json) => Goal.fromJson(json)).toList();
        
//         case 401:
//           print('🔒 Authentication failed. Token might be expired.');
//           await LocalStorage.clearToken();
//           throw Exception('Your session has expired. Please login again.');
        
//         default:
//           throw Exception('Failed to load goals: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error fetching goals: $e');
//       throw Exception('Failed to load goals: $e');
//     }
//   }

//   // Create a new goal
//   static Future<Goal> createGoal({
//     required String title,
//     required DateTime startDate,
//     required DateTime completionDate,
//   }) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Creating new goal: $title');

//       final response = await http.post(
//         Uri.parse(baseUrl + goalEndpoint),
//         headers: headers,
//         body: json.encode({
//           'title': title,
//           'start_date': _formatDate(startDate),
//           'completion_date': _formatDate(completionDate),
//           'is_completed': false,
//           'user': userId,
//           'created_by': currentUser,
//           'created_at': _formatDateTime(currentTime),
//         }),
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       if (response.statusCode == 201) {
//         print('✅ Goal created successfully');
//         return Goal.fromJson(json.decode(response.body));
//       } else if (response.statusCode == 400) {
//         final error = json.decode(response.body);
//         throw Exception('Invalid goal data: ${error.toString()}');
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to create goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error creating goal: $e');
//       throw Exception('Failed to create goal: $e');
//     }
//   }

//   // Update an existing goal
//   static Future<Goal> updateGoal({
//     required int goalId,
//     required String title,
//     required DateTime startDate,
//     required DateTime completionDate,
//     required bool isCompleted,
//     DateTime? completionTime,
//   }) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Updating goal #$goalId');

//       final response = await http.put(
//         Uri.parse('$baseUrl$goalEndpoint$goalId/'),
//         headers: headers,
//         body: json.encode({
//           'title': title,
//           'start_date': _formatDate(startDate),
//           'completion_date': _formatDate(completionDate),
//           'is_completed': isCompleted,
//           'completion_time': completionTime != null ? _formatDateTime(completionTime) : null,
//           'user': userId,
//           'last_modified_by': currentUser,
//           'last_modified_at': _formatDateTime(currentTime),
//         }),
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         print('✅ Goal updated successfully');
//         return Goal.fromJson(json.decode(response.body));
//       } else if (response.statusCode == 400) {
//         final error = json.decode(response.body);
//         throw Exception('Invalid goal data: ${error.toString()}');
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to update goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error updating goal: $e');
//       throw Exception('Failed to update goal: $e');
//     }
//   }

//   // Delete a goal
//   static Future<void> deleteGoal(int goalId) async {
//     try {
//       final headers = await _getAuthHeaders();
//       print('📡 Deleting goal #$goalId');

//       final response = await http.delete(
//         Uri.parse('$baseUrl$goalEndpoint$goalId/'),
//         headers: headers,
//       );

//       print('📥 Response status: ${response.statusCode}');

//       if (response.statusCode == 204) {
//         print('✅ Goal deleted successfully');
//         return;
//       } else if (response.statusCode == 401) {
//         print('🔒 Authentication failed. Token might be expired.');
//         await LocalStorage.clearToken();
//         throw Exception('Your session has expired. Please login again.');
//       } else {
//         throw Exception('Failed to delete goal: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error deleting goal: $e');
//       throw Exception('Failed to delete goal: $e');
//     }
//   }
// }




import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goals_model.dart';
import '../services/local_storage.dart';

class GoalService {
  static const String baseUrl = 'http://127.0.0.1:8000/gt';
  static const String goalEndpoint = '/goals/';
  
  // Updated current time to match your system
  static final DateTime currentTime = DateTime.parse('2025-02-22 16:39:32');
  static const String currentUser = 'Anilbk777';
  static const int userId = 14;

  // Format date to YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Format date to YYYY-MM-DD HH:MM:SS
  static String _formatDateTime(DateTime date) {
    return "${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  // Get headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Debug method to check the current endpoint
  static void debugEndpoint() {
    print('🔍 Current API endpoint: $baseUrl$goalEndpoint');
    print('🔍 Example full URL: http://127.0.0.1:8000/gt/goals/');
  }

  // Fetch goals for a specific user
  static Future<List<Goal>> fetchGoals() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Fetching goals with token...');
      debugEndpoint();

      final response = await http.get(
        Uri.parse('$baseUrl$goalEndpoint?user=$userId'),
        headers: headers,
      );

      // print('📥 Response status: ${response.statusCode}');
      // print('📥 Response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          List<dynamic> data = json.decode(response.body);
          print('✅ Successfully fetched ${data.length} goals');
          return data.map((json) => Goal.fromJson(json)).toList();
        
        case 401:
          print('🔒 Authentication failed. Token might be expired.');
          await LocalStorage.clearToken();
          throw Exception('Your session has expired. Please login again.');
        
        default:
          throw Exception('Failed to load goals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching goals: $e');
      throw Exception('Failed to load goals: $e');
    }
  }

  // Create a new goal
  static Future<Goal> createGoal({
    required String title,
    required DateTime startDate,
    required DateTime completionDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Creating new goal: $title');

      final response = await http.post(
        Uri.parse(baseUrl + goalEndpoint),
        headers: headers,
        body: json.encode({
          'title': title,
          'start_date': _formatDate(startDate),
          'completion_date': _formatDate(completionDate),
          'is_completed': false,
          'user': userId,
          'created_by': currentUser,
          'created_at': _formatDateTime(currentTime),
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Goal created successfully');
        return Goal.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception('Invalid goal data: ${error.toString()}');
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to create goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating goal: $e');
      throw Exception('Failed to create goal: $e');
    }
  }

  // Update an existing goal
  static Future<Goal> updateGoal({
    required int goalId,
    required String title,
    required DateTime startDate,
    required DateTime completionDate,
    required bool isCompleted,
    DateTime? completionTime,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Updating goal #$goalId');

      final response = await http.put(
        Uri.parse('$baseUrl$goalEndpoint$goalId/'),
        headers: headers,
        body: json.encode({
          'title': title,
          'start_date': _formatDate(startDate),
          'completion_date': _formatDate(completionDate),
          'is_completed': isCompleted,
          'completion_time': completionTime != null ? _formatDateTime(completionTime) : null,
          'user': userId,
          'last_modified_by': currentUser,
          'last_modified_at': _formatDateTime(currentTime),
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Goal updated successfully');
        return Goal.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception('Invalid goal data: ${error.toString()}');
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to update goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating goal: $e');
      throw Exception('Failed to update goal: $e');
    }
  }

  // Delete a goal
  static Future<void> deleteGoal(int goalId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Deleting goal #$goalId');

      final response = await http.delete(
        Uri.parse('$baseUrl$goalEndpoint$goalId/'),
        headers: headers,
      );

      // print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('✅ Goal deleted successfully');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to delete goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting goal: $e');
      throw Exception('Failed to delete goal: $e');
    }
  }
}