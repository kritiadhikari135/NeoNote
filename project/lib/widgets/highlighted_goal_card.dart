import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // For SystemMouseCursors
import 'package:intl/intl.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/personalScreen/goal_task_detail.dart';

class HighlightedGoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool shouldHighlight;

  const HighlightedGoalCard({
    Key? key,
    required this.goal,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
    this.shouldHighlight = false,
  }) : super(key: key);

  @override
  State<HighlightedGoalCard> createState() => _HighlightedGoalCardState();
}

class _HighlightedGoalCardState extends State<HighlightedGoalCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _borderWidthAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 6000), // 6 seconds for the full animation
      vsync: this,
    );

    // Create animations with a custom curve that stays visible longer
    _borderWidthAnimation = Tween<double>(
      begin: 4.0, // Thicker border
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // Use an interval curve that keeps the border visible for the first 3 seconds
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _borderColorAnimation = ColorTween(
      begin: Colors.red.shade700, // Brighter, more noticeable red
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // Use an interval curve that keeps the color visible for the first 3 seconds
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // Start animation if should highlight
    if (widget.shouldHighlight) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(HighlightedGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If highlight status changed, handle animation
    if (widget.shouldHighlight != oldWidget.shouldHighlight) {
      if (widget.shouldHighlight) {
        _startAnimation();
      } else {
        _animationController.reset();
      }
    }
  }

  void _startAnimation() {
    // Reset and start animation
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: widget.shouldHighlight
                ? Border.all(
                    color: _borderColorAnimation.value ?? Colors.transparent,
                    width: _borderWidthAnimation.value,
                  )
                : null,
          ),
          child: child,
        );
      },
      child: _buildGoalCard(),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      margin: EdgeInsets.zero, // No margin since the container has margin
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Show hand cursor on hover
        child: GestureDetector(
          onTap: () {
            // Navigate to the task list when the goal card is clicked
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailScreen(goal: widget.goal),
              ),
            );
          },
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  widget.goal.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
                            '${DateFormat.yMMMd().format(widget.goal.startDate)} - ${DateFormat.yMMMd().format(widget.goal.completionDate)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    if ((widget.goal.hasReminder) && widget.goal.reminderDateTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notifications_active, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reminder: ${DateFormat('MMM d, yyyy - h:mm a').format(widget.goal.reminderDateTime!)}',
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
                        value: widget.goal.isCompleted,
                        onChanged: (_) => widget.onToggleCompletion(),
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
                          widget.onEdit();
                        } else if (choice == 'delete') {
                          widget.onDelete();
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
}
