import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  // Get the stored token
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;

      // Check if token is expired and refresh if needed
      if (_isTokenExpired(token)) {
        return await refreshToken();
      }

      return 'Bearer $token';
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  // Store a new token
  static Future<void> setToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('Error storing token: $e');
    }
  }

  // Store a refresh token
  static Future<void> setRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      print('Error storing refresh token: $e');
    }
  }

  // Clear the stored token (for logout)
  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Check if token is expired
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);

      if (data.containsKey('exp')) {
        final exp = data['exp'];
        final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expDate);
      }

      return true; // If no expiration, assume expired
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // Assume expired on error
    }
  }

  // Refresh the token using the refresh token
  static Future<String?> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['access'];

        await setToken(newToken);
        return 'Bearer $newToken';
      } else {
        print('Failed to refresh token: ${response.statusCode}');
        await clearToken(); // Clear invalid tokens
        return null;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  // Login and get a new token
  static Future<bool> login(String email, String password) async {
    try {
      print('Attempting to login with email: $email');
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data['access']);
        await setRefreshToken(data['refresh']);
        print('Login successful, token stored');
        return true;
      } else {
        print('Login failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }
}
