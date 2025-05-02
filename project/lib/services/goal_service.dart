
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goals_model.dart';
import '../services/local_storage.dart';

class GoalService {
  static const String baseUrl = 'http://127.0.0.1:8000/gt';
  static const String goalEndpoint = '/goals/';

  // Get the current time dynamically
  static DateTime get currentTime => DateTime.now();
  static const String currentUser = 'Anilbk777';
  static const int userId = 14;

  // Format date to YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Format date to YYYY-MM-DD HH:MM:SS
  static String _formatDateTime(DateTime date) {
    // Debug print to check the date time being formatted
    print('Formatting date time: ${date.toString()}');

    // Format the date time in ISO 8601 format
    // We want to preserve the exact time as entered by the user
    // without any time zone conversion
    final formattedDateTime = "${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";

    print('Formatted date time: $formattedDateTime');
    return formattedDateTime;
  }

  // Get the current time in Nepal time zone (UTC+5:45)
  static DateTime getNepaliTime() {
    final now = DateTime.now();
    // Nepal is UTC+5:45
    final nepalOffset = const Duration(hours: 5, minutes: 45);
    final utcTime = now.toUtc();
    final nepalTime = utcTime.add(nepalOffset);

    print('Current UTC time: ${utcTime.toString()}');
    print('Current Nepal time: ${nepalTime.toString()}');

    return nepalTime;
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
    bool hasReminder = false,
    DateTime? reminderDateTime,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Creating new goal: $title');

      // Debug print to check the reminder date time before sending to the server
      if (hasReminder && reminderDateTime != null) {
        // We want to preserve the exact time as entered by the user
        // without any time zone conversion
        final now = DateTime.now();
        print('GOAL SERVICE - Creating goal with reminder date time: ${reminderDateTime.toString()}');
        print('GOAL SERVICE - Reminder time zone offset: ${reminderDateTime.timeZoneOffset}');
        print('GOAL SERVICE - Current time: ${now.toString()}');
        print('GOAL SERVICE - Current time zone offset: ${now.timeZoneOffset}');
        print('GOAL SERVICE - Time difference: ${reminderDateTime.difference(now)}');
        print('GOAL SERVICE - Time difference in minutes: ${reminderDateTime.difference(now).inMinutes}');
        print('GOAL SERVICE - Time difference in seconds: ${reminderDateTime.difference(now).inSeconds}');
      }

      final response = await http.post(
        Uri.parse(baseUrl + goalEndpoint),
        headers: headers,
        body: json.encode({
          'title': title,
          'start_date': _formatDate(startDate),
          'completion_date': _formatDate(completionDate),
          'is_completed': false,
          'has_reminder': hasReminder,
          'reminder_date_time': reminderDateTime != null ? _formatDateTime(reminderDateTime) : null,
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
    bool hasReminder = false,
    DateTime? reminderDateTime,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Updating goal #$goalId');

      // Debug print to check the reminder date time before sending to the server
      if (hasReminder && reminderDateTime != null) {
        print('Updating goal with reminder date time: ${reminderDateTime.toString()}');
        print('Current time: ${DateTime.now().toString()}');
        print('Time difference in minutes: ${reminderDateTime.difference(DateTime.now()).inMinutes}');
      }

      final response = await http.put(
        Uri.parse('$baseUrl$goalEndpoint$goalId/'),
        headers: headers,
        body: json.encode({
          'title': title,
          'start_date': _formatDate(startDate),
          'completion_date': _formatDate(completionDate),
          'is_completed': isCompleted,
          'completion_time': completionTime != null ? _formatDateTime(completionTime) : null,
          'has_reminder': hasReminder,
          'reminder_date_time': reminderDateTime != null ? _formatDateTime(reminderDateTime) : null,
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

  // Fetch a goal by ID
  static Future<Goal> fetchGoalById(int goalId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Fetching goal #$goalId');

      final response = await http.get(
        Uri.parse('$baseUrl$goalEndpoint$goalId/'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Goal fetched successfully');
        return Goal.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Goal not found');
      } else {
        throw Exception('Failed to fetch goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching goal: $e');
      throw Exception('Failed to fetch goal: $e');
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