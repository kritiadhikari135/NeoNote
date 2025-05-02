
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/widgets/goal_cards.dart';
import 'package:project/widgets/highlighted_goal_card.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/notification_model.dart';
import 'dart:math' as Math;
import 'goal_helpers.dart';

class GoalPage extends StatefulWidget {
  final int? highlightedGoalId;

  const GoalPage({
    super.key,
    this.highlightedGoalId,
  });

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final List<Goal> _goals = [];
  final List<Goal> _filteredGoals = [];
  final _goalController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _completionDate;
  bool _isLoading = false;
  bool _isSaving = false; // New state variable for saving/updating goals
  bool _isSearchActive = false;
  bool _noGoalsFound = false;
  bool _hasReminder = false;
  DateTime? _reminderDateTime;
  final ScrollController _scrollController = ScrollController();

  // Global key for the highlighted goal card
  final GlobalKey _highlightedGoalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _goalController.addListener(_clearSearchOnGoalFocus);
    _searchController.addListener(_clearGoalOnSearchFocus);

    // If there's a highlighted goal ID, set up a post-frame callback
    if (widget.highlightedGoalId != null) {
      // print('🔍 Setting up post-frame callback for highlighted goal ID: ${widget.highlightedGoalId}');

      // Wait for the first frame to be rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // print('🖼️ First frame rendered, scrolling will be handled after goals are loaded');
        // The actual scrolling is handled in _loadGoals after the goals are loaded
      });
    }
  }

  // Method to scroll to the highlighted goal
  void _scrollToHighlightedGoal() {
    // print('🔍 Attempting to scroll to highlighted goal ID: ${widget.highlightedGoalId}');

    // Wait for goals to load
    if (_isLoading || _goals.isEmpty) {
      // print('⏳ Goals not loaded yet, retrying in 500ms...');
      // Try again after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _scrollToHighlightedGoal();
        }
      });
      return;
    }

    // print('📋 Total goals: ${_goals.length}');

    // Check if the highlighted goal key has a context
    if (_highlightedGoalKey.currentContext != null) {
      // print('✅ Found highlighted goal context, scrolling to it');

      // Use a delay to ensure the UI is fully built
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Use Scrollable.ensureVisible to scroll to the goal card
          Scrollable.ensureVisible(
            _highlightedGoalKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            alignment: 0.0, // Align to the top of the viewport
            curve: Curves.easeInOut,
          );
          // print('✅ Scrolled to highlighted goal');
        }
      });
    } else {
      // print('❌ Highlighted goal context not found, will retry in 500ms');
      // Try again after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _scrollToHighlightedGoal();
        }
      });
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearchOnGoalFocus() {
    if (_goalController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  void _clearGoalOnSearchFocus() {
    if (_searchController.text.isNotEmpty) {
      _goalController.clear();
    }
  }

  Future<void> _loadGoals() async {
    // print('📥 Loading goals...');
    if (widget.highlightedGoalId != null) {
      // print('🎯 Will highlight goal ID: ${widget.highlightedGoalId} after loading');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await GoalService.fetchGoals();
      // print('✅ Successfully loaded ${goals.length} goals');

      // Check if the highlighted goal exists in the loaded goals
      if (widget.highlightedGoalId != null) {
        bool found = false;
        for (var goal in goals) {
          if (goal.id == widget.highlightedGoalId) {
            found = true;
            // print('✅ Highlighted goal found in loaded goals: ${goal.title} (ID: ${goal.id})');
            break;
          }
        }
        if (!found) {
          // print('⚠️ Highlighted goal with ID ${widget.highlightedGoalId} not found in loaded goals');
        }
      }

      if (mounted) {
        setState(() {
          _goals.clear();
          _goals.addAll(goals);
          _filteredGoals.clear();
          _filteredGoals.addAll(goals);
          _goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
          _isLoading = false;
          _isSaving = false; // Also reset saving state when loading completes
        });
      }

      _filterGoals();

      // If there's a highlighted goal, scroll to it after a delay
      if (widget.highlightedGoalId != null) {
        // print('🔍 Will attempt to scroll to highlighted goal after a delay');
        // Use a delay to ensure the UI is fully rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // print('⏱️ Delay complete, now scrolling to highlighted goal');
            _scrollToHighlightedGoal();
          }
        });
      }
    } catch (e) {
      // print('❌ Error loading goals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSaving = false; // Also reset saving state on error
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load goals: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Goal> get _activeGoals {
    return _filteredGoals.where((goal) => !goal.isCompleted).toList();
  }

  List<Goal> get _completedGoals {
    final now = DateTime.now();
    return _filteredGoals.where((goal) {
      if (!goal.isCompleted) return false;
      final completionTime = goal.completionTime;
      if (completionTime == null) return false;
      return now.difference(completionTime).inDays <= 30;
    }).toList();
  }

  void _filterGoals() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGoals.clear();
      _filteredGoals.addAll(_goals.where((goal) {
        String goalTitle = goal.title.toLowerCase();
        String startDate = DateFormat.yMMMd().format(goal.startDate).toLowerCase();
        String completionDate = DateFormat.yMMMd().format(goal.completionDate).toLowerCase();
        return goalTitle.contains(query) ||
            startDate.contains(query) ||
            completionDate.contains(query);
      }));
      _noGoalsFound = _filteredGoals.isEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredGoals.clear();
      _filteredGoals.addAll(_goals);
      _noGoalsFound = false;
    });
  }

  Future<void> _handleAddGoal() async {
    setState(() {
      _isSaving = true; // Show saving indicator instead of loading
    });

    // Debug print to check the reminder date time before adding the goal
    if (_hasReminder && _reminderDateTime != null) {
      // print('Adding goal with reminder date time: ${_reminderDateTime.toString()}');
      // print('Current time: ${DateTime.now().toString()}');
      // print('Time difference in minutes: ${_reminderDateTime!.difference(DateTime.now()).inMinutes}');
    }

    try {
      await addGoal(
        context,
        _goalController,
        _startDate,
        _completionDate,
        setState,
        hasReminder: _hasReminder,
        reminderDateTime: _reminderDateTime,
      );

      // Clear the controllers and dates after adding a goal
      _goalController.clear();
      _startDate = null;
      _completionDate = null;
      _hasReminder = false;
      _reminderDateTime = null;

      // Load goals after successful save
      await _loadGoals();
    } catch (e) {
      // Show error message if goal creation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add goal: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Set loading state to false even if there's an error
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _handleToggleCompletion(Goal goal) async {
    // Show saving indicator
    setState(() {
      _isSaving = true;

      // Optimistically update the UI
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        goal.completionTime = DateTime.now();
        // If goal is being completed, remove any reminder
        goal.hasReminder = false;
        goal.reminderDateTime = null;
      } else {
        goal.completionTime = null;
      }
      _filteredGoals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort goals
    });

    try {
      // Make the API call to update the goal's status
      await GoalService.updateGoal(
        goalId: goal.id,
        title: goal.title,
        startDate: goal.startDate,
        completionDate: goal.completionDate,
        isCompleted: goal.isCompleted,
        completionTime: goal.completionTime,
        hasReminder: goal.hasReminder, // Pass the updated reminder status
        reminderDateTime: goal.reminderDateTime, // Pass the updated reminder time
      );

      // If the goal was completed, remove any associated notification
      if (goal.isCompleted) {
        try {
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          await notificationProvider.removeGoalReminderNotification(goal.id);
        } catch (e) {
          print('Warning: Could not access NotificationProvider to remove notification: $e');
          // Continue even if notification removal fails
        }
      }

      // Hide saving indicator after successful update
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      // Revert the UI update if the API call fails
      setState(() {
        goal.isCompleted = !goal.isCompleted;
        if (goal.isCompleted) {
          goal.completionTime = DateTime.now();
          goal.hasReminder = false;
          goal.reminderDateTime = null;
        } else {
          goal.completionTime = null;
        }
        _isSaving = false; // Hide saving indicator
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to update goal status: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleEditGoal(int index) async {
    // Don't show loading screen when opening the edit dialog
    try {
      await editGoal(
        context,
        index,
        _goals,
        setState,
      );

      // Only show loading when actually saving the goal (handled inside editGoal)
      await _loadGoals(); // This will set _isLoading to false when complete
    } catch (e) {
      // Show error message if goal editing fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to edit goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteGoal(int index) async {
    setState(() {
      _isSaving = true; // Show saving indicator
    });

    try {
      await deleteGoal(
        context,
        index,
        _goals,
        setState,
        (bool loading) {
          // This callback is used by the deleteGoal function to update loading state
          setState(() {
            _isLoading = loading;
          });
        },
      );

      setState(() {
        _filteredGoals.clear();
        _filteredGoals.addAll(_goals);
        _noGoalsFound = _filteredGoals.isEmpty;
        _isSaving = false; // Hide saving indicator
      });
    } catch (e) {
      // Show error message if goal deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete goal: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Hide saving indicator
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF255DE1),
        ),
      ),
    );
  }

  // Method to build goal cards - can be overridden by subclasses
  List<Widget> buildGoalCards(List<Goal> goals) {
    return goals.map((goal) {
      final bool shouldHighlight = widget.highlightedGoalId == goal.id;

      if (shouldHighlight) {
        // Use the highlighted goal card for the highlighted goal with the global key
        // print('🔑 Adding key to highlighted goal card: ${goal.title} (ID: ${goal.id})');
        return Container(
          key: _highlightedGoalKey,
          child: HighlightedGoalCard(
            goal: goal,
            onToggleCompletion: () => _handleToggleCompletion(goal),
            onEdit: () => _handleEditGoal(_goals.indexOf(goal)),
            onDelete: () => _handleDeleteGoal(_goals.indexOf(goal)),
            shouldHighlight: true,
          ),
        );
      } else {
        // Use the regular goal card for other goals
        return GoalCard(
          goal: goal,
          onToggleCompletion: () => _handleToggleCompletion(goal),
          onEdit: () => _handleEditGoal(_goals.indexOf(goal)),
          onDelete: () => _handleDeleteGoal(_goals.indexOf(goal)),
        );
      }
    }).toList();
  }

  // New method to show the Add Goal dialog using the same inputs as before.
  Future<void> _showAddGoalDialog() async {
    // Don't show loading screen when opening the add goal dialog

    // Use a temporary state for the dialog's date selections to keep them in sync with the page
    DateTime? dialogStartDate = _startDate;
    DateTime? dialogCompletionDate = _completionDate;
    bool dialogHasReminder = _hasReminder;

    // Set default reminder time to current time + 2 minutes for testing
    final now = DateTime.now();

    // We want to use the time exactly as it was entered by the user
    // without any time zone conversion
    DateTime? dialogReminderDateTime;
    if (_reminderDateTime != null) {
      dialogReminderDateTime = _reminderDateTime;
    } else {
      // Set a default reminder time (current time + 2 minutes)
      dialogReminderDateTime = now.add(const Duration(minutes: 2));
    }

    // For time picker with AM/PM format
    TimeOfDay? reminderTime = dialogReminderDateTime != null
        ? TimeOfDay(hour: dialogReminderDateTime.hour, minute: dialogReminderDateTime.minute)
        : TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // StatefulBuilder allows us to manage the dialog's internal state.
          builder: (context, setStateDialog) {
            // Add a loading state for the dialog
            bool isDialogSaving = false;

            // We're now using the formatTimeOfDayTo12Hour function from notification_model.dart

            // Use a simple Dialog with fixed width
            return AlertDialog(
                  title: const Text('Add Goal'),
                  content: Container(
                    width: 400, // Fixed width
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _goalController,
                            decoration: InputDecoration(
                              labelText: 'What\'s your goal?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.stars),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dialogStartDate == null
                                    ? 'Select Start Date'
                                    : DateFormat.yMMMd().format(dialogStartDate!),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  // Make sure initialDate is not before firstDate
                                  final firstDate = DateTime(2000);
                                  final now = DateTime.now();
                                  final initialDate = dialogStartDate != null
                                      ? (dialogStartDate!.isBefore(firstDate) ? firstDate : dialogStartDate!)
                                      : now;

                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: firstDate,
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setStateDialog(() {
                                      dialogStartDate = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dialogCompletionDate == null
                                    ? 'Select Completion Date'
                                    : DateFormat.yMMMd().format(dialogCompletionDate!),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  // Make sure initialDate is not before firstDate
                                  final firstDate = DateTime(2000);
                                  final now = DateTime.now();
                                  final initialDate = dialogCompletionDate != null
                                      ? (dialogCompletionDate!.isBefore(firstDate) ? firstDate : dialogCompletionDate!)
                                      : now;

                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: firstDate,
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setStateDialog(() {
                                      dialogCompletionDate = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Reminder Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.notifications, color: Color(0xFF255DE1)),
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
                                value: dialogHasReminder,
                                activeColor: const Color(0xFF255DE1),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    dialogHasReminder = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (dialogHasReminder) ...[
                            const SizedBox(height: 16),
                            // Reminder Date
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
                                          dialogReminderDateTime != null
                                              ? DateFormat.yMMMd().format(dialogReminderDateTime!)
                                              : 'Select Date',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Get current date/time for validation
                                          final DateTime now = DateTime.now();

                                          // Show date picker with current date as minimum
                                          // Ensure initialDate is not before firstDate
                                          DateTime initialDate;
                                          if (dialogReminderDateTime != null) {
                                            // If reminder date is in the past, use current date
                                            initialDate = dialogReminderDateTime!.isBefore(now) ? now : dialogReminderDateTime!;
                                          } else {
                                            initialDate = now;
                                          }

                                          DateTime? pickedDate = await showDatePicker(
                                            context: context,
                                            initialDate: initialDate,
                                            firstDate: now, // Can't pick dates in the past
                                            lastDate: DateTime(2100),
                                          );

                                          if (pickedDate != null) {
                                            // Preserve the time part when updating the date
                                            // This ensures we keep the same time but update the date

                                            // Get the time components from the current reminder time
                                            // or use the current time if no reminder time is set
                                            int hour = reminderTime?.hour ?? now.hour;
                                            int minute = reminderTime?.minute ?? now.minute;

                                            // Create a new DateTime with the selected date and current time
                                            // This will be in the local time zone (Nepal time)
                                            final newDateTime = DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              hour,
                                              minute,
                                            );

                                            // Debug print to check the time
                                            // print('GOAL DATE PICKER - Selected date: ${pickedDate.toString()}');
                                            // print('GOAL DATE PICKER - Selected time: $hour:$minute');
                                            // print('GOAL DATE PICKER - New reminder date time: ${newDateTime.toString()}');
                                            // print('GOAL DATE PICKER - New reminder time zone offset: ${newDateTime.timeZoneOffset}');
                                            // print('GOAL DATE PICKER - Current time: ${now.toString()}');
                                            // print('GOAL DATE PICKER - Current time zone offset: ${now.timeZoneOffset}');
                                            // print('GOAL DATE PICKER - Time difference: ${newDateTime.difference(now)}');
                                            // print('GOAL DATE PICKER - Time difference in minutes: ${newDateTime.difference(now).inMinutes}');
                                            // print('GOAL DATE PICKER - Time difference in seconds: ${newDateTime.difference(now).inSeconds}');

                                            setStateDialog(() {
                                              dialogReminderDateTime = newDateTime;
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
                                          reminderTime != null
                                              ? formatTimeOfDayTo12Hour(reminderTime!)
                                              : 'Select Time',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Show time picker with 12-hour format
                                          TimeOfDay? pickedTime = await showTimePicker(
                                            context: context,
                                            initialTime: reminderTime ?? TimeOfDay.now(),
                                            builder: (BuildContext context, Widget? child) {
                                              return MediaQuery(
                                                data: MediaQuery.of(context).copyWith(
                                                  alwaysUse24HourFormat: false, // Use 12-hour format
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );

                                          if (pickedTime != null) {
                                            setStateDialog(() {
                                              reminderTime = pickedTime;

                                              // Update the full date time with the new time
                                              // This preserves the date but updates the time
                                              if (dialogReminderDateTime != null) {
                                                // Create a new DateTime with the selected date and time
                                                // We want to store the time exactly as selected by the user
                                                // without any time zone conversion

                                                // Get the date components from the current reminder date time
                                                final year = dialogReminderDateTime!.year;
                                                final month = dialogReminderDateTime!.month;
                                                final day = dialogReminderDateTime!.day;

                                                // Create a new DateTime with the selected time
                                                // This will be in the local time zone (Nepal time)
                                                final newDateTime = DateTime(
                                                  year,
                                                  month,
                                                  day,
                                                  pickedTime.hour,
                                                  pickedTime.minute,
                                                );

                                                // Debug print to check the time
                                                final now = DateTime.now();
                                                // print('GOAL TIME PICKER - User selected time: ${pickedTime.hour}:${pickedTime.minute}');
                                                // print('GOAL TIME PICKER - Created new reminder date time: ${newDateTime.toString()}');
                                                // print('GOAL TIME PICKER - New reminder time zone offset: ${newDateTime.timeZoneOffset}');
                                                // print('GOAL TIME PICKER - Current time: ${now.toString()}');
                                                // print('GOAL TIME PICKER - Current time zone offset: ${now.timeZoneOffset}');
                                                // print('GOAL TIME PICKER - Time difference: ${newDateTime.difference(now)}');
                                                // print('GOAL TIME PICKER - Time difference in minutes: ${newDateTime.difference(now).inMinutes}');
                                                // print('GOAL TIME PICKER - Time difference in seconds: ${newDateTime.difference(now).inSeconds}');

                                                dialogReminderDateTime = newDateTime;
                                              } else {
                                                // If no date was set yet, use today's date with the selected time
                                                final now = DateTime.now();
                                                final newDateTime = DateTime(
                                                  now.year,
                                                  now.month,
                                                  now.day,
                                                  pickedTime.hour,
                                                  pickedTime.minute,
                                                );

                                                // Debug print to check the time
                                                // print('Selected time: ${pickedTime.hour}:${pickedTime.minute}');
                                                // print('New reminder date time: ${newDateTime.toString()}');
                                                // print('Current time: ${now.toString()}');
                                                // print('Time difference in minutes: ${newDateTime.difference(now).inMinutes}');

                                                dialogReminderDateTime = newDateTime;
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
                  ),
                  actions: [
                    TextButton(
                      onPressed: isDialogSaving
                        ? null // Disable button when saving
                        : () {
                            // Clear inputs if needed and close dialog.
                            Navigator.pop(context);
                          },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: isDialogSaving
                        ? null // Disable button when saving
                        : () async {
                            // Show loading indicator in the dialog
                            setStateDialog(() {
                              isDialogSaving = true;
                            });

                            // Update the state with the dialog inputs
                            setState(() {
                              _startDate = dialogStartDate;
                              _completionDate = dialogCompletionDate;
                              _hasReminder = dialogHasReminder;
                              _reminderDateTime = dialogHasReminder ? dialogReminderDateTime : null;
                            });

                            // Handle goal addition
                            await _handleAddGoal();

                            // Close dialog only if still mounted
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF255DE1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('Add Goal'),
                        ],
                      ),
                    ),
                  ],
                );

          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to verify the highlighted goal ID
    // print('🏁 GoalPage build called with highlightedGoalId: ${widget.highlightedGoalId}');

    // Make sure we have access to the NotificationProvider
    // This will ensure it's available in the widget tree
    Provider.of<NotificationProvider>(context, listen: false);

    return CustomScaffold(
      selectedPage: 'Goals',
      onItemSelected: (page) {
        // Existing navigation logic remains intact.
      },
      // Added floating action button to add goals.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF255DE1),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isSearchActive,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF255DE1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '✨ Dreams to Achieve ✨',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search goals by name or date...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _filterGoals();
                            _goalController.clear();
                          },
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_noGoalsFound)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Goal not found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_activeGoals.isNotEmpty) ...[
                              _buildSectionHeader('Active Goals 🎯'),
                              ...buildGoalCards(_activeGoals),
                              const SizedBox(height: 24),
                            ],
                            if (_completedGoals.isNotEmpty) ...[
                              _buildSectionHeader('Completed Goals ✅'),
                              ...buildGoalCards(_completedGoals),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || _isSearchActive || _isSaving)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isSaving ? 'Saving goal...' : 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
