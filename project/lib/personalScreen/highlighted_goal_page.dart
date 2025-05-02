import 'package:flutter/material.dart';
import 'package:project/personalScreen/goal.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/widgets/highlighted_goal_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/notification_provider.dart';

// This is a standalone implementation of the goal page with highlighting capability
class HighlightedGoalPage extends StatefulWidget {
  final int? highlightedGoalId;

  const HighlightedGoalPage({
    Key? key,
    this.highlightedGoalId,
  }) : super(key: key);

  @override
  State<HighlightedGoalPage> createState() => _HighlightedGoalPageState();
}

class _HighlightedGoalPageState extends State<HighlightedGoalPage> {
  final List<Goal> _goals = [];
  final List<Goal> _filteredGoals = [];
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchActive = false;
  bool _noGoalsFound = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await GoalService.fetchGoals();
      setState(() {
        _goals.clear();
        _goals.addAll(goals);
        _filteredGoals.clear();
        _filteredGoals.addAll(goals);
        _goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
        _isLoading = false;
      });

      // After loading goals, scroll to the highlighted goal if needed
      if (widget.highlightedGoalId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToHighlightedGoal();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToHighlightedGoal() {
    // Find the index of the highlighted goal
    int highlightedIndex = -1;

    // First check active goals
    for (int i = 0; i < _activeGoals.length; i++) {
      if (_activeGoals[i].id == widget.highlightedGoalId) {
        // Add offset for the section header
        highlightedIndex = i + 1; // +1 for the "Active Goals" header
        break;
      }
    }

    // If not found in active goals, check completed goals
    if (highlightedIndex == -1) {
      for (int i = 0; i < _completedGoals.length; i++) {
        if (_completedGoals[i].id == widget.highlightedGoalId) {
          // Add offset for both section headers and all active goals
          highlightedIndex = _activeGoals.length + i + 2; // +2 for both headers
          break;
        }
      }
    }

    // If found, scroll to it
    if (highlightedIndex >= 0) {
      // Delay a bit to ensure the list is built
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // Approximate the position based on card height
          final double estimatedPosition = highlightedIndex * 150.0; // Approximate height of each card

          _scrollController.animateTo(
            estimatedPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
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

  Future<void> _handleToggleCompletion(Goal goal) async {
    // Optimistically update the UI
    setState(() {
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        goal.completionTime = DateTime.now();
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
      );
    } catch (e) {
      // Revert the UI update if the API call fails
      setState(() {
        goal.isCompleted = !goal.isCompleted;
        if (goal.isCompleted) {
          goal.completionTime = DateTime.now();
        } else {
          goal.completionTime = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update goal status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Make sure we have access to the NotificationProvider
    Provider.of<NotificationProvider>(context, listen: false);

    return CustomScaffold(
      selectedPage: 'Goals',
      onItemSelected: (page) {},
      body: Stack(
        children: [
          Container(
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_activeGoals.isNotEmpty) ...[
                            _buildSectionHeader('Active Goals 🎯'),
                            ..._activeGoals.map((goal) => _buildGoalCard(goal)),
                            const SizedBox(height: 24),
                          ],
                          if (_completedGoals.isNotEmpty) ...[
                            _buildSectionHeader('Completed Goals ✅'),
                            ..._completedGoals.map((goal) => _buildGoalCard(goal)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final bool shouldHighlight = widget.highlightedGoalId == goal.id;

    return HighlightedGoalCard(
      goal: goal,
      onToggleCompletion: () => _handleToggleCompletion(goal),
      onEdit: () {}, // Simplified for this example
      onDelete: () {}, // Simplified for this example
      shouldHighlight: shouldHighlight,
    );
  }
}
