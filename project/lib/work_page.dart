


import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:project/workspace_dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';
import 'package:project/project_detail_page.dart';

class WorkPage extends StatefulWidget {
  const WorkPage({Key? key}) : super(key: key);

  @override
  _WorkPageState createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;
  bool _isLeavingProject = false; // To manage loading state for leaving
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        isLoading = true;
        error = '';
      });

      final token = await LocalStorage.getToken();
      if (token == null) {
        if (!mounted) return; // Check again before calling setState
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/work/projects/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          if (!mounted) return; // Check again before calling setState
          setState(() {
            projects = data.map((project) => {
              'id': project['id'],
              'name': project['name'],
              'description': project['description'],
              'members': project['members'] ?? [],
              'is_hosted_by_user': project['is_hosted_by_user'] ?? false,
              'owner': project['owner'], // Assuming the API provides owner details
            }).toList();
            isLoading = false;
          });
        } catch (e) {
          if (!mounted) return; // Check again before calling setState
          setState(() {
            error = 'Error parsing response: ${e.toString()}';
            isLoading = false;
          });
        }
      } else {
        if (!mounted) return; // Check again before calling setState
        setState(() {
          error = 'Failed to load projects: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check again before calling setState
      setState(() {
        error = 'Error connecting to server: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> createProject() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/work/projects/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': projectNameController.text,
          'description': descriptionController.text,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProjects();
        projectNameController.clear();
        descriptionController.clear();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Failed to create project';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Failed to create project: ${response.statusCode}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D3D3D),
        title: const Text(
          'Create New Project',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: createProject,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    projectNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _leaveProject(BuildContext context, int projectId) async {
    // Prevent multiple leave attempts
    if (_isLeavingProject) return;

    setState(() {
      _isLeavingProject = true;
    });

    // Use a context that is guaranteed to be valid for the dialog
    final BuildContext dialogContext = this.context;

    // Show loading dialog
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Color(0xFF3D3D3D),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Leaving project...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        Navigator.pop(dialogContext); // Close loading dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/work/projects/$projectId/leave/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      Navigator.pop(dialogContext); // Close loading dialog

      if (mounted) { // Check if widget is still mounted before showing snackbar/updating state
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully left the project'), backgroundColor: Colors.green),
          );
          // Refresh projects list to reflect the change
          await fetchProjects();
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? 'Failed to leave project: ${response.statusCode}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // Ensure loading dialog is closed on error
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }
      if (mounted) { // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Ensure the loading state is reset even if the widget was unmounted
      if (mounted) {
        setState(() {
          _isLeavingProject = false;
        });
      } else {
         _isLeavingProject = false; // Reset directly if not mounted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldWorkspace(
      selectedPage: 'Work',
      onItemSelected: (String page) {
        if (page == 'Home') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WorkspaceDashboardScreen(),
            ),
          );
        }
      },
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Color(0xFF255DE1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'Work',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Projects',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: fetchProjects,
                      tooltip: 'Refresh Projects',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hosted Projects Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: const Text(
                        'Hosted Projects',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (error.isNotEmpty)
                      Center(
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (projects.where((project) => project['is_hosted_by_user'] == true).isEmpty)
                      const Center(
                        child: Text(
                          'No hosted projects yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 2.0, // Reduced aspect ratio for smaller height
                        ),
                        itemCount: projects.where((project) => project['is_hosted_by_user'] == true).length,
                        itemBuilder: (context, index) {
                          final project = projects.where((project) => project['is_hosted_by_user'] == true).toList()[index];
                          return ProjectCard(
                            project: project,
                            fetchProjects: fetchProjects,
                            onLeaveProject: (id) => _leaveProject(context, id), // Pass the leave function
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                    // Member Projects Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: const Text(
                        'You Are a Member',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (error.isNotEmpty)
                      Center(
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (projects.where((project) => project['is_hosted_by_user'] == false).isEmpty)
                      const Center(
                        child: Text(
                          'No team member projects yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 2.0, // Reduced aspect ratio for smaller height
                        ),
                        itemCount: projects.where((project) => project['is_hosted_by_user'] == false).length,
                        itemBuilder: (context, index) {
                          final project = projects.where((project) => project['is_hosted_by_user'] == false).toList()[index];
                          return ProjectCard(
                            project: project,
                            fetchProjects: fetchProjects,
                            onLeaveProject: (id) => _leaveProject(context, id), // Pass the leave function
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final Future<void> Function() fetchProjects; // Callback to refresh projects
  final Future<void> Function(int projectId) onLeaveProject; // Callback for leaving

  const ProjectCard({
    Key? key,
    required this.project,
    required this.fetchProjects,
    required this.onLeaveProject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final members = (project['members'] as List<dynamic>?) ?? [];
    final bool isHostedByUser = project['is_hosted_by_user'] == true; // Explicit check for clarity
    final owner = project['owner'] as Map<String, dynamic>?; // Get owner info if available

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(
              title: project['name'],
              description: project['description'],
              projectId: project['id'],
              isHostedByUser: isHostedByUser, // Pass the boolean
            ),
          ),
        ).then((_) => fetchProjects()); // Refresh projects when returning from detail page
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF255DE1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder,
                    size: 16,
                    color: Color(0xFF255DE1),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF255DE1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isHostedByUser) // Show leave button only if NOT hosted by user
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 18),
                      tooltip: 'Leave Project',
                      onPressed: () => _showLeaveConfirmationDialog(context, project['id'], onLeaveProject),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              project['description'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Display Host Info if hosted by user and owner info is available
            if (isHostedByUser && owner != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Host: ${owner['full_name'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            if (members.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: members.map((member) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF255DE1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF255DE1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmationDialog(BuildContext context, int projectId, Future<void> Function(int projectId) leaveAction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D3D3D),
          title: const Text(
            'Leave Project',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to leave this project?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // First close the dialog
                Navigator.pop(context);
                // Then leave the project
                await leaveAction(projectId); // Call the passed function
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}