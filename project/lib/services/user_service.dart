import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';

class UserService {
  static const String baseUrl = "http://127.0.0.1:8000/api/accounts/profile/";
  static String? _cachedUserId;

  // Get the current user's ID
  static Future<String?> getCurrentUserId() async {
    // Return cached ID if available
    if (_cachedUserId != null) {
      print("✅ Using cached user ID: $_cachedUserId");
      return _cachedUserId;
    }

    try {
      String? token = await LocalStorage.getToken();

      if (token == null) {
        print("⚠️ No token found. User is not authenticated.");
        return null;
      }

      print("🔍 Fetching user profile from: $baseUrl");
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("📡 Profile response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📄 Profile response data: $data");

        // Extract user ID from response
        if (data.containsKey('id')) {
          _cachedUserId = data['id'].toString();
          print("✅ User ID found: $_cachedUserId");
          return _cachedUserId;
        } else {
          print("⚠️ User ID not found in profile response. Available keys: ${data.keys.toList()}");
          // If 'id' is not available, try to use a default value for backward compatibility
          _cachedUserId = '1'; // Default user ID as fallback
          print("⚠️ Using default user ID: $_cachedUserId");
          return _cachedUserId;
        }
      } else {
        print("❌ Failed to get user profile: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error getting user ID: $e");
      print("❌ Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  // Clear the cached user ID (for logout)
  static void clearCachedUserId() {
    _cachedUserId = null;
  }
}
