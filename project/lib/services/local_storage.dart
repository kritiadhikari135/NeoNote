



import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setString('auth_token', token);

    if (success) {
      print("✅ Token stored successfully!");
    } else {
      print("⚠️ Failed to store token!");
    }
  }

  static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();

  // Add a small delay to ensure data is loaded properly
  await Future.delayed(Duration(milliseconds: 500));

  String? token = prefs.getString('auth_token');

  if (token == null || token.isEmpty) {
    print("⚠️ No token found in local storage.");
    return null;
  } else {
    print("✅ Retrieved Token: $token");
    return token;
  }
}
static Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');  // Clear the token
  await prefs.remove('user_pages');  // Clear pages data if needed
  print("🗑️ Token and user data cleared!");
}

  
}

