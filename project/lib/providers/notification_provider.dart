import 'package:flutter/material.dart';
import 'package:project/models/notification_model.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/services/goal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// Import the formatTo12Hour function from notification_model.dart
import 'package:project/models/notification_model.dart' show formatTo12Hour;

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _nextId = 1;
  Timer? _notificationTimer;

  // Constructor to set up the timer
  NotificationProvider() {
    // Check for due notifications immediately when provider is created
    // This ensures the badge count is correct as soon as the app starts
    Future.microtask(() {
      _checkForDueNotifications();
    });

    // Set up a timer to check for new notifications every 5 seconds
    // Using a shorter interval for more responsive updates
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Check if any notifications have become due and update the UI
      _checkForDueNotifications();
    });
  }

  // Method to check if any notifications have become due
  void _checkForDueNotifications() {
    // Get the current time
    final now = DateTime.now();

    // Check if any notifications have become due since the last check
    bool hasNewDueNotifications = false;

    for (var notification in _notifications) {
      // Skip notifications that are already read
      if (notification.isRead) continue;

      // Skip notifications without a due date
      if (notification.dueDateTime == null) continue;

      // Check if this notification is now due
      final dueDateTime = notification.dueDateTime!;

      // Calculate if the notification is due now
      bool isDueNow = false;

      // If it's a past year
      if (dueDateTime.year < now.year) {
        isDueNow = true;
      }
      // If it's the same year but past month
      else if (dueDateTime.year == now.year && dueDateTime.month < now.month) {
        isDueNow = true;
      }
      // If it's the same year and month but past day
      else if (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day < now.day) {
        isDueNow = true;
      }
      // If it's the same day, compare hour and minute
      else if (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day == now.day) {
        // Calculate total minutes for easier comparison
        int dueMinutes = (dueDateTime.hour * 60) + dueDateTime.minute;
        int nowMinutes = (now.hour * 60) + now.minute;

        // Check if due time is now or in the past
        isDueNow = dueMinutes <= nowMinutes;
      }

      if (isDueNow) {
        hasNewDueNotifications = true;
        break; // We found at least one due notification, no need to check more
      }
    }

    // If we found new due notifications, notify listeners to update the UI
    if (hasNewDueNotifications) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel the timer when the provider is disposed
    _notificationTimer?.cancel();
    super.dispose();
  }

  List<NotificationModel> get notifications => _notifications;

  // Get unread notifications count
  int get unreadCount {
    final now = DateTime.now();
    return _notifications.where((notification) {
      // Only count unread notifications
      if (notification.isRead) return false;

      // If notification has no due date, always count it
      if (notification.dueDateTime == null) return true;

      // Check if notification is due now or in the past
      final dueDateTime = notification.dueDateTime!;

      // Compare year, month, day, hour, and minute directly
      bool isPastOrDueNow = false;

      // If it's a past year
      if (dueDateTime.year < now.year) {
        isPastOrDueNow = true;
      }
      // If it's the same year but past month
      else if (dueDateTime.year == now.year && dueDateTime.month < now.month) {
        isPastOrDueNow = true;
      }
      // If it's the same year and month but past day
      else if (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day < now.day) {
        isPastOrDueNow = true;
      }
      // If it's the same day, compare hour and minute
      else if (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day == now.day) {
        // Calculate total minutes for easier comparison
        int dueMinutes = (dueDateTime.hour * 60) + dueDateTime.minute;
        int nowMinutes = (now.hour * 60) + now.minute;

        // Show if due time is earlier than or equal to current time
        isPastOrDueNow = dueMinutes <= nowMinutes;
      }

      // Only count notifications that are due now or in the past
      return isPastOrDueNow;
    }).length;
  }

  // Initialize the provider
  Future<void> initialize() async {
    try {
      // Check if user is authenticated first
      final token = await LocalStorage.getToken();
      if (token == null) {
        print('⚠️ No authentication token found. Skipping notification initialization.');
        _notifications = [];
        notifyListeners();
        return;
      }

      final userData = await LocalStorage.getUser();
      if (userData == null) {
        print('⚠️ No user data found. Skipping notification initialization.');
        _notifications = [];
        notifyListeners();
        return;
      }

      try {
        final apiNotifications = await NotificationService.fetchNotifications();
        _notifications = apiNotifications;
        _sortNotifications();
      } catch (apiError) {
        // Handle API errors gracefully
        print('⚠️ Error fetching notifications from API: $apiError');
        // Don't clear existing notifications on API error
        // Just keep the current state
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error initializing notification provider: $e');
      // Don't clear notifications on general errors
      notifyListeners();
    }
  }

  // Add a goal reminder notification
  Future<void> addGoalReminderNotification(Goal goal) async {
    if (!(goal.hasReminder ?? false) || goal.reminderDateTime == null) {
      return;
    }

    // Ensure we're using the exact same DateTime object from the goal
    // This preserves the original time that was set by the user
    final reminderDateTime = goal.reminderDateTime;

    // Debug print to check the actual reminder time
    final now = DateTime.now();

    // print('NOTIFICATION PROVIDER - Adding reminder notification for goal: ${goal.title}');
    // print('NOTIFICATION PROVIDER - Reminder date/time: ${reminderDateTime.toString()}');

    // Check if the reminder time is in UTC (has 'Z' suffix)
    bool isUtc = reminderDateTime!.toString().endsWith('Z');
    // print('NOTIFICATION PROVIDER - Is UTC time: $isUtc');

    // print('NOTIFICATION PROVIDER - Reminder time (24-hour): ${reminderDateTime.hour}:${reminderDateTime.minute}');
    // print('NOTIFICATION PROVIDER - Reminder time (12-hour): ${formatTo12Hour(reminderDateTime.hour, reminderDateTime.minute)}');
    // print('NOTIFICATION PROVIDER - Current time: ${now.toString()}');
    // print('NOTIFICATION PROVIDER - Current time (12-hour): ${formatTo12Hour(now.hour, now.minute)}');

    // If the time is in UTC, convert it to local time for comparison
    DateTime localReminderDateTime = reminderDateTime;
    if (isUtc) {
      // Convert UTC time to local time
      localReminderDateTime = reminderDateTime.toLocal();
      // print('NOTIFICATION PROVIDER - Reminder date time (converted to local): ${localReminderDateTime.toString()}');
      // print('NOTIFICATION PROVIDER - Reminder time after conversion (24-hour): ${localReminderDateTime.hour}:${localReminderDateTime.minute}');
      // print('NOTIFICATION PROVIDER - Reminder time after conversion (12-hour): ${formatTo12Hour(localReminderDateTime.hour, localReminderDateTime.minute)}');
    }

    // print('NOTIFICATION PROVIDER - Time difference in minutes: ${localReminderDateTime.difference(now).inMinutes}');

    // Check if a notification for this goal already exists
    final existingIndex = _notifications.indexWhere(
      (notification) =>
        notification.type == NotificationType.goalReminder &&
        notification.sourceId == goal.id
    );

    if (existingIndex != -1) {
      // Update existing notification
      _notifications[existingIndex] = _notifications[existingIndex].copyWith(
        title: 'Goal Reminder: ${goal.title}',
        message: 'Reminder for your goal: ${goal.title}',
        dueDateTime: reminderDateTime,
        isRead: false,
      );
    } else {
      // Create new notification
      final notification = NotificationModel(
        id: _nextId++,
        title: 'Goal Reminder: ${goal.title}',
        message: 'Reminder for your goal: ${goal.title}',
        createdAt: DateTime.now(),
        dueDateTime: reminderDateTime,
        type: NotificationType.goalReminder,
        sourceId: goal.id,
      );
      _notifications.add(notification);
    }

    // Sort notifications
    _sortNotifications();

    await _saveNotifications();

    // Check if the new notification is already due
    _checkForDueNotifications();

    // Always notify listeners to update the UI
    notifyListeners();

    // The backend will automatically create/update the notification when the goal is saved
    // No need to make an additional API call here
  }

  // Remove a goal reminder notification
  Future<void> removeGoalReminderNotification(int goalId) async {
    _notifications.removeWhere(
      (notification) =>
        notification.type == NotificationType.goalReminder &&
        notification.sourceId == goalId
    );
    await _saveNotifications();
    notifyListeners();

    // The backend will automatically remove the notification when the goal is updated/deleted
    // No need to make an additional API call here
  }

  // Add a task reminder notification
  Future<void> addTaskReminderNotification(TaskModel task) async {
    // Use the getter which always returns a boolean
    if (!task.hasReminder || task.reminderDateTime == null) {
      return;
    }

    // Ensure we're using the exact same DateTime object from the task
    final reminderDateTime = task.reminderDateTime;

    // Debug print to check the actual reminder time
    final now = DateTime.now();

    // Check if the reminder time is in UTC (has 'Z' suffix)
    bool isUtc = reminderDateTime!.toString().endsWith('Z');

    // If the time is in UTC, convert it to local time for comparison
    DateTime localReminderDateTime = reminderDateTime;
    if (isUtc) {
      // Convert UTC time to local time
      localReminderDateTime = reminderDateTime.toLocal();
    }

    // Check if a notification for this task already exists
    final existingIndex = _notifications.indexWhere(
      (notification) =>
        notification.type == NotificationType.taskDue &&
        notification.sourceId == task.id
    );

    if (existingIndex != -1) {
      // Update existing notification
      _notifications[existingIndex] = _notifications[existingIndex].copyWith(
        title: 'Task Reminder: ${task.title}',
        message: 'Reminder for your task: ${task.title}',
        dueDateTime: reminderDateTime,
        isRead: false,
      );
    } else {
      // Create new notification
      final notification = NotificationModel(
        id: _nextId++,
        title: 'Task Reminder: ${task.title}',
        message: 'Reminder for your task: ${task.title}',
        createdAt: DateTime.now(),
        dueDateTime: reminderDateTime,
        type: NotificationType.taskDue,
        sourceId: task.id,
      );
      _notifications.add(notification);
    }

    // Sort notifications
    _sortNotifications();

    await _saveNotifications();

    // Check if the new notification is already due
    _checkForDueNotifications();

    // Always notify listeners to update the UI
    notifyListeners();

    // The backend will automatically create/update the notification when the task is saved
    // No need to make an additional API call here
  }

  // Add a goal task reminder notification
  Future<void> addGoalTaskReminderNotification(GoalTask task) async {
    print("📢 addGoalTaskReminderNotification called for task ID: ${task.id}, title: ${task.title}");

    // Check if task has reminder
    if (!task.hasReminder || task.reminderDateTime == null) {
      print("❌ Task has no reminder or reminderDateTime is null. hasReminder: ${task.hasReminder}, reminderDateTime: ${task.reminderDateTime}");
      return;
    }

    // Ensure we're using the exact same DateTime object from the task
    final reminderDateTime = task.reminderDateTime;

    // Debug print to check the actual reminder time
    final now = DateTime.now();
    print("📅 Task reminder time: ${reminderDateTime.toString()}, Current time: ${now.toString()}");

    // Check if the reminder time is in UTC (has 'Z' suffix)
    bool isUtc = reminderDateTime!.toString().endsWith('Z');
    print("🌐 Is UTC time: $isUtc");

    // If the time is in UTC, convert it to local time for comparison
    DateTime localReminderDateTime = reminderDateTime;
    if (isUtc) {
      // Convert UTC time to local time
      localReminderDateTime = reminderDateTime.toLocal();
      print("🕒 Converted to local time: ${localReminderDateTime.toString()}");
    }

    // Check if a notification for this task already exists
    final existingIndex = _notifications.indexWhere(
      (notification) =>
        notification.type == NotificationType.taskDue &&
        notification.sourceId == task.id
    );

    // Get the goal title
    String goalTitle = "Unknown Goal";
    try {
      // Fetch the goal to get its title
      final goal = await GoalService.fetchGoalById(task.goal);
      goalTitle = goal.title;
      print("📝 Found goal title: $goalTitle for goal ID: ${task.goal}");
    } catch (e) {
      print("⚠️ Could not fetch goal title: $e");
      // Continue with unknown goal title
    }

    // Create notification title and message with goal information
    final title = 'Goal Task Reminder: ${task.title}';
    final message = 'Reminder for your goal task: ${task.title} (Goal: $goalTitle)';

    print("📝 Creating notification with title: $title");

    if (existingIndex != -1) {
      // Update existing notification
      print("🔄 Updating existing notification at index $existingIndex");
      _notifications[existingIndex] = _notifications[existingIndex].copyWith(
        title: title,
        message: message,
        dueDateTime: reminderDateTime,
        isRead: false,
      );
    } else {
      // Create new notification
      print("➕ Creating new notification for goal task");
      final notification = NotificationModel(
        id: _nextId++,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        dueDateTime: reminderDateTime,
        type: NotificationType.taskDue,
        sourceId: task.id,
      );
      _notifications.add(notification);
      print("✅ Added new notification with ID: ${notification.id}");
    }

    // Sort notifications
    _sortNotifications();

    await _saveNotifications();

    // Check if the new notification is already due
    _checkForDueNotifications();

    // Always notify listeners to update the UI
    notifyListeners();

    // The backend will automatically create/update the notification when the task is saved
    // No need to make an additional API call here
  }

  // Remove a task reminder notification
  Future<void> removeTaskReminderNotification(int taskId) async {
    _notifications.removeWhere(
      (notification) =>
        notification.type == NotificationType.taskDue &&
        notification.sourceId == taskId
    );
    await _saveNotifications();
    notifyListeners();

    // The backend will automatically remove the notification when the task is updated/deleted
    // No need to make an additional API call here
  }

  // Remove a goal task reminder notification
  Future<void> removeGoalTaskReminderNotification(int taskId) async {
    // Reuse the same method since the logic is identical
    await removeTaskReminderNotification(taskId);
  }

  // Mark a notification as read
  Future<bool> markAsRead(int notificationId) async {
    // print('🔄 NotificationProvider: Marking notification #$notificationId as read');

    // First try to update on the server
    bool serverUpdateSuccess = false;
    try {
      await NotificationService.markAsRead(notificationId);
      // print('✅ NotificationProvider: Notification #$notificationId marked as read on server');
      serverUpdateSuccess = true;
    } catch (e) {
      print('❌ NotificationProvider: Failed to mark notification as read on server: $e');
      // We'll still update locally even if server update fails
    }

    // Then update locally regardless of server success
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (index != -1) {
      // Update the notification in memory
      _notifications[index] = _notifications[index].copyWith(isRead: true);

      // Save to local storage immediately
      await _saveNotifications();

      // Check for due notifications after marking as read
      // This ensures the badge count is updated immediately
      _checkForDueNotifications();

      // Notify listeners to update UI
      notifyListeners();

      // print('✅ NotificationProvider: Notification #$notificationId marked as read locally');

      // If server update failed, try to refresh from server to ensure consistency
      if (!serverUpdateSuccess) {
        // Try to refresh notifications from server after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          initialize().catchError((error) {
            // print('❌ Error refreshing notifications after failed server update: $error');
          });
        });
      }

      return true;
    } else {
      // print('⚠️ NotificationProvider: Notification #$notificationId not found');
      return false;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((notification) => notification.copyWith(isRead: true)).toList();
    await _saveNotifications();

    // Check for due notifications after marking all as read
    // This ensures the badge count is updated immediately
    _checkForDueNotifications();

    notifyListeners();

    // Update on the server
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      // print('Failed to mark all notifications as read on server: $e');
      // Continue with local update
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    _notifications.removeWhere((notification) => notification.id == notificationId);
    await _saveNotifications();

    // Check for due notifications after deleting
    // This ensures the badge count is updated immediately
    _checkForDueNotifications();

    notifyListeners();

    // Delete on the server
    try {
      await NotificationService.deleteNotification(notificationId);
    } catch (e) {
      print('Failed to delete notification on server: $e');
      // Continue with local deletion
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();

    // Check for due notifications after deleting all
    // This ensures the badge count is updated immediately
    _checkForDueNotifications();

    notifyListeners();

    // Delete on the server
    try {
      await NotificationService.deleteAllNotifications();
    } catch (e) {
      print('Failed to delete all notifications on server: $e');
      // Continue with local deletion
    }
  }

  // Clear notifications when user logs out
  Future<void> clearNotifications() async {
    // print('🧹 Clearing all notifications from memory');
    _notifications.clear();
    _nextId = 1;
    notifyListeners();
  }



  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current user ID or email to use as a key
      final currentUser = await LocalStorage.getUser();
      if (currentUser == null) {
        // print('⚠️ No user found in local storage, skipping notification saving');
        return;
      }

      final userKey = currentUser['id'] ?? currentUser['email'] ?? 'unknown_user';
      // print('🔑 Saving notifications for user: $userKey');

      final notificationsJson = _notifications.map((notification) => {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'createdAt': notification.createdAt.toIso8601String(),
        'dueDateTime': notification.dueDateTime?.toIso8601String(),
        'type': notification.type.index,
        'sourceId': notification.sourceId,
        'isRead': notification.isRead,
      }).toList();

      // Use a user-specific key for storing notifications
      await prefs.setString('notifications_$userKey', jsonEncode(notificationsJson));
      await prefs.setInt('next_notification_id_$userKey', _nextId);
      // print('💾 Saved ${notificationsJson.length} notifications for user: $userKey');
    } catch (e) {
      print('❌ Error saving notifications: $e');
    }
  }

  // Sort notifications by creation time (newest first) and due date
  void _sortNotifications() {
    _notifications.sort((a, b) {
      // First, sort by read status (unread first)
      if (!a.isRead && b.isRead) return -1;
      if (a.isRead && !b.isRead) return 1;

      // Then sort by creation time (newest first)
      final creationComparison = b.createdAt.compareTo(a.createdAt);

      // If creation times are different, use that for sorting
      if (creationComparison != 0) {
        return creationComparison;
      }

      // If creation times are the same, sort by due date
      if (a.dueDateTime != null && b.dueDateTime != null) {
        // If both have due dates, sort by due date (upcoming first)
        return a.dueDateTime!.compareTo(b.dueDateTime!);
      } else if (a.dueDateTime != null) {
        // a has due date, b doesn't - a comes first
        return -1;
      } else if (b.dueDateTime != null) {
        // b has due date, a doesn't - b comes first
        return 1;
      }

      // If everything else is equal, keep original order
      return 0;
    });

    // Debug print the sorted notifications
    // print('📋 Sorted notifications:');
    for (var notification in _notifications) {
      final dueStr = notification.dueDateTime != null
          ? '${notification.dueDateTime!.toString()}'
          : 'No due date';
      // print('  - ID: ${notification.id}, Title: ${notification.title}, Created: ${notification.createdAt}, Due: $dueStr');
    }
  }

  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current user ID or email to use as a key
      final currentUser = await LocalStorage.getUser();
      if (currentUser == null) {
        print('⚠️ No user found in local storage, skipping notification loading');
        _notifications = [];
        return;
      }

      final userKey = currentUser['id'] ?? currentUser['email'] ?? 'unknown_user';
      // print('🔑 Loading notifications for user: $userKey');

      // Use a user-specific key for storing notifications
      final notificationsJson = prefs.getString('notifications_$userKey');
      // print('📂 Found stored notifications: ${notificationsJson != null}');

      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        final List<dynamic> decodedJson = jsonDecode(notificationsJson);
        // print('📊 Loaded ${decodedJson.length} notifications from storage');

        _notifications = [];
        for (var item in decodedJson) {
          try {
            // Safely extract values with null checks
            final id = item['id'] as int? ?? 0;
            final title = item['title'] as String? ?? 'Notification';
            final message = item['message'] as String? ?? '';
            final createdAtStr = item['createdAt'] as String?;
            final dueDateTimeStr = item['dueDateTime'] as String?;
            final typeIndex = item['type'] as int? ?? 0;
            final sourceId = item['sourceId'] as int?;
            final isRead = item['isRead'] as bool? ?? false;

            // Parse dates safely
            DateTime createdAt;
            try {
              createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
            } catch (e) {
              createdAt = DateTime.now();
            }

            DateTime? dueDateTime;
            if (dueDateTimeStr != null) {
              try {
                dueDateTime = DateTime.parse(dueDateTimeStr);
              } catch (e) {
                dueDateTime = null;
              }
            }

            // Create notification with safe values
            final notification = NotificationModel(
              id: id,
              title: title,
              message: message,
              createdAt: createdAt,
              dueDateTime: dueDateTime,
              type: NotificationType.values[typeIndex.clamp(0, NotificationType.values.length - 1)],
              sourceId: sourceId,
              isRead: isRead,
            );

            _notifications.add(notification);
          } catch (e) {
            print('❌ Error parsing notification: $e');
            // Skip this notification
          }
        }

        _nextId = prefs.getInt('next_notification_id_$userKey') ?? 1;
      } else {
        // print('📭 No notifications found in storage for user: $userKey');
        _notifications = [];
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      // Initialize with empty list
      _notifications = [];
    }
  }
}
