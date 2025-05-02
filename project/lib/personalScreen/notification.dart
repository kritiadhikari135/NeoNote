import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/notification_model.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/services/goal_service.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/goal.dart';
import 'package:project/personalScreen/tasklist.dart';
import 'package:project/personalScreen/goal_task_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Initialize notifications when the page is opened
    _refreshNotifications();
  }

  // Refresh notifications
  Future<void> _refreshNotifications() async {
    try {
      if (_isLoading) {
        return; // Prevent multiple simultaneous refreshes
      }

      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // Get token first
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'You need to be logged in to view notifications.';
            _isLoading = false;
          });
        }
        return;
      }

      // Get current user info
      final userData = await LocalStorage.getUser();
      if (userData == null) {
        // Try to fetch user data using the token
        try {
          print("No user data found in storage. Attempting to fetch user profile...");
          final response = await http.get(
            Uri.parse('http://127.0.0.1:8000/api/accounts/profile/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final fetchedUserData = json.decode(response.body);
            print("✅ User profile fetched: $fetchedUserData");

            // Save user data to local storage
            await LocalStorage.saveUser(fetchedUserData);
            print("✅ User data saved to local storage");
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = 'You need to be logged in to view notifications.';
                _isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          print("⚠️ Error fetching user profile: $e");
          if (mounted) {
            setState(() {
              _errorMessage = 'You need to be logged in to view notifications.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Get the notification provider
      if (!mounted) return;
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      // Retry logic for fetching notifications
      int retryCount = 0;
      const int maxRetries = 3;
      while (retryCount < maxRetries) {
        try {
          await notificationProvider.initialize();
          break; // Exit loop if successful
        } catch (error) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception('Failed to fetch notifications after $maxRetries attempts.');
          }
          await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Notification',
      onItemSelected: (page) {},
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Always show the app bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF255DE1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final notifications = notificationProvider.notifications;
                      return Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _isLoading ? null : _refreshNotifications,
                            tooltip: 'Refresh notifications',
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            onPressed: notifications.isEmpty || _isLoading
                                ? () {
                                    // Show message when there are no notifications to mark as read
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No notifications to mark as read'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : () {
                                    notificationProvider.markAllAsRead();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All notifications marked as read'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            tooltip: 'Mark all as read',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: notifications.isEmpty || _isLoading
                                ? () {
                                    // Show message when there are no notifications to delete
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No notifications to delete'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : () {
                                    _showDeleteAllConfirmationDialog(context);
                                  },
                            tooltip: 'Delete all notifications',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final notifications = notificationProvider.notifications;

                  // Show full-screen loading indicator while fetching notifications
                  if (_isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Color(0xFF255DE1),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Loading notifications...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF255DE1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show empty state or error message when no notifications
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _errorMessage.isNotEmpty ? Icons.error_outline : Icons.notifications_off,
                            size: 64,
                            color: _errorMessage.isNotEmpty ? Colors.red.shade300 : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage.isNotEmpty ? _errorMessage : 'No notifications',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: _errorMessage.isNotEmpty ? Colors.red.shade300 : Colors.grey,
                            ),
                          ),
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _refreshNotifications,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF255DE1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  // Check if there are any visible notifications (past due or without due date)
                  bool hasVisibleNotifications = false;
                  for (var notification in notifications) {
                    if (notification.dueDateTime == null) {
                      // Notifications without due date are always visible
                      hasVisibleNotifications = true;
                      break;
                    }

                    // Check if notification is due now or in the past
                    final now = DateTime.now();
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

                    if (isPastOrDueNow) {
                      hasVisibleNotifications = true;
                      break;
                    }
                  }

                  // Show empty state if no visible notifications
                  if (!hasVisibleNotifications && notifications.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_paused,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications to display yet\nYou have ${notifications.length} upcoming notification${notifications.length > 1 ? 's' : ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show notifications list
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];

                      // Check if notification should be displayed
                      final now = DateTime.now();
                      bool shouldShow = true;

                      if (notification.dueDateTime != null) {
                        // Get the due date time
                        DateTime dueDateTime = notification.dueDateTime!;

                        // Debug print - commented out to reduce console output
                        // print('NOTIFICATION FILTER - ID: ${notification.id}, Title: ${notification.title}');
                        // print('NOTIFICATION FILTER - Due: ${dueDateTime.toString()}, Now: ${now.toString()}');

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

                        shouldShow = isPastOrDueNow;
                        // print('NOTIFICATION FILTER - Should show: $shouldShow');
                      }

                      // If notification should not be shown, return an empty container
                      if (!shouldShow) {
                        // print('NOTIFICATION LIST - Hiding notification ID: ${notification.id}, Title: ${notification.title} (not past due yet)');
                        return const SizedBox.shrink();
                      }

                      // print('NOTIFICATION LIST - Showing notification ID: ${notification.id}, Title: ${notification.title} (past due or no due date)');

                      return _buildNotificationCard(context, notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final now = DateTime.now();
    bool isPast = false;
    bool isDueNow = false;

    if (notification.dueDateTime != null) {
      // Get the due date time
      DateTime dueDateTime = notification.dueDateTime!;

      // Debug prints to help diagnose time issues
      // print('NOTIFICATION CARD - Original time: ${dueDateTime.toString()}');
      // print('NOTIFICATION CARD - Due time (24-hour): ${dueDateTime.hour}:${dueDateTime.minute}');
      // print('NOTIFICATION CARD - Due time (12-hour): ${formatTo12Hour(dueDateTime.hour, dueDateTime.minute)}');
      // print('NOTIFICATION CARD - Current time (24-hour): ${now.hour}:${now.minute}');
      // print('NOTIFICATION CARD - Current time (12-hour): ${formatTo12Hour(now.hour, now.minute)}');

      // Calculate the difference in minutes between due time and current time
      int minutesDifference = 0;

      // Calculate total minutes for both times for easier comparison
      int dueTotalMinutes = (dueDateTime.hour * 60) + dueDateTime.minute;
      int nowTotalMinutes = (now.hour * 60) + now.minute;

      // If it's the same day, calculate minute difference
      if (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day == now.day) {
        minutesDifference = nowTotalMinutes - dueTotalMinutes;
      } else if (dueDateTime.year < now.year ||
                (dueDateTime.year == now.year && dueDateTime.month < now.month) ||
                (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day < now.day)) {
        // If it's a past day, it's definitely past due
        minutesDifference = 1; // Just a positive value to indicate past
      } else {
        // Future day
        minutesDifference = -1; // Negative value to indicate future
      }

      // Check if past due or exactly due now
      isPast = minutesDifference > 0;
      isDueNow = minutesDifference == 0;

      // print('NOTIFICATION CARD - Minutes difference: $minutesDifference');
      // print('NOTIFICATION CARD - Is past: $isPast, Is due now: $isDueNow');

      // Get the remaining time from the notification model
      final remainingTime = notification.remainingTime;
      // print('NOTIFICATION CARD - Remaining time: $remainingTime');
    }

    return Dismissible(
      key: Key('notification-${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(context, listen: false)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        // Add a key that includes the read status to force rebuild when it changes
        key: ValueKey('notification-card-${notification.id}-${notification.isRead}'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification.isRead ? 1 : 3,
        color: notification.isRead ? Colors.grey[100] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide(color: Colors.grey[400]!, width: 1)
              : const BorderSide(color: Color(0xFF255DE1), width: 2),
        ),
        child: InkWell(
          onTap: () {
            _handleNotificationTap(context, notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getNotificationIcon(notification, isPast),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              color: notification.isRead ? Colors.grey[700] : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: notification.isRead ? Colors.grey[500] : Colors.grey[600],
                              fontStyle: notification.isRead ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (notification.dueDateTime != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isPast ? Colors.red : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.formattedDueDateTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPast ? Colors.red : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (isDueNow)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "Due now",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            if (!isPast && !isDueNow)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  notification.remainingTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "Overdue",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF255DE1),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'READ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationModel notification, bool isPast) {
    IconData iconData;
    Color iconColor;

    // Check if notification is due now
    bool isDueNow = false;
    if (notification.dueDateTime != null) {
      final now = DateTime.now();
      final dueDateTime = notification.dueDateTime!;

      // Calculate total minutes for both times for easier comparison
      int dueTotalMinutes = (dueDateTime.hour * 60) + dueDateTime.minute;
      int nowTotalMinutes = (now.hour * 60) + now.minute;

      // Check if same day and same time (hour and minute)
      isDueNow = dueDateTime.year == now.year &&
                dueDateTime.month == now.month &&
                dueDateTime.day == now.day &&
                dueTotalMinutes == nowTotalMinutes;
    }

    // If notification is read, use a different icon
    if (notification.isRead) {
      switch (notification.type) {
        case NotificationType.goalReminder:
          iconData = Icons.check_circle;
          iconColor = Colors.grey[400]!;
          break;
        case NotificationType.taskDue:
          iconData = Icons.check_circle;
          iconColor = Colors.grey[400]!;
          break;
        case NotificationType.systemNotification:
          iconData = Icons.check_circle;
          iconColor = Colors.grey[400]!;
          break;
        default:
          iconData = Icons.check_circle;
          iconColor = Colors.grey[400]!;
      }
    } else {
      switch (notification.type) {
        case NotificationType.goalReminder:
          iconData = Icons.flag;
          if (isPast) {
            iconColor = Colors.red;
          } else if (isDueNow) {
            iconColor = Colors.green;
          } else {
            iconColor = const Color(0xFF255DE1);
          }
          break;
        case NotificationType.taskDue:
          iconData = Icons.task_alt;
          if (isPast) {
            iconColor = Colors.red;
          } else if (isDueNow) {
            iconColor = Colors.green;
          } else {
            iconColor = Colors.orange;
          }
          break;
        case NotificationType.systemNotification:
          iconData = Icons.info;
          iconColor = Colors.grey;
          break;
        default:
          iconData = Icons.notifications;
          iconColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // print('👆 User tapped on notification #${notification.id}');

    // Mark notification as read
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.markAsRead(notification.id);

    // Check if it's a goal notification and has a source ID
    if (notification.type == NotificationType.goalReminder && notification.sourceId != null) {
      final int goalId = notification.sourceId!;
      // print('🎯 Found goal ID: $goalId');

      // Navigate to the goal page with the highlighted goal ID
      // print('🚀 Navigating to goal page with highlighted goal ID: $goalId');

      // Use a simple navigation approach with .then() to refresh after returning
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalPage(
            highlightedGoalId: goalId,
          ),
        ),
      ).then((_) {
        // Refresh notifications when returning from the goal page
        if (mounted) {
          // print('🔄 Refreshing notifications after returning from goal page');
          _refreshNotifications();
        }
      });
    }
    // Check if it's a task notification and has a source ID
    else if (notification.type == NotificationType.taskDue && notification.sourceId != null) {
      final int taskId = notification.sourceId!;
      // print('📋 Found task ID: $taskId');

      // First, try to determine if this is a goal task or a regular task
      // We'll check if the notification title contains "Goal Task" or similar
      bool isGoalTask = notification.title.toLowerCase().contains("goal") ||
                        notification.message.toLowerCase().contains("goal");

      if (isGoalTask) {
        // Try to extract the goal ID from the notification message if available
        int? goalId;

        // First try to extract goal ID using the new format "Goal: Title"
        final RegExp goalTitleRegex = RegExp(r'Goal:\s+([^)]+)', caseSensitive: false);
        final titleMatch = goalTitleRegex.firstMatch(notification.message);

        if (titleMatch != null && titleMatch.groupCount >= 1) {
          // We found a goal title, now we need to find the goal ID
          final goalTitle = titleMatch.group(1)!.trim();
          print('Found goal title in notification: $goalTitle');

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Fetch all goals to find the one with matching title
          GoalService.fetchGoals().then((goals) {
            // Close loading indicator
            Navigator.pop(context);

            // Find the goal with matching title
            Goal? matchingGoal;
            try {
              matchingGoal = goals.firstWhere(
                (goal) => goal.title.trim() == goalTitle,
              );
            } catch (e) {
              // No matching goal found
              matchingGoal = null;
            }

            if (matchingGoal != null) {
              // We found the goal, navigate to the task list with highlighted goal
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskScreen(
                    highlightedTaskId: taskId,
                    highlightedGoalId: matchingGoal?.id,
                  ),
                ),
              ).then((_) {
                // Refresh notifications when returning
                if (mounted) {
                  _refreshNotifications();
                }
              });
            } else {
              // Fallback to goal detail screen if we can't find the goal
              // Try to extract goal ID using the old format
              final RegExp goalIdRegex = RegExp(r'goal\s+(\d+)', caseSensitive: false);
              final match = goalIdRegex.firstMatch(notification.message);

              if (match != null && match.groupCount >= 1) {
                goalId = int.tryParse(match.group(1)!);

                if (goalId != null) {
                  // Navigate to the goal detail screen
                  // Ensure goalId is not null before calling fetchGoalById
                  if (goalId != null) {
                    // Convert nullable int? to non-nullable int using null assertion operator
                    // This is safe because we've already checked that goalId is not null
                    int nonNullableGoalId = goalId!;
                    GoalService.fetchGoalById(nonNullableGoalId).then((goal) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalDetailScreen(
                            goal: goal,
                            highlightedTaskId: taskId,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _refreshNotifications();
                        }
                      });
                  }).catchError((_) {
                    // Navigate to the task list as fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskScreen(
                          highlightedTaskId: taskId,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _refreshNotifications();
                      }
                    });
                  });
                  } else {
                    // Navigate to the task list as fallback if goalId is null
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskScreen(
                          highlightedTaskId: taskId,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _refreshNotifications();
                      }
                    });
                  }
                } else {
                  // Navigate to the task list as fallback
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskScreen(
                        highlightedTaskId: taskId,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _refreshNotifications();
                    }
                  });
                }
              } else {
                // Navigate to the task list as fallback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      highlightedTaskId: taskId,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    _refreshNotifications();
                  }
                });
              }
            }
          }).catchError((error) {
            // Close loading indicator
            Navigator.pop(context);

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load goals: $error'),
                backgroundColor: Colors.red,
              ),
            );

            // Navigate to the task list page as a fallback
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskScreen(
                  highlightedTaskId: taskId,
                ),
              ),
            ).then((_) {
              if (mounted) {
                _refreshNotifications();
              }
            });
          });
        } else {
          // Try to extract goal ID using the old format
          final RegExp goalIdRegex = RegExp(r'goal\s+(\d+)', caseSensitive: false);
          final match = goalIdRegex.firstMatch(notification.message);

          if (match != null && match.groupCount >= 1) {
            goalId = int.tryParse(match.group(1)!);

            if (goalId != null) {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Fetch the goal
              // Ensure goalId is not null before calling fetchGoalById
              if (goalId != null) {
                // Convert nullable int? to non-nullable int using null assertion operator
                // This is safe because we've already checked that goalId is not null
                int nonNullableGoalId = goalId!;
                GoalService.fetchGoalById(nonNullableGoalId).then((goal) {
                  // Close loading indicator
                  Navigator.pop(context);

                  // Navigate to the goal detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalDetailScreen(
                        goal: goal,
                        highlightedTaskId: taskId,
                      ),
                    ),
                  ).then((_) {
                    // Refresh notifications when returning
                    if (mounted) {
                      _refreshNotifications();
                    }
                  });
              }).catchError((error) {
                // Close loading indicator
                Navigator.pop(context);

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load goal: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                // Navigate to the task list page as a fallback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      highlightedTaskId: taskId,
                    ),
                  ),
                ).then((_) {
                  // Refresh notifications when returning
                  if (mounted) {
                    _refreshNotifications();
                  }
                });
              });
              } else {
                // Close loading indicator (in case it was shown)
                Navigator.pop(context);

                // Navigate to the task list page as a fallback if goalId is null
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      highlightedTaskId: taskId,
                    ),
                  ),
                ).then((_) {
                  // Refresh notifications when returning
                  if (mounted) {
                    _refreshNotifications();
                  }
                });
              }
            } else {
              // If we couldn't extract the goal ID, navigate to the task list page as a fallback
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskScreen(
                    highlightedTaskId: taskId,
                  ),
                ),
              ).then((_) {
                // Refresh notifications when returning
                if (mounted) {
                  _refreshNotifications();
                }
              });
            }
          } else {
            // If we couldn't extract the goal ID, navigate to the task list page as a fallback
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskScreen(
                  highlightedTaskId: taskId,
                ),
              ),
            ).then((_) {
              // Refresh notifications when returning
              if (mounted) {
                _refreshNotifications();
              }
            });
          }
        }
      } else {
        // Navigate to the regular task list page with the highlighted task ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskScreen(
              highlightedTaskId: taskId,
            ),
          ),
        ).then((_) {
          // Refresh notifications when returning from the task list page
          if (mounted) {
            _refreshNotifications();
          }
        });
      }
    }
  }

  void _showDeleteAllConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .deleteAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
