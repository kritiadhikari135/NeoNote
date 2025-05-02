import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:project/models/notification_model.dart';
import 'package:project/services/local_storage.dart';

class NotificationService {
  // Base URL for the API
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Notifications endpoint - corrected to match Django router structure
  static const String notificationsEndpoint = '/notifications/notifications';

  // Print the full URL for debugging
  static void _logUrl(String endpoint) {
    print('🔗 API URL: $baseUrl$notificationsEndpoint$endpoint');
  }

  // Get headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    // Make sure the token has the correct format
    String authToken = token;
    if (!token.startsWith('Bearer ')) {
      authToken = 'Bearer $token';
    }

    print('🔑 Using authentication token: ${authToken.substring(0, math.min(16, authToken.length))}...');

    return {
      'Content-Type': 'application/json',
      'Authorization': authToken,
    };
  }

  // Fetch all notifications for the current user
  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final endpoint = '';
      _logUrl(endpoint);
      print('📡 Fetching notifications...');

      // Get user info for debugging
      final userData = await LocalStorage.getUser();
      if (userData == null) {
        print('⚠️ No user data found. Please log in to fetch notifications.');
        throw Exception('User not logged in. Please log in to view notifications.');
      }

      print('🧑‍💻 Fetching notifications for user: ${userData['email']}');

      final response = await http.get(
        Uri.parse('$baseUrl$notificationsEndpoint$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ Response status code: 200');
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> data = decodedData is List ? decodedData : decodedData['results'] ?? [];
        print('✅ Successfully processed ${data.length} notifications from API');

        // Convert to notification models
        final notifications = data.map((item) => _convertToNotificationModel(item)).toList();

        // Print detailed notification information
        print('📊 Notification details:');
        if (notifications.isEmpty) {
          print('   No notifications found for this user');
        } else {
          for (var notification in notifications) {
            print('   - ID: ${notification.id}');
            print('     Title: ${notification.title}');
            print('     Message: ${notification.message}');
            print('     Type: ${notification.type}');
            print('     Created: ${notification.createdAt}');
            print('     Due: ${notification.dueDateTime}');
            print('     Source ID: ${notification.sourceId}');
            print('     Read: ${notification.isRead}');
            print('     ---');
          }
        }

        return notifications;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        print('🔒 Response body: ${response.body}');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        print('❌ Failed to load notifications: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        // Try to parse the error message from the response
        String errorMessage = 'Failed to load notifications: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = 'Error: ${errorData['detail']}';
          }
        } catch (e) {
          // If we can't parse the error, just use the default message
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      throw Exception('Failed to load notifications. Please check your connection and try again.');
    }
  }

  // Mark a notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Marking notification #$notificationId as read');

      // Use the correct endpoint format as defined in the Django ViewSet
      // Make sure we're using the correct format for the API endpoint
      final endpoint = '/$notificationId/mark_as_read/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      // Add extra debugging
      print('🔍 Notification ID: $notificationId');
      print('🔍 Headers: $headers');

      // Try to get user data to ensure we're authenticated
      final userData = await LocalStorage.getUser();
      if (userData == null) {
        print('⚠️ No user data found. Please log in to mark notifications as read.');
        throw Exception('User not logged in. Please log in to mark notifications as read.');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ Notification marked as read');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Marking all notifications as read');

      final endpoint = '/mark_all_as_read/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ All notifications marked as read');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Deleting notification #$notificationId');

      final endpoint = '/$notificationId/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 204) {
        print('✅ Notification deleted');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Deleting all notifications');

      final endpoint = '/delete_all/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 204) {
        print('✅ All notifications deleted');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to delete all notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Convert API response to NotificationModel
  static NotificationModel _convertToNotificationModel(Map<String, dynamic> json) {
    print('🔄 Converting notification JSON: $json');

    // Parse dates safely
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'] ?? json['createdAt'];
      if (createdAtStr != null) {
        createdAt = DateTime.parse(createdAtStr.toString());
        print('✅ Parsed createdAt: $createdAt');
      } else {
        print('⚠️ No createdAt found, using current time');
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('❌ Error parsing createdAt: $e');
      createdAt = DateTime.now();
    }

    DateTime? dueDateTime;
    try {
      final dueDateTimeStr = json['due_date_time'] ?? json['dueDateTime'];
      if (dueDateTimeStr != null) {
        dueDateTime = DateTime.parse(dueDateTimeStr.toString());
        print('✅ Parsed dueDateTime: $dueDateTime');
      }
    } catch (e) {
      print('❌ Error parsing dueDateTime: $e');
      dueDateTime = null;
    }

    // Determine notification type
    NotificationType type;
    try {
      final notificationType = json['notification_type'] ?? json['type'];

      if (notificationType is int) {
        final typeIndex = notificationType;
        if (typeIndex >= 0 && typeIndex < NotificationType.values.length) {
          type = NotificationType.values[typeIndex];
          print('✅ Using type from index: $type');
        } else {
          print('⚠️ Type index out of range: $typeIndex');
          type = NotificationType.systemNotification;
        }
      } else if (notificationType is String) {
        final typeStr = notificationType;
        switch (typeStr) {
          case 'goal_reminder':
            type = NotificationType.goalReminder;
            break;
          case 'task_due':
            type = NotificationType.taskDue;
            break;
          case 'invitation_accepted':
            type = NotificationType.invitationAccepted;
            break;
          case 'invitation_rejected':
            type = NotificationType.invitationRejected;
            break;
          default:
            try {
              type = NotificationType.values.firstWhere(
                (e) => e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
                orElse: () {
                  print('⚠️ Type string not found: $typeStr');
                  return NotificationType.systemNotification;
                },
              );
            } catch (e) {
              print('❌ Error parsing type string: $e');
              type = NotificationType.systemNotification;
            }
        }
        print('✅ Using type from string: $type');
      } else {
        print('⚠️ No valid type found, using default');
        type = NotificationType.systemNotification;
      }
    } catch (e) {
      print('❌ Error determining notification type: $e');
      type = NotificationType.systemNotification;
    }

    // Get ID safely
    int id;
    try {
      if (json['id'] is int) {
        id = json['id'];
      } else if (json['id'] is String) {
        id = int.parse(json['id']);
      } else {
        id = 0;
      }
    } catch (e) {
      print('❌ Error parsing ID: $e');
      id = 0;
    }

    // Get source ID safely
    int? sourceId;
    try {
      final rawSourceId = json['source_id'] ?? json['sourceId'];
      if (rawSourceId is int) {
        sourceId = rawSourceId;
      } else if (rawSourceId is String) {
        sourceId = int.parse(rawSourceId);
      }
    } catch (e) {
      print('❌ Error parsing sourceId: $e');
      sourceId = null;
    }

    // Get isRead safely
    bool isRead;
    try {
      final rawIsRead = json['is_read'] ?? json['isRead'] ?? false;
      if (rawIsRead is bool) {
        isRead = rawIsRead;
      } else if (rawIsRead is String) {
        isRead = rawIsRead.toLowerCase() == 'true';
      } else if (rawIsRead is int) {
        isRead = rawIsRead != 0;
      } else {
        isRead = false;
      }
    } catch (e) {
      print('❌ Error parsing isRead: $e');
      isRead = false;
    }

    // Create and return the notification model
    final notification = NotificationModel(
      id: id,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      createdAt: createdAt,
      dueDateTime: dueDateTime,
      type: type,
      sourceId: sourceId,
      isRead: isRead,
    );

    print('✅ Successfully converted notification: ${notification.id} - ${notification.title}');
    return notification;
  }

  // Get unread invitation notification count
  static Future<int> getUnreadInvitationResponseCount() async {
    try {
      // Check if user is authenticated first
      final token = await LocalStorage.getToken();
      if (token == null) {
        print('⚠️ No authentication token found. Skipping invitation count check.');
        return 0;
      }

      try {
        final headers = await _getAuthHeaders();
        print('📡 Fetching unread invitation response count');

        final endpoint = '/unread_invitation_responses/';
        _logUrl(endpoint);

        // Print the full URL for debugging
        final url = '$baseUrl$notificationsEndpoint$endpoint';
        print('🔗 Full URL: $url');

        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final count = data['count'] ?? 0;
          print('✅ Unread invitation response count: $count');
          return count;
        } else if (response.statusCode == 401) {
          print('🔒 Authentication failed. Token might be expired.');
          await LocalStorage.clearToken();
          return 0;
        } else {
          print('❌ Failed to get unread invitation response count: ${response.statusCode}');
          return 0;
        }
      } catch (apiError) {
        print('❌ API error getting unread invitation response count: $apiError');
        return 0;
      }
    } catch (e) {
      print('❌ Error getting unread invitation response count: $e');
      return 0; // Return 0 on error to avoid breaking the UI
    }
  }

  // Mark invitation response notifications as read
  static Future<bool> markInvitationResponsesAsRead() async {
    try {
      print('📡 Marking invitation responses as read');

      // Get all notifications first
      final notifications = await fetchNotifications();

      // Filter for invitation response notifications
      final invitationResponses = notifications.where((notification) =>
        !notification.isRead &&
        (notification.type == NotificationType.invitationAccepted ||
         notification.type == NotificationType.invitationRejected)
      ).toList();

      // If there are no unread invitation responses, return early
      if (invitationResponses.isEmpty) {
        print('✅ No unread invitation responses to mark as read');
        return true;
      }

      // Mark each one as read individually
      for (var notification in invitationResponses) {
        try {
          await markAsRead(notification.id);
        } catch (e) {
          print('⚠️ Error marking notification ${notification.id} as read: $e');
          // Continue with other notifications even if one fails
        }
      }

      print('✅ Marked ${invitationResponses.length} invitation responses as read');
      return true;
    } catch (e) {
      print('❌ Error marking invitation responses as read: $e');
      return false;
    }
  }
}
