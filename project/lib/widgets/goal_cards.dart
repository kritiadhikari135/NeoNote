
import 'package:flutter/material.dart'; // Includes SystemMouseCursors
import 'package:intl/intl.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/personalScreen/goal_task_detail.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/services/goal_task.dart';
import 'package:project/widgets/completion_progress_bar.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
  });

  // Method to refresh goal data
  Future<void> _refreshGoalData(BuildContext context) async {
    try {
      // Always fetch the latest tasks to ensure we have up-to-date data
      await goal.fetchTasksIfNeeded();

      // Force a rebuild of the widget if it's still mounted
      if (context is Element && context.mounted) {
        context.markNeedsBuild();
      }

      // Debug print to verify the completion percentage
      print('🔄 Goal "${goal.title}" completion: ${goal.completionPercentage().toStringAsFixed(1)}%');
      print('   Tasks: ${goal.tasks.length} total, ${goal.tasks.where((task) => task.status == 'completed').length} completed');
    } catch (e) {
      print('❌ Error refreshing goal data: $e');
      // Silently handle errors - we don't want to disrupt the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't refresh on every build to prevent infinite loops
    // We'll only refresh when returning from the detail page

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Show hand cursor on hover
        child: GestureDetector(
          onTap: () async {
            // Navigate to the task list when the goal card is clicked
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailScreen(goal: goal),
              ),
            );

            // Always refresh the goal data when returning from the goal detail page
            try {
              // Fetch the latest goal data with updated task information
              final updatedGoal = await GoalService.fetchGoalById(goal.id);
              // Update the goal object with the latest data
              goal.tasks = updatedGoal.tasks;
              // Force a rebuild of the widget
              (context as Element).markNeedsBuild();

              print('✅ Refreshed goal "${goal.title}" after returning from detail page');
              print('   Completion: ${goal.completionPercentage().toStringAsFixed(1)}%');
              print('   Tasks: ${goal.tasks.length} total, ${goal.tasks.where((task) => task.status == 'completed').length} completed');
            } catch (e) {
              print('❌ Error refreshing goal after detail page: $e');
            }
          },
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // New Progress bar using CompletionProgressBar widget
                    CompletionProgressBar(
                      percentage: goal.completionPercentage(),
                      height: 8.0,
                      showPercentage: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.completionPercentage().toStringAsFixed(0)}% Complete',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${DateFormat.yMMMd().format(goal.startDate)} - ${DateFormat.yMMMd().format(goal.completionDate)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    if (goal.hasReminder && goal.reminderDateTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notifications_active, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reminder: ${DateFormat('MMM d, yyyy - h:mm a').format(_getLocalDateTime(goal.reminderDateTime!))}',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: goal.isCompleted,
                        onChanged: (_) => onToggleCompletion(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: const Color(0xFF255DE1),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (choice) {
                        if (choice == 'edit') {
                          onEdit();
                        } else if (choice == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // Helper method to handle DateTime display
  // We want to display the time exactly as it was entered by the user
  DateTime _getLocalDateTime(DateTime dateTime) {
    // We no longer need to convert the time zone
    // Just return the original date time
    return dateTime;
  }
}

class CompletedGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompletedGoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  // Method to refresh goal data
  Future<void> _refreshGoalData(BuildContext context) async {
    try {
      // Always fetch the latest tasks to ensure we have up-to-date data
      await goal.fetchTasksIfNeeded();

      // Force a rebuild of the widget if it's still mounted
      if (context is Element && context.mounted) {
        context.markNeedsBuild();
      }

      // Debug print to verify the completion percentage
      print('🔄 Completed Goal "${goal.title}" completion: ${goal.completionPercentage().toStringAsFixed(1)}%');
      print('   Tasks: ${goal.tasks.length} total, ${goal.tasks.where((task) => task.status == 'completed').length} completed');
    } catch (e) {
      print('❌ Error refreshing completed goal data: $e');
      // Silently handle errors - we don't want to disrupt the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't refresh on every build to prevent infinite loops
    // We'll only refresh when returning from the detail page
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[50],
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Show hand cursor on hover
        child: GestureDetector(
          onTap: () async {
            // Navigate to the task list when the goal card is clicked
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailScreen(goal: goal),
              ),
            );

            // Always refresh the goal data when returning from the goal detail page
            try {
              // Fetch the latest goal data with updated task information
              final updatedGoal = await GoalService.fetchGoalById(goal.id);
              // Update the goal object with the latest data
              goal.tasks = updatedGoal.tasks;
              // Force a rebuild of the widget
              (context as Element).markNeedsBuild();

              print('✅ Refreshed completed goal "${goal.title}" after returning from detail page');
              print('   Completion: ${goal.completionPercentage().toStringAsFixed(1)}%');
              print('   Tasks: ${goal.tasks.length} total, ${goal.tasks.where((task) => task.status == 'completed').length} completed');
            } catch (e) {
              print('❌ Error refreshing completed goal after detail page: $e');
            }
          },
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // New Progress bar using CompletionProgressBar widget for completed goals
                const CompletionProgressBar(
                  percentage: 100.0, // Always 100% for completed goals
                  height: 8.0,
                  showPercentage: false,
                ),
                const SizedBox(height: 4),
                Text(
                  '100% Complete',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${DateFormat.yMMMd().format(goal.startDate)} - ${DateFormat.yMMMd().format(goal.completionDate)}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
                if (goal.hasReminder && goal.reminderDateTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.notifications_active, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Reminder: ${DateFormat('MMM d, yyyy - h:mm a').format(_getLocalDateTime(goal.reminderDateTime!))}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (goal.completionTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Completed on ${DateFormat.yMMMd().add_jm().format(_getLocalDateTime(goal.completionTime!))}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onSelected: (choice) {
                if (choice == 'edit') {
                  onEdit();
                } else if (choice == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to handle DateTime display
  // We want to display the time exactly as it was entered by the user
  DateTime _getLocalDateTime(DateTime dateTime) {
    // We no longer need to convert the time zone
    // Just return the original date time
    return dateTime;
  }
}