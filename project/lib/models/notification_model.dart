import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';

// Helper function to format time in 12-hour format
String formatTo12Hour(int hour, int minute) {
  final hour12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
  final amPm = hour >= 12 ? 'PM' : 'AM';
  return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
}

// Helper function to format TimeOfDay in 12-hour format
String formatTimeOfDayTo12Hour(TimeOfDay time) {
  // Convert 0 hour to 12 for 12-hour format
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  // Ensure minutes are always two digits
  final minute = time.minute.toString().padLeft(2, '0');
  // Add AM/PM suffix
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? dueDateTime;
  final NotificationType type;
  final int? sourceId; // ID of the related item (goal, diary, etc.)
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.dueDateTime,
    required this.type,
    this.sourceId,
    this.isRead = false,
  });

  // Calculate remaining time until the notification is due
  String get remainingTime {
    if (dueDateTime == null) {
      return '';
    }

    // Get current time
    final now = DateTime.now();
    // print('TIMEAGO - Current time (now): ${now.toString()}');
    // print('TIMEAGO - Current time (12-hour): ${formatTo12Hour(now.hour, now.minute)}');

    // Get the due date time
    DateTime due = dueDateTime!;
    // print('TIMEAGO - Due date time (original): ${due.toString()}');
    // print('TIMEAGO - Due time (24-hour): ${due.hour}:${due.minute}');
    // print('TIMEAGO - Due time (12-hour): ${formatTo12Hour(due.hour, due.minute)}');

    // Check if already overdue
    if (due.isBefore(now)) {
      // print('TIMEAGO - Notification is overdue');
      return 'Overdue';
    }

    // COMPLETELY NEW APPROACH: Calculate time difference manually
    // This avoids any issues with time zones or DateTime calculations

    // First, extract the date components
    final dueYear = due.year;
    final dueMonth = due.month;
    final dueDay = due.day;
    final dueHour = due.hour;
    final dueMinute = due.minute;

    final nowYear = now.year;
    final nowMonth = now.month;
    final nowDay = now.day;
    final nowHour = now.hour;
    final nowMinute = now.minute;

    // print('TIMEAGO - Due date: $dueYear-$dueMonth-$dueDay $dueHour:$dueMinute');
    // print('TIMEAGO - Now date: $nowYear-$nowMonth-$nowDay $nowHour:$nowMinute');

    // Calculate days difference
    int daysDiff = 0;
    if (dueYear > nowYear || dueMonth > nowMonth || dueDay > nowDay) {
      // Simple case: different days
      // For simplicity, we'll just use the difference in days
      final dueDate = DateTime(dueYear, dueMonth, dueDay);
      final nowDate = DateTime(nowYear, nowMonth, nowDay);
      daysDiff = dueDate.difference(nowDate).inDays;
    }

    // Calculate hours and minutes difference
    int hoursDiff = dueHour - nowHour;
    int minutesDiff = dueMinute - nowMinute;

    // Adjust if minutes are negative
    if (minutesDiff < 0) {
      minutesDiff += 60;
      hoursDiff -= 1;
    }

    // Adjust if hours are negative
    if (hoursDiff < 0 && daysDiff > 0) {
      hoursDiff += 24;
      daysDiff -= 1;
    }

    // Convert days to hours
    hoursDiff += daysDiff * 24;

    // print('TIMEAGO - Manual calculation - Hours: $hoursDiff, Minutes: $minutesDiff');

    // Format the remaining time in a human-readable way
    String formattedTime;

    if (hoursDiff > 0) {
      // If more than an hour
      if (minutesDiff > 0) {
        // Include minutes if not exactly on the hour
        formattedTime = '$hoursDiff hour${hoursDiff > 1 ? 's' : ''} $minutesDiff minute${minutesDiff > 1 ? 's' : ''} remaining';
      } else {
        formattedTime = '$hoursDiff hour${hoursDiff > 1 ? 's' : ''} remaining';
      }
    } else if (minutesDiff > 0) {
      formattedTime = '$minutesDiff minute${minutesDiff > 1 ? 's' : ''} remaining';
    } else {
      formattedTime = 'Due now';
    }

    // print('TIMEAGO - Final formatted time: $formattedTime');

    // Return the manually formatted time
    return formattedTime;
  }

  // Format the due date and time in 12-hour format
  String get formattedDueDateTime {
    if (dueDateTime == null) {
      return '';
    }

    // Get the due date time
    DateTime due = dueDateTime!;

    // Debug prints to help diagnose time issues
    // print('TIMEAGO - Original time in formattedDueDateTime: ${due.toString()}');
    // print('TIMEAGO - Due time (24-hour): ${due.hour}:${due.minute}');
    // print('TIMEAGO - Due time (12-hour): ${formatTo12Hour(due.hour, due.minute)}');

    // Extract date and time components
    final year = due.year;
    final month = due.month;
    final day = due.day;
    final hour = due.hour;
    final minute = due.minute;

    // Format the date and time manually
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNames[month - 1];

    // Convert hour to 12-hour format
    final hour12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';

    // Format the time
    final formattedTime = '$monthName $day, $year - $hour12:${minute.toString().padLeft(2, '0')} $amPm';
    // print('TIMEAGO - Formatted due time: $formattedTime');

    return formattedTime;
  }

  // Create a copy of this notification with some fields changed
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? dueDateTime,
    NotificationType? type,
    int? sourceId,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationType {
  goalReminder,
  taskDue,
  systemNotification,
  invitationAccepted,
  invitationRejected,
}
