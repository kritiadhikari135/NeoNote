import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import 'package:project/services/local_storage.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:file_picker/file_picker.dart'; // For picking files
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

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
    super.key,
    required this.projectId,
    required this.teamMembers,
  });

  @override
  ProjectTaskListState createState() => ProjectTaskListState();
}

class ProjectTaskListState extends State<ProjectTaskList> {
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
    // Calculate width based on text length
    final double width = text.length * 16.0; // Adjust the multiplier as needed

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withAlpha(38),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withAlpha(100), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Build a hoverable table row with stylish effects
  TableRow _buildHoverableTableRow(Map<String, dynamic> task) {
    // Get priority color for consistent hover effects
    final priorityColor = _getPriorityColor(task['priority'] ?? 'low');

    return TableRow(
      decoration: BoxDecoration(
        color: Colors.transparent,
        // Add a subtle border bottom for better separation
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      children: [
        // Title column with hover effect
        Builder(
          builder: (context) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTaskDetailDialog(task),
                    hoverColor: priorityColor.withAlpha(25),
                    splashColor: priorityColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task['title'] ?? 'Unnamed Task',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Assigned To column with hover effect
        Builder(
          builder: (context) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTaskDetailDialog(task),
                    hoverColor: priorityColor.withAlpha(25),
                    splashColor: priorityColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(task['assigned_to']?['full_name'] ?? 'Unassigned'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Priority column with hover effect
        Builder(
          builder: (context) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTaskDetailDialog(task),
                    hoverColor: priorityColor.withAlpha(25),
                    splashColor: priorityColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildColoredLabel(
                        (task['priority'] ?? 'low').toString().capitalize(),
                        _getPriorityColor(task['priority'] ?? 'low'),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Due Date column with hover effect
        Builder(
          builder: (context) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTaskDetailDialog(task),
                    hoverColor: priorityColor.withAlpha(25),
                    splashColor: priorityColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(task['due_date'] ?? ''),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showTaskDetailDialog(Map<String, dynamic> task) async {
    // Fetch task submissions
    List<dynamic> submissions = await _fetchTaskSubmissions(task['id']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxWidth: 900, // Set a maximum width for very large screens
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog title with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Task: ${task['title']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Content wrapped in Expanded and SingleChildScrollView
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task details section
                            const Text('Task Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            _buildDetailRow('Priority', _buildColoredLabel(
                              (task['priority'] ?? 'low').toString().capitalize(),
                              _getPriorityColor(task['priority'] ?? 'low'),
                            )),
                            _buildDetailRow(
                              'Assigned To',
                              task['assigned_to'] != null
                                ? _buildUserNameWidget(task['assigned_to']['full_name'])
                                : const Text('Unassigned', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                            ),
                            _buildDetailRow(
                              'Due Date',
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  task['due_date'] ?? 'No due date',
                                  style: TextStyle(
                                    color: task['due_date'] != null ? Colors.black87 : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            ),
                            _buildDetailRow(
                              'Created By',
                              task['created_by'] != null
                                ? _buildUserNameWidget(task['created_by']['full_name'])
                                : const Text('Unknown', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                            ),

                            const SizedBox(height: 16),
                            const Divider(),

                            // File submission section
                            const Text('Submit Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload File'),
                              onPressed: () => _uploadFile(task['id']),
                            ),

                            const SizedBox(height: 16),
                            const Divider(),

                            // Submissions list section
                            const Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),

                            if (submissions.isEmpty)
                              const Text('No submissions yet')
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: submissions.map((submission) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.indigo.shade100),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getFileIcon(submission['file_name']?.split('.').last ?? ''),
                                                  size: 18,
                                                  color: _getFileColor(submission['file_name']?.split('.').last ?? ''),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    submission['file_name'] ?? 'Unknown file',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text('Submitted by: ', style: TextStyle(color: Colors.grey)),
                                              submission['submitted_by'] != null
                                                ? _buildUserNameWidget(submission['submitted_by']['full_name'])
                                                : const Text('Unknown', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text('Date: ', style: TextStyle(color: Colors.grey)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _formatDate(submission['submission_date']),
                                                  style: TextStyle(
                                                    color: Colors.blue.shade800,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (submission['comment'] != null && submission['comment'].isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Comment:',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    submission['comment'],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.open_in_new, size: 16),
                                                label: const Text('Open File'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => _openFile(
                                                  submission['file'],
                                                  submission['file_name'] ?? 'file',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Footer with close button
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Style user names with a nice avatar-like appearance
  Widget _buildUserNameWidget(String name) {
    // Generate a color based on the name
    final int hashCode = name.hashCode;
    final List<Color> avatarColors = [
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.amber.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
    ];

    final Color avatarColor = avatarColors[hashCode.abs() % avatarColors.length];
    final String initials = name.split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join('')
        .toUpperCase();

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: avatarColor.withAlpha(100),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Colors.grey.withAlpha(50),
                blurRadius: 0.5,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  Future<List<dynamic>> _fetchTaskSubmissions(int taskId) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/$taskId/submissions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use debugPrint instead of print
        debugPrint('Failed to load submissions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Use debugPrint instead of print
      debugPrint('Error fetching submissions: $e');
      return [];
    }
  }

  Future<void> _uploadFile(int taskId) async {
    Map<String, dynamic>? currentTask;

    // Find the current task from _tasks list
    for (var task in _tasks) {
      if (task['id'] == taskId) {
        currentTask = Map<String, dynamic>.from(task);
        break;
      }
    }

    if (currentTask == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task not found'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Pick file with withData: true to ensure we get the bytes for web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Important for web to get file bytes
      );

      if (result == null || result.files.isEmpty) {
        return; // User canceled the picker
      }

      final file = result.files.first;
      final fileName = file.name;

      // Get file bytes - should work on both web and mobile now
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read file data. Please try a different file.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show comment dialog
      String? comment = await _showCommentDialog();
      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading file...'),
              ],
            ),
          );
        },
      );

      // Prepare the request
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (mounted) Navigator.of(context).pop(); // Close loading dialog
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/$taskId/submit/'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      // Add comment if provided
      if (comment != null && comment.isNotEmpty) {
        request.fields['comment'] = comment;
      }

      // Send the request
      final response = await request.send();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 201) {
        // Success
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the task list and detail dialog
        await _fetchProjectTasks(); // Refresh the task list

        // Check if still mounted before using context
        if (!mounted) return;

        Navigator.of(context).pop(); // Close the current dialog

        // Find the updated task with fresh data
        Map<String, dynamic>? updatedTask;
        for (var task in _tasks) {
          if (task['id'] == taskId) {
            updatedTask = Map<String, dynamic>.from(task);
            break;
          }
        }

        // Show the task detail dialog with updated data
        if (updatedTask != null && mounted) {
          _showTaskDetailDialog(updatedTask);
        } else if (mounted) {
          _showTaskDetailDialog(currentTask); // Fallback to the original task data
        }
      } else {
        // Error
        final responseBody = await response.stream.bytesToString();
        debugPrint('Upload error response: $responseBody');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('File upload error: $e');

      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showCommentDialog() async {
    final commentController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment (Optional)'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Enter a comment about this file...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, commentController.text),
              child: const Text('Add Comment'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to launch a file URL with proper error handling
  Future<void> _launchFileUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);

      if (!mounted) return;

      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openFile(String fileUrl, String fileName) async {
    // Determine file type from extension
    final fileExtension = fileName.split('.').last.toLowerCase();

    // Check if this is a file type we can preview in-app
    final canPreviewInApp = _canPreviewFileType(fileExtension);

    // If we can't preview it in-app, directly open in external app
    if (!canPreviewInApp) {
      final fullUrl = 'http://127.0.0.1:8000$fileUrl';
      _launchFileUrl(fullUrl);
      return;
    }

    // For files we can preview, show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading file...'),
            ],
          ),
        );
      },
    );

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (!mounted) return;

        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
        return;
      }

      // Construct the full URL
      final fullUrl = 'http://127.0.0.1:8000$fileUrl';

      // Fetch the file content
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Show file content in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with file name and close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    // File content
                    Expanded(
                      child: _buildFileContentWidget(response.bodyBytes, fileExtension, fileName, fileUrl),
                    ),
                    // Footer with download option
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          onPressed: () {
                            _launchFileUrl(fullUrl);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        // Close loading dialog if it's still open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to determine if we can preview a file type in-app
  bool _canPreviewFileType(String fileExtension) {
    // Text files we can preview
    if (['txt', 'md', 'json', 'csv', 'html', 'xml', 'css', 'js'].contains(fileExtension)) {
      return true;
    }

    // Image files we can preview
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
      return true;
    }

    // All other file types (including Office documents and PDFs) will open in external apps
    return false;
  }

  Widget _buildFileContentWidget(Uint8List bytes, String fileExtension, String fileName, String fileUrl) {
    // For text-based files, try to display the content
    if (['txt', 'md', 'json', 'csv', 'html', 'xml', 'css', 'js'].contains(fileExtension)) {
      try {
        final text = utf8.decode(bytes);
        return SingleChildScrollView(
          child: SelectableText(text),
        );
      } catch (e) {
        debugPrint('Error decoding text file: $e');
        // Fall back to binary display
      }
    }

    // For images, display the image
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
      return Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error displaying image: $error');
            return const Center(child: Text('Unable to display image'));
          },
        ),
      );
    }

    // This function should only be called for file types we can preview in-app
    // (text files and images) as determined by _canPreviewFileType()

    // For text-based files, we already have the display logic above

    // For images, we already have the display logic above

    // If we somehow get here with a file type we can't preview, show a message
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(fileExtension),
            size: 80,
            color: _getFileColor(fileExtension),
          ),
          const SizedBox(height: 24),
          Text(
            'File type: ${fileExtension.toUpperCase()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fileName,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Preview not available for this file type.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the download button below to open this file.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.cyan;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Colors.pink;
      default:
        return Colors.grey;
    }
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
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
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
                      _buildHoverableTableRow(task),
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
