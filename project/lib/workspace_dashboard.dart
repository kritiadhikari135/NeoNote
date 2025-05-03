// import 'package:flutter/material.dart';
// import 'package:project/widgets/custom_scaffold_workspace.dart';
// import 'package:project/work_page.dart';
// // import 'package:project/dashboard.dart';

// class WorkspaceDashboardScreen extends StatefulWidget {
//   const WorkspaceDashboardScreen({super.key});

//   @override
//   _WorkspaceDashboardScreenState createState() => _WorkspaceDashboardScreenState();
// }

// class _WorkspaceDashboardScreenState extends State<WorkspaceDashboardScreen> {
//   String _selectedPage = "Home";

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffoldWorkspace(
//       selectedPage: _selectedPage,
//       onItemSelected: (page) {
//         if (page == 'Work') {
//           // Navigate to the Work page
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => const WorkPage()),
//           );
//         } else {
//           setState(() {
//             _selectedPage = page;
//           });
//         }
//       },
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Top Bar
//           Container(
//             color: const Color.fromARGB(255, 37, 93, 225),
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Spacer(), // This pushes the text to the center
//                 const Text(
//                   'Workspace Dashboard',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const Spacer(), // This ensures the text stays centered
//                 IconButton(
//                   icon: const Icon(Icons.settings, color: Colors.white),
//                   onPressed: () {
//                     // Add settings functionality here
//                   },
//                   tooltip: 'Settings',
//                 ),
//               ],
//             ),
//           ),
//           // Main Content
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Welcome to Workspace',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Collaborate with your team and manage projects efficiently.',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     // Recent Projects Section
//                     const Text(
//                       'Recent Projects',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildProjectsGrid(),
//                     const SizedBox(height: 32),
//                     // Team Members Section
//                     const Text(
//                       'Team Members',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTeamMembersList(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProjectsGrid() {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1.5,
//       ),
//       itemCount: 6,
//       itemBuilder: (context, index) {
//         return Card(
//           elevation: 2,
//           child: InkWell(
//             onTap: () {
//               // Navigate to project details
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Project ${index + 1}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Last updated: Today',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const Spacer(),
//                   const LinearProgressIndicator(
//                     value: 0.7,
//                     backgroundColor: Colors.grey,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     '70% Complete',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTeamMembersList() {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundColor: Colors.primaries[index % Colors.primaries.length],
//             child: Text(
//               'U${index + 1}',
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           title: Text('User ${index + 1}'),
//           subtitle: Text('Role ${index + 1}'),
//           trailing: IconButton(
//             icon: const Icon(Icons.message),
//             onPressed: () {
//               // Message user
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// ================================================================================================================

import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:project/work_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:project/services/local_storage.dart';
import 'package:project/project_detail_page.dart'; // Import ProjectDetailPage

class WorkspaceDashboardScreen extends StatefulWidget {
  const WorkspaceDashboardScreen({super.key});

  @override
  _WorkspaceDashboardScreenState createState() =>
      _WorkspaceDashboardScreenState();
}

class _WorkspaceDashboardScreenState extends State<WorkspaceDashboardScreen> {
  String _selectedPage = "Home";
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _overallTeamMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldWorkspace(
      selectedPage: _selectedPage,
      onItemSelected: (page) {
        if (page == 'Work') {
          // Navigate to the Work page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkPage()),
          );
        } else {
          setState(() {
            _selectedPage = page;
          });
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Container(
            color: const Color.fromARGB(255, 37, 93, 225),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // This pushes the text to the center
                const Text(
                  'Workspace Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(), // This ensures the text stays centered
                // Removed Settings Icon Button
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator( // Added RefreshIndicator
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView( // Wrap content in SingleChildScrollView
                  physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollability for RefreshIndicator
                  child: Column( // Add Column here
                  crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
                  children: [
                    const Center( // Center the Welcome text
                      child: Text(
                        'Welcome to Workspace',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center( // Center the description text
                      child: Text(
                        'Collaborate with your team and manage projects efficiently.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recent Projects Section
                    const Text(
                      'Recent Projects', // Updated title for clarity
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error.isNotEmpty)
                      Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    else if (_projects.isEmpty)
                      const Center(child: Text('No projects found.'))
                    else
                      _buildProjectsGrid(),

                    const SizedBox(height: 32),
                    // Team Members Section
                    const Text(
                      'Overall Team Members', // Updated title for clarity
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()) // Show loader here too initially
                    else if (_error.isNotEmpty)
                      Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))) // Error can affect both
                    else if (_overallTeamMembers.isEmpty)
                      const Center(child: Text('No team members found.'))
                    else
                      _buildTeamMembersList(),
                  ],
                ),
                ), // Close Column
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        // Assuming the same endpoint returns all projects for the user
        Uri.parse('http://localhost:8000/api/work/projects/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedProjects = data.map((project) => {
          'id': project['id'],
          'name': project['name'] ?? 'Unnamed Project',
          'description': project['description'] ?? '',
          'members': project['members'] ?? [],
          'is_hosted_by_user': project['is_hosted_by_user'] ?? false,
          'owner': project['owner'], // Assuming the API provides owner details
        }).toList();

        // --- Process Overall Team Members ---
        final Set<int> memberIds = {}; // Use Set for efficient uniqueness check
        final List<Map<String, dynamic>> uniqueMembers = [];

        for (var project in fetchedProjects) {
          // Add owner if exists and not already added
          if (project['owner'] != null && project['owner']['id'] != null && memberIds.add(project['owner']['id'])) {
            uniqueMembers.add(project['owner']);
          }
          // Add members if exist and not already added
          if (project['members'] is List) {
            for (var member in project['members']) {
              if (member != null && member['id'] != null && memberIds.add(member['id'])) {
                uniqueMembers.add(member);
              }
            }
          }
        }

        setState(() {
          _projects = fetchedProjects;
          _overallTeamMembers = uniqueMembers; // Store unique members
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error connecting to server: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildProjectsGrid() {
    // Display only the first 3 projects, or fewer if less than 3 exist
    final recentProjects = _projects.take(3).toList();
    const double cardAspectRatio = 1.6; // Increased aspect ratio for shorter height

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: cardAspectRatio, // Use adjusted aspect ratio
      ),
      itemCount: recentProjects.length, // Use the actual count (max 3)
      itemBuilder: (context, index) {
        final project = recentProjects[index];
        final members = (project['members'] as List<dynamic>?) ?? [];
        final owner = project['owner'] as Map<String, dynamic>?; // Get owner info if available
        final bool isHostedByUser = project['is_hosted_by_user'] == true;
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProjectDetailPage(
                    projectId: project['id'],
                    title: project['name'],
                    description: project['description'],
                    isHostedByUser: project['is_hosted_by_user'] ?? false,
                  ),
                ),
              ).then((_) => _fetchDashboardData()); // Refresh data when returning
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced padding for card content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section (similar to ProjectCard)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF255DE1).withOpacity(0.1), // Light purple-ish background
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder, // Folder Icon
                          size: 16,
                          color: Color(0xFF255DE1), // Blue color
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            project['name'] ?? 'Unnamed Project',
                            style: const TextStyle(
                              fontSize: 18, // Increased from 16 to 18
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF255DE1), // Blue color
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description Section
                  Text(
                    project['description'] ?? 'No description provided.',
                    style: TextStyle(
                      fontSize: 14, // Increased from 12 to 14
                      color: (project['description'] == null || project['description'].isEmpty)
                          ? Colors.grey[400]
                          : Colors.black87, // Darker color for better readability
                    ),
                    maxLines: 2, // Limit description lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // Add some space instead of Spacer
                  // Team Members Section (for this specific project)
                  if (members.isNotEmpty || owner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE), // Light grey color instead of using withOpacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'Team',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              // Add owner chip if exists
                              if (owner != null)
                                _buildMiniMemberChip(owner['full_name'] ?? 'Owner', isOwner: true),
                              // Add member chips
                              ...members.map((member) {
                                // Avoid duplicating owner if they are also in members list
                                if (owner != null && member['id'] == owner['id']) {
                                  return const SizedBox.shrink(); // Don't show owner twice
                                }
                                return _buildMiniMemberChip(member['full_name'] ?? 'Member');
                              }),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'No members yet',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 4), // Small spacing at the bottom
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for mini member chips within the project card
  Widget _buildMiniMemberChip(String name, {bool isOwner = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4), // Add spacing between chips
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Increased padding
      decoration: BoxDecoration(
        color: (isOwner ? Colors.orange[100] : const Color(0xFFE6EFFF)), // Light blue color instead of using withOpacity
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // 10% opacity black
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12, // Increased from 10 to 12
          color: (isOwner ? Colors.orange[800] : const Color(0xFF255DE1)),
          fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTeamMembersList() {
    // This list shows OVERALL members across all projects
    return Column(
      children: _overallTeamMembers.map((member) {
        final String fullName = member['full_name'] ?? 'Unknown User';
        final String email = member['email'] ?? 'No email';

        // Generate a color based on the name
        final int nameHash = fullName.hashCode.abs();
        final List<Color> colors = [
          const Color(0xFF3366FF), // Blue
          const Color(0xFF6C63FF), // Indigo
          const Color(0xFF8A4FFF), // Purple
          const Color(0xFFFF6B6B), // Red
          const Color(0xFFFF9F43), // Orange
          const Color(0xFF1DD1A1), // Green
          const Color(0xFF00CCFF), // Cyan
        ];
        final Color themeColor = colors[nameHash % colors.length];

        // Get initials for avatar
        final String initials = fullName.isNotEmpty
            ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
            : '?';

        // Create a modern card for each team member
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withAlpha(20),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Could add action here in the future
                  },
                  splashColor: themeColor.withAlpha(50),
                  highlightColor: themeColor.withAlpha(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar with initials
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor,
                                Color.lerp(themeColor, Colors.white, 0.3) ?? themeColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Email with icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Message icon removed as requested
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}