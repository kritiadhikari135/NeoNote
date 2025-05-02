import 'package:flutter/foundation.dart' show kIsWeb;

class UrlHelper {
  /// Returns the appropriate base URL for API calls based on platform
  static String getBaseUrl() {
    if (kIsWeb) {
      // For web, use 127.0.0.1 instead of localhost to avoid CORS issues
      return 'http://127.0.0.1:8000';
    } else {
      // For native platforms, use localhost
      return 'http://localhost:8000';
    }
  }

  /// Returns a full API URL with the given endpoint
  static String getApiUrl(String endpoint) {
    final baseUrl = getBaseUrl();
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    return '$baseUrl/$endpoint';
  }

  /// Adds a timestamp parameter to prevent caching
  static String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (url.contains('?')) {
      return '$url&t=$timestamp';
    } else {
      return '$url?t=$timestamp';
    }
  }
}
