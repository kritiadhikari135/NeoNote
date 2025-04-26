
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:intl/intl.dart';

Future<void> addGoal(
  BuildContext context,
  TextEditingController goalController,
  DateTime? startDate,
  DateTime? completionDate,
  Function setState,
) async {
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

  try {
    final newGoal = await GoalService.createGoal(
      title: goalTitle,
      startDate: startDate,
      completionDate: completionDate,
    );

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

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
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
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: newStartDate,
                    firstDate: DateTime(2000),
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
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: newCompletionDate,
                    firstDate: DateTime(2000),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
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

              try {
                final updatedGoal = await GoalService.updateGoal(
                  goalId: goal.id,
                  title: editedTitle,
                  startDate: newStartDate,
                  completionDate: newCompletionDate,
                  isCompleted: goal.isCompleted,
                  completionTime: goal.completionTime,
                );

                setState(() {
                  goals[index] = updatedGoal;
                  goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
                });
                Navigator.of(context).pop();
              } catch (e) {
                showErrorDialog(context, 'Failed to update goal: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
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