import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';
import 'package:intl/intl.dart'; // For date formatting

// Extension to capitalize words
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class ProjectTaskList extends StatefulWidget {
  final int projectId;
  final List<Map<String, dynamic>> teamMembers;

  const ProjectTaskList({
    Key? key,
    required this.projectId,
    required this.teamMembers,
  }) : super(key: key);

  @override
  _ProjectTaskListState createState() => _ProjectTaskListState();
}

class _ProjectTaskListState extends State<ProjectTaskList> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProjectTasks();
  }

  Future<void> _fetchProjectTasks() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .get(
            Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tasks = data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load tasks: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _error = 'Connection error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(
    String title,
    int? assignedToId,
    String priority,
    DateTime dueDate,
  ) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        // Check if mounted before using context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'title': title,
              'assigned_to_id': assignedToId,
              'priority': priority,
              'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        // Check if mounted before using context or modifying state
        if (!mounted) return;

        final data = json.decode(response.body);
        setState(() {
          _tasks.add(data);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Check if mounted before using context
        if (!mounted) return;

        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: ${errorData.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Check if mounted before using context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    int? selectedAssigneeId;
    String? selectedPriority;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedAssigneeId,
                      onChanged: (value) => setModalState(() => selectedAssigneeId = value),
                      items: widget.teamMembers.map((m) => DropdownMenuItem<int>(
                        value: m['id'],
                        child: Text(m['full_name']),
                      )).toList(),
                      decoration: const InputDecoration(labelText: 'Assign To'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      onChanged: (value) => setModalState(() => selectedPriority = value),
                      items: ['Low', 'Medium', 'High']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      decoration: const InputDecoration(labelText: 'Priority'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(dueDate == null
                              ? 'Select Due Date'
                              : 'Due: ${DateFormat.yMd().format(dueDate!)}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => dueDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && selectedPriority != null && dueDate != null) {
                      _addTask(
                        titleController.text,
                        selectedAssigneeId,
                        selectedPriority!.toLowerCase(),
                        dueDate!,
                      );
                      Navigator.pop(context);
                    } else {
                      // Check if mounted before using context (though less likely needed here as it's synchronous)
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.black;
    }
  }

  Widget _buildColoredLabel(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // shrink-wrap vertically
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _showAddTaskDialog,
            child: const Text('Add Task'),
          ),
        ),

        if (_isLoading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ] else if (_error != null) ...[
          const SizedBox(height: 24),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ] else if (_tasks.isEmpty) ...[
          const SizedBox(height: 24),
          const Center(
            child: Text('No tasks available.', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Table(
                  columnWidths: {
                    0: const FlexColumnWidth(3),
                    1: const FlexColumnWidth(3),
                    2: const FlexColumnWidth(2),
                    3: const FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(color: Colors.indigo[50]),
                      children: const [
                        Padding(padding: EdgeInsets.all(12), child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    // Data rows
                    for (var task in _tasks)
                      TableRow(children: [
                        Padding(padding: const EdgeInsets.all(12), child: Text(task['title'] ?? 'Unnamed Task')),
                        Padding(padding: const EdgeInsets.all(12), child: Text(task['assigned_to']?['full_name'] ?? 'Unassigned')),
                        Padding(padding: const EdgeInsets.all(12), child: _buildColoredLabel(
                          (task['priority'] ?? 'low').toString().capitalize(),
                          _getPriorityColor(task['priority'] ?? 'low'),
                        )),
                        Padding(padding: const EdgeInsets.all(12), child: Text(task['due_date'] ?? '')),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
