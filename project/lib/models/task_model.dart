

// class TaskModel {
//   final int id;
//   final String title;
//   final String status;
//   final String priority;
//   final String dueDate;
//   final String dateCreated;

//   TaskModel({
//     required this.id,
//     required this.title,
//     required this.status,
//     required this.priority,
//     required this.dueDate,
//     required this.dateCreated,
//   });

//   factory TaskModel.fromJson(Map<String, dynamic> json) {
//     return TaskModel(
//       id: json['id'],
//       title: json['title'],
//       status: json['status'],
//       priority: json['priority'],
//       dueDate: json['due_date'] ?? "",
//       dateCreated: json['date_created'],
//     );
//   }
// }
class TaskModel {
  final int id;
  final String title;
  final String status;
  final String priority;
  final String dueDate;
  final String dateCreated;

  TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.dateCreated,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      priority: json['priority'],
      dueDate: json['due_date'] ?? "",
      dateCreated: json['date_created'],
    );
  }
}