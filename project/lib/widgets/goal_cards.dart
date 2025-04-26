// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:project/models/goals_model.dart';

// class GoalCard extends StatelessWidget {
//   final Goal goal;
//   final VoidCallback onToggleCompletion;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;

//   const GoalCard({
//     Key? key,
//     required this.goal,
//     required this.onToggleCompletion,
//     required this.onEdit,
//     required this.onDelete,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           ListTile(
//             contentPadding: const EdgeInsets.all(16),
//             title: Text(
//               goal.title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         '${DateFormat.yMMMd().format(goal.startDate)} - ${DateFormat.yMMMd().format(goal.completionDate)}',
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (goal.tasks.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   LinearProgressIndicator(
//                     value: goal.completionPercentage() / 100,
//                     backgroundColor: Colors.grey[200],
//                     valueColor: const AlwaysStoppedAnimation<Color>(
//                       Color(0xFF255DE1),
//                     ),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${goal.completionPercentage().toStringAsFixed(0)}% Complete',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Transform.scale(
//                   scale: 1.2,
//                   child: Checkbox(
//                     value: goal.isCompleted,
//                     onChanged: (_) => onToggleCompletion(),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     activeColor: const Color(0xFF255DE1),
//                   ),
//                 ),
//                 PopupMenuButton<String>(
//                   icon: const Icon(Icons.more_vert),
//                   onSelected: (choice) {
//                     if (choice == 'edit') {
//                       onEdit();
//                     } else if (choice == 'delete') {
//                       onDelete();
//                     }
//                   },
//                   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                     const PopupMenuItem<String>(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           Icon(Icons.edit, size: 20),
//                           SizedBox(width: 8),
//                           Text('Edit'),
//                         ],
//                       ),
//                     ),
//                     const PopupMenuItem<String>(
//                       value: 'delete',
//                       child: Row(
//                         children: [
//                           Icon(Icons.delete, size: 20, color: Colors.red),
//                           SizedBox(width: 8),
//                           Text('Delete', style: TextStyle(color: Colors.red)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           if (goal.tasks.isNotEmpty) ...[
//             const Divider(),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Tasks',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...goal.tasks.map((task) => _buildTaskItem(task)),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTaskItem(GoalTask task) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Row(
//         children: [
//           Icon(
//             task.status == 'completed'
//                 ? Icons.check_circle
//                 : Icons.radio_button_unchecked,
//             size: 16,
//             color: task.status == 'completed'
//                 ? const Color(0xFF255DE1)
//                 : Colors.grey[400],
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               task.title,
//               style: TextStyle(
//                 decoration: task.status == 'completed'
//                     ? TextDecoration.lineThrough
//                     : null,
//                 color:
//                     task.status == 'completed' ? Colors.grey[600] : Colors.black87,
//               ),
//             ),
//           ),
//           if (task.dueDate != null)
//             Text(
//               DateFormat.yMMMd().format(task.dueDate!),
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class CompletedGoalCard extends StatelessWidget {
//   final Goal goal;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;

//   const CompletedGoalCard({
//     Key? key,
//     required this.goal,
//     required this.onEdit,
//     required this.onDelete,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       color: Colors.grey[50],
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         title: Text(
//           goal.title,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey[600],
//             decoration: TextDecoration.lineThrough,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     '${DateFormat.yMMMd().format(goal.startDate)} - ${DateFormat.yMMMd().format(goal.completionDate)}',
//                     style: TextStyle(color: Colors.grey[400]),
//                   ),
//                 ),
//               ],
//             ),
//             if (goal.completionTime != null) ...[
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   Icon(Icons.check_circle, size: 16, color: Colors.grey[400]),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Completed on ${DateFormat.yMMMd().add_jm().format(goal.completionTime!)}',
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//         trailing: PopupMenuButton<String>(
//           icon: Icon(Icons.more_vert, color: Colors.grey[400]),
//           onSelected: (choice) {
//             if (choice == 'edit') {
//               onEdit();
//             } else if (choice == 'delete') {
//               onDelete();
//             }
//           },
//           itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//             const PopupMenuItem<String>(
//               value: 'edit',
//               child: Row(
//                 children: [
//                   Icon(Icons.edit, size: 20),
//                   SizedBox(width: 8),
//                   Text('Edit'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem<String>(
//               value: 'delete',
//               child: Row(
//                 children: [
//                   Icon(Icons.delete, size: 20, color: Colors.red),
//                   SizedBox(width: 8),
//                   Text('Delete', style: TextStyle(color: Colors.red)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/goals_model.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    Key? key,
    required this.goal,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              goal.title,
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
                        '${DateFormat.yMMMd().format(goal.startDate)} - ${DateFormat.yMMMd().format(goal.completionDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                if (goal.tasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.completionPercentage() / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF255DE1),
                    ),
                    borderRadius: BorderRadius.circular(4),
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
          if (goal.tasks.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...goal.tasks.map((task) => _buildTaskItem(task)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(GoalTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            task.status == 'completed'
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 16,
            color: task.status == 'completed'
                ? const Color(0xFF255DE1)
                : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration: task.status == 'completed'
                    ? TextDecoration.lineThrough
                    : null,
                color:
                    task.status == 'completed' ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
          if (task.dueDate != null)
            Text(
              DateFormat.yMMMd().format(task.dueDate!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}

class CompletedGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompletedGoalCard({
    Key? key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          goal.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            decoration: TextDecoration.lineThrough,
          ),
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
            if (goal.completionTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Completed on ${DateFormat.yMMMd().add_jm().format(goal.completionTime!)}',
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
    );
  }
}