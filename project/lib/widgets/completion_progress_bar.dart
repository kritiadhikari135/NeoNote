import 'package:flutter/material.dart';

class CompletionProgressBar extends StatelessWidget {
  final double percentage;
  final double height;
  final double? width;
  final bool showPercentage;
  final bool animate;

  const CompletionProgressBar({
    Key? key,
    required this.percentage,
    this.height = 12.0,
    this.width,
    this.showPercentage = true,
    this.animate = true,
  }) : super(key: key);

  Color _getProgressColor(double percentage) {
    // Color gradient based on completion percentage
    if (percentage < 30) {
      return Colors.redAccent;
    } else if (percentage < 70) {
      return Colors.orangeAccent;
    } else {
      return Colors.greenAccent.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure percentage is valid
    final safePercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage.clamp(0.0, 100.0);
    final progressColor = _getProgressColor(safePercentage);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPercentage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal Completion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${safePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = width ?? constraints.maxWidth;
              final progressWidth = (safePercentage / 100) * containerWidth;

              return Container(
                height: height,
                width: containerWidth,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: containerWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                    // Progress
                    AnimatedContainer(
                      duration: animate ? const Duration(milliseconds: 800) : Duration.zero,
                      curve: Curves.easeInOut,
                      width: progressWidth.isFinite ? progressWidth : 0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor.withOpacity(0.7),
                            progressColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
