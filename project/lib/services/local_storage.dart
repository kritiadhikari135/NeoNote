import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);     // Clear the token using the correct key
    await prefs.remove(_userIdKey);    // Clear user ID
    await prefs.remove('auth_token');  // Clear any legacy token
    await prefs.remove('user_pages');  // Clear pages data if needed
    await prefs.remove('user_data');   // Clear user data
    print("🗑️ Token and user data cleared!");
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson == null || userJson.isEmpty) {
        print("⚠️ No user data found in local storage.");
        return null;
      }

      // Parse the JSON string to a Map
      final userData = Map<String, dynamic>.from(
        jsonDecode(userJson) as Map
      );

      print("✅ Retrieved user data: ${userData['email']}");
      return userData;
    } catch (e) {
      print("❌ Error retrieving user data: $e");
      return null;
    }
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(userData);

      bool success = await prefs.setString('user_data', userJson);

      if (success) {
        print("✅ User data stored successfully!");
      } else {
        print("⚠️ Failed to store user data!");
      }
    } catch (e) {
      print("❌ Error saving user data: $e");
    }
  }
}

