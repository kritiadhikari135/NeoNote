import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:project/services/local_storage.dart';

/// A service that handles CORS issues in web browsers by using a proxy
class CorsProxyService {
  /// The base URL for the API
  static const String _directBaseUrl = 'http://127.0.0.1:8000';

  /// Public CORS proxy services
  static const List<String> _corsProxies = [
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
    'https://api.allorigins.win/raw?url=',
  ];

  /// The index of the current proxy being used
  static int _currentProxyIndex = 0;

  /// Get the base URL with CORS proxy if needed
  static String getBaseUrl() {
    if (kIsWeb) {
      // For web, use a CORS proxy
      return _corsProxies[_currentProxyIndex] + _directBaseUrl;
    } else {
      // For native platforms, use direct URL
      return _directBaseUrl;
    }
  }

  /// Try the next proxy if the current one fails
  static void rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % _corsProxies.length;
    print('🔄 Rotating to next CORS proxy: ${_corsProxies[_currentProxyIndex]}');
  }

  /// Get authentication headers
  static Future<Map<String, String>> _getAuthHeaders({Map<String, String>? additionalHeaders}) async {
    // Get the token from local storage
    final token = await LocalStorage.getToken();

    // Create base headers
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };

    // Add authorization header if token exists
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('✅ Using authentication token: ${token.substring(0, math.min(10, token.length))}...');
    } else {
      print('⚠️ No authentication token found');
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Make a GET request with CORS handling
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    // If no headers provided, get authentication headers
    final requestHeaders = headers ?? await _getAuthHeaders();

    final url = Uri.parse('${getBaseUrl()}$endpoint');
    print('🔗 Making GET request to: $url');

    try {
      final response = await http.get(url, headers: requestHeaders);

      // Check for authentication errors
      if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
      }

      return response;
    } catch (e) {
      print('❌ Error making GET request: $e');

      // If we're on web and this isn't the last proxy, try the next one
      if (kIsWeb && _currentProxyIndex < _corsProxies.length - 1) {
        rotateProxy();
        return get(endpoint, headers: requestHeaders);
      }

      // Re-throw the error if we've tried all proxies or we're not on web
      rethrow;
    }
  }

  /// Make a POST request with CORS handling
  static Future<http.Response> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    // If no headers provided, get authentication headers
    final requestHeaders = headers ?? await _getAuthHeaders();

    final url = Uri.parse('${getBaseUrl()}$endpoint');
    print('🔗 Making POST request to: $url');

    try {
      final response = await http.post(url, headers: requestHeaders, body: body);

      // Check for authentication errors
      if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
      }

      return response;
    } catch (e) {
      print('❌ Error making POST request: $e');

      // If we're on web and this isn't the last proxy, try the next one
      if (kIsWeb && _currentProxyIndex < _corsProxies.length - 1) {
        rotateProxy();
        return post(endpoint, headers: requestHeaders, body: body);
      }

      // Re-throw the error if we've tried all proxies or we're not on web
      rethrow;
    }
  }

  /// Make a DELETE request with CORS handling
  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    // If no headers provided, get authentication headers
    final requestHeaders = headers ?? await _getAuthHeaders();

    final url = Uri.parse('${getBaseUrl()}$endpoint');
    print('🔗 Making DELETE request to: $url');

    try {
      final response = await http.delete(url, headers: requestHeaders);

      // Check for authentication errors
      if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
      }

      return response;
    } catch (e) {
      print('❌ Error making DELETE request: $e');

      // If we're on web and this isn't the last proxy, try the next one
      if (kIsWeb && _currentProxyIndex < _corsProxies.length - 1) {
        rotateProxy();
        return delete(endpoint, headers: requestHeaders);
      }

      // Re-throw the error if we've tried all proxies or we're not on web
      rethrow;
    }
  }
}
