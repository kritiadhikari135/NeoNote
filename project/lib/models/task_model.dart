
class TaskModel {
  final int id;
  final String title;
  final String status;
  final String priority;
  final String dueDate;
  final String dateCreated;
  final bool? _hasReminder; // Make this private and nullable
  final DateTime? reminderDateTime;

  // Constructor
  TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.dateCreated,
    bool? hasReminder = false,
    this.reminderDateTime,
  }) : _hasReminder = hasReminder;

  // Getter for hasReminder that always returns a boolean
  bool get hasReminder => _hasReminder ?? false;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? reminderDateTime;
    if (json['reminder_date_time'] != null) {
      try {
        reminderDateTime = DateTime.parse(json['reminder_date_time']);
      } catch (e) {
        print('Error parsing reminder date time: $e');
      }
    }

    // Handle has_reminder field - convert to boolean or leave as null
    bool? hasReminder;
    if (json['has_reminder'] != null) {
      // If it's already a boolean, use it directly
      if (json['has_reminder'] is bool) {
        hasReminder = json['has_reminder'];
      }
      // If it's a string, convert it to boolean
      else if (json['has_reminder'] is String) {
        hasReminder = json['has_reminder'].toLowerCase() == 'true';
      }
      // If it's a number, treat non-zero as true
      else if (json['has_reminder'] is num) {
        hasReminder = json['has_reminder'] != 0;
      }
    }

    return TaskModel(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      priority: json['priority'],
      dueDate: json['due_date'] ?? "",
      dateCreated: json['date_created'],
      hasReminder: hasReminder,
      reminderDateTime: reminderDateTime,
    );
  }
}