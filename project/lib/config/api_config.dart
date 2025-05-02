import 'package:project/utils/platform_helper.dart';

class ApiConfig {
  // Base URL for API calls
  static String get baseUrl => PlatformHelper.getApiBaseUrl();
  
  // Authentication endpoints
  static String get loginUrl => '$baseUrl/api/token/';
  static String get refreshTokenUrl => '$baseUrl/api/token/refresh/';
  static String get registerUrl => '$baseUrl/api/accounts/register/';
  static String get profileUrl => '$baseUrl/api/accounts/profile/';
  
  // Workspace endpoints
  static String get invitationsUrl => '$baseUrl/api/work/invitations/';
  static String get projectsUrl => '$baseUrl/api/work/projects/';
  
  // Add timestamp parameter to prevent caching
  static String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (url.contains('?')) {
      return '$url&t=$timestamp';
    } else {
      return '$url?t=$timestamp';
    }
  }
  
  // Standard headers for API requests
  static Map<String, String> getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}
