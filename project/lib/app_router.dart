import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';
import 'package:project/login_page.dart';
import 'package:project/register_page.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/home_page.dart';
import 'package:project/personalScreen/calender.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppRouter {
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String diaryRoute = '/diary';
  static const String calendarRoute = '/calendar';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomePage());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case diaryRoute:
        return MaterialPageRoute(builder: (_) => DiaryPage());
      case calendarRoute:
        return MaterialPageRoute(builder: (_) => const Calenderpage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Future<String> getInitialRoute() async {
    // Check if user is logged in
    final token = await LocalStorage.getToken();
    if (token == null) {
      return loginRoute;
    }

    // Verify token is valid by making a request to the profile endpoint
    try {
      // Use the appropriate URL based on platform
      String baseUrl;
      // Check if we're running in a browser (web)
      bool isWeb = identical(0, 0.0);

      if (isWeb) {
        // For web, use 127.0.0.1 instead of localhost
        baseUrl = 'http://127.0.0.1:8000';
      } else {
        // For native apps, use localhost
        baseUrl = 'http://localhost:8000';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/accounts/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Token is valid, go to dashboard
        return dashboardRoute;
      } else {
        // Token is invalid, clear it and go to login
        await LocalStorage.clearToken();
        return loginRoute;
      }
    } catch (e) {
      // Error occurred, go to login
      return loginRoute;
    }
  }
}
