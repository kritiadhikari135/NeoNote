import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PlatformHelper {
  /// Returns true if the application is running on the web
  static bool get isWeb => kIsWeb;

  /// Returns true if the application is running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if the application is running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Returns true if the application is running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns true if the application is running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if the application is running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Returns the appropriate base URL for API calls based on platform
  static String getApiBaseUrl() {
    if (kIsWeb) {
      // For web, use 127.0.0.1 instead of localhost to avoid CORS issues
      return 'http://127.0.0.1:8000';
    } else {
      // For native platforms, use localhost
      return 'http://localhost:8000';
    }
  }
}
