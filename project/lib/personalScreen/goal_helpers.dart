
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:intl/intl.dart';
import 'package:project/providers/notification_provider.dart';

Future<void> addGoal(
  BuildContext context,
  TextEditingController goalController,
  DateTime? startDate,
  DateTime? completionDate,
  Function setState, {
  bool hasReminder = false,
  DateTime? reminderDateTime,
}) async {
  String goalTitle = goalController.text.trim();

  if (goalTitle.isEmpty) {
    showErrorDialog(context, 'Goal title cannot be empty.');
    return;
  }

  if (startDate == null) {
    showErrorDialog(context, 'Please select a start date.');
    return;
  }

  if (completionDate == null) {
    showErrorDialog(context, 'Please select a completion date.');
    return;
  }

  if (completionDate.isBefore(startDate)) {
    showErrorDialog(context, 'Completion date cannot be earlier than the start date.');
    return;
  }

  // Validate reminder date if reminder is enabled
  if (hasReminder && reminderDateTime != null) {
    // Get current time for comparison
    final now = DateTime.now();

    // We want to use the time exactly as it was entered by the user
    // without any time zone conversion

    // Debug print to check the reminder time
    // print('GOAL HELPERS - Validating reminder time: ${reminderDateTime.toString()}');
    // print('GOAL HELPERS - Reminder time zone offset: ${reminderDateTime.timeZoneOffset}');
    // print('GOAL HELPERS - Current time: ${now.toString()}');
    // print('GOAL HELPERS - Current time zone offset: ${now.timeZoneOffset}');
    // print('GOAL HELPERS - Time difference: ${reminderDateTime.difference(now)}');
    // print('GOAL HELPERS - Time difference in minutes: ${reminderDateTime.difference(now).inMinutes}');
    // print('GOAL HELPERS - Time difference in seconds: ${reminderDateTime.difference(now).inSeconds}');

    // Compare the reminder time with current time
    if (reminderDateTime.isBefore(now)) {
      showErrorDialog(context, 'Reminder time cannot be in the past.');
      return;
    }
  }

  try {
    final newGoal = await GoalService.createGoal(
      title: goalTitle,
      startDate: startDate,
      completionDate: completionDate,
      hasReminder: hasReminder,
      reminderDateTime: reminderDateTime,
    );

    // Add notification if reminder is set
    if (hasReminder && reminderDateTime != null) {
      try {
        // Get the NotificationProvider from the nearest ancestor
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.addGoalReminderNotification(newGoal);
      } catch (e) {
        // print('Warning: Could not access NotificationProvider: $e');
        // Continue without adding notification - it will be added when the app is restarted
      }
    }

    setState(() {
      goalController.clear();
      startDate = null;
      completionDate = null;
    });
  } catch (e) {
    showErrorDialog(context, 'Failed to create goal: $e');
  }
}

void toggleCompletion(
  BuildContext context,
  Goal goal,
  List<Goal> goals,
  Function setState,
) async {
  try {
    final updatedGoal = await GoalService.updateGoal(
      goalId: goal.id,
      title: goal.title,
      startDate: goal.startDate,
      completionDate: goal.completionDate,
      isCompleted: !goal.isCompleted,
      completionTime: !goal.isCompleted ? DateTime.now() : null,
    );

    setState(() {
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        goals[index] = updatedGoal;
        goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
      }
    });
  } catch (e) {
    showErrorDialog(context, 'Failed to update goal status: $e');
  }
}

Future<void> deleteGoal(
  BuildContext context,
  int index,
  List<Goal> goals,
  Function setState,
  Function setLoading,
) async {
  // Show a dialog and wait for confirmation
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Goal'),
      content: const Text('Are you sure you want to delete this goal?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // Begin deletion and update UI state accordingly
  setLoading(true);
  try {
    // Get the goal to be deleted
    final goalToDelete = goals[index];

    // Add the goal to the bin
    Provider.of<BinProvider>(context, listen: false).addDeletedGoal(goalToDelete);

    // Remove any notifications for this goal
    if (goalToDelete.hasReminder ?? false) {
      try {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.removeGoalReminderNotification(goalToDelete.id);
      } catch (e) {
        // print('Warning: Could not access NotificationProvider to remove notification: $e');
        // Continue with deletion even if notification removal fails
      }
    }

    // Delete the goal from the backend
    await GoalService.deleteGoal(goalToDelete.id);

    // Update the UI
    setState(() {
      goals.removeAt(index);
    });

    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal moved to bin')),
    );
  } catch (e) {
    showErrorDialog(context, 'Failed to delete goal: $e');
  } finally {
    setLoading(false);
  }
}


Future<void> editGoal(
  BuildContext context,
  int index,
  List<Goal> goals,
  Function setState,
) async {
  final goal = goals[index];
  TextEditingController editController = TextEditingController(text: goal.title);
  DateTime newStartDate = goal.startDate;
  DateTime newCompletionDate = goal.completionDate;

  // If the goal is completed, ensure reminders are turned off
  bool newHasReminder = goal.isCompleted ? false : goal.hasReminder;
  DateTime? newReminderDateTime = goal.isCompleted ? null : goal.reminderDateTime;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          // Add a loading state for the dialog
          bool isDialogSaving = false;

          return AlertDialog(
                title: const Text('Edit Goal'),
                content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: InputDecoration(
                      labelText: 'Goal Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
              buildDateSelector(
                context,
                label: 'Start Date',
                date: newStartDate,
                onSelect: () async {
                  // Make sure initialDate is not before firstDate
                  final firstDate = DateTime(2000);
                  final initialDate = newStartDate.isBefore(firstDate) ? firstDate : newStartDate;

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF255DE1),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    setStateDialog(() {
                      newStartDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              buildDateSelector(
                context,
                label: 'Completion Date',
                date: newCompletionDate,
                onSelect: () async {
                  // Make sure initialDate is not before firstDate
                  final firstDate = DateTime(2000);
                  final initialDate = newCompletionDate.isBefore(firstDate) ? firstDate : newCompletionDate;

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF255DE1),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    setStateDialog(() {
                      newCompletionDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Only show reminder toggle for non-completed goals
              if (!goal.isCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Color(0xFF255DE1)
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Set Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: newHasReminder,
                      activeColor: const Color(0xFF255DE1),
                      onChanged: (value) {
                        setStateDialog(() {
                          newHasReminder = value;
                          if (value && newReminderDateTime == null) {
                            // Set a default reminder time (tomorrow)
                            newReminderDateTime = DateTime.now().add(const Duration(days: 1));
                          }
                        });
                      },
                    ),
                  ],
                ),
              if (!goal.isCompleted && newHasReminder) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reminder Date & Time (Nepal Time)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date Picker
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              newReminderDateTime != null
                                  ? DateFormat.yMMMd().format(newReminderDateTime!)
                                  : 'Select Date',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final DateTime now = DateTime.now();

                              // Ensure initialDate is not before firstDate
                              DateTime initialDate;
                              if (newReminderDateTime != null) {
                                // If reminder date is in the past, use current date
                                initialDate = newReminderDateTime!.isBefore(now) ? now : newReminderDateTime!;
                              } else {
                                initialDate = now;
                              }

                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: now,
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                // Preserve the time part when updating the date
                                final TimeOfDay reminderTime = newReminderDateTime != null
                                    ? TimeOfDay(hour: newReminderDateTime!.hour, minute: newReminderDateTime!.minute)
                                    : TimeOfDay.now();

                                final newDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  reminderTime.hour,
                                  reminderTime.minute,
                                );
                                setStateDialog(() {
                                  newReminderDateTime = newDateTime;
                                });
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Time Picker
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              newReminderDateTime != null
                                  ? _formatTimeIn12Hour(TimeOfDay(
                                      hour: newReminderDateTime!.hour,
                                      minute: newReminderDateTime!.minute,
                                    ))
                                  : 'Select Time',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              TimeOfDay initialTime = newReminderDateTime != null
                                  ? TimeOfDay(hour: newReminderDateTime!.hour, minute: newReminderDateTime!.minute)
                                  : TimeOfDay.now();

                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                                builder: (BuildContext context, Widget? child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: false,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedTime != null) {
                                setStateDialog(() {
                                  // Update the full date time with the new time
                                  if (newReminderDateTime != null) {
                                    newReminderDateTime = DateTime(
                                      newReminderDateTime!.year,
                                      newReminderDateTime!.month,
                                      newReminderDateTime!.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  } else {
                                    final now = DateTime.now();
                                    newReminderDateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  }
                                });
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Nepal Time Zone info
                      const Text(
                        'Nepal Time (UTC+5:45)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
            actions: [
              TextButton(
                onPressed: isDialogSaving
                  ? null // Disable button when saving
                  : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDialogSaving
                  ? null // Disable button when saving
                  : () async {
                      String editedTitle = editController.text.trim();
                      if (editedTitle.isEmpty) {
                        showErrorDialog(context, 'Title cannot be empty.');
                        return;
                      }

                      if (newCompletionDate.isBefore(newStartDate)) {
                        showErrorDialog(
                            context, 'Completion date cannot be earlier than start date.');
                        return;
                      }

                      // Show loading indicator
                      setStateDialog(() {
                        isDialogSaving = true;
                      });

                      try {
                        // Ensure that completed goals don't have reminders
                        final bool hasReminder = goal.isCompleted ? false : newHasReminder;
                        final DateTime? reminderDateTime = goal.isCompleted ? null : (newHasReminder ? newReminderDateTime : null);

                        final updatedGoal = await GoalService.updateGoal(
                          goalId: goal.id,
                          title: editedTitle,
                          startDate: newStartDate,
                          completionDate: newCompletionDate,
                          isCompleted: goal.isCompleted,
                          completionTime: goal.completionTime,
                          hasReminder: hasReminder,
                          reminderDateTime: reminderDateTime,
                        );

                        // Update notification if reminder is set or removed
                        try {
                          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                          // Only add notification if the goal is not completed and has a reminder
                          if (!updatedGoal.isCompleted && hasReminder && reminderDateTime != null) {
                            await notificationProvider.addGoalReminderNotification(updatedGoal);
                          } else {
                            // If goal is completed or reminder was removed, remove any existing notification
                            await notificationProvider.removeGoalReminderNotification(goal.id);
                          }
                        } catch (e) {
                          print('Warning: Could not access NotificationProvider to update notification: $e');
                          // Continue with goal update even if notification update fails
                        }

                        setState(() {
                          goals[index] = updatedGoal;
                          goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
                        });

                        // Close dialog only if still mounted
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        // Hide loading indicator on error
                        setStateDialog(() {
                          isDialogSaving = false;
                        });
                        showErrorDialog(context, 'Failed to update goal: $e');
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF255DE1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
                ),

            ],
          );
        },
      );
    },
  );
}

Widget buildDateSelector(
  BuildContext context, {
  required String label,
  DateTime? date,
  required VoidCallback onSelect,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey[50],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date == null ? 'Not Selected' : DateFormat.yMMMd().format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onSelect,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Select'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF255DE1),
          ),
        ),
      ],
    ),
  );
}

// Format time in 12-hour format with AM/PM
String _formatTimeIn12Hour(TimeOfDay time) {
  // Convert 0 hour to 12 for 12-hour format
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  // Ensure minutes are always two digits
  final minute = time.minute.toString().padLeft(2, '0');
  // Add AM/PM suffix
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}