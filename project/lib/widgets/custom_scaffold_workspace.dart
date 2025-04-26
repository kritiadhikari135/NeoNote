import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';

class CustomScaffoldWorkspace extends StatefulWidget {
  final String selectedPage;
  final Function(String) onItemSelected;
  final Widget body;

  const CustomScaffoldWorkspace({
    super.key,
    required this.selectedPage,
    required this.onItemSelected,
    required this.body,
  });

  @override
  CustomScaffoldWorkspaceState createState() => CustomScaffoldWorkspaceState();
}

class CustomScaffoldWorkspaceState extends State<CustomScaffoldWorkspace> {
  List<String> workspacePages = ['Work', 'Goals', 'Task List'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFEFEFF4),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: const Text(
                        'NeoNote',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 37, 93, 225),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Main Navigation
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.home, 'Home', context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.inbox, 'Inbox', context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.person, 'Switch to Personal', context, isDashboardSwitch: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.chat, 'Chat', context),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // WorkSpace Section Header
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Workspace',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 37, 93, 225),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Color.fromARGB(255, 37, 93, 225)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showAddWorkspaceDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Display workspace pages
                    for (var page in workspacePages)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: _buildSidebarItem(
                          page == 'Work' ? Icons.work :
                          page == 'Goals' ? Icons.flag :
                          Icons.task_alt,
                          page,
                          context
                        ),
                      ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Utilities
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.calendar_today, 'Calendar', context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.file_copy, 'Templates', context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: _buildSidebarItem(Icons.delete, 'Bin', context),
                    ),

                    const SizedBox(height: 24),

                    // Invite Members Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show a simple snackbar message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invitation feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.group),
                        label: const Text('Invite Members'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            flex: 4,
            child: widget.body,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, BuildContext context, {bool isDashboardSwitch = false}) {
    final isSelected = widget.selectedPage == label;
    const primaryColor = Color.fromARGB(255, 37, 93, 225);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.black54,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryColor : Colors.black87,
        ),
      ),
      onTap: () {
        if (isDashboardSwitch) {
          // Navigate to the personal dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          widget.onItemSelected(label); // Notify the parent about the selection
        }
      },
      selected: isSelected,
      selectedTileColor: primaryColor.withAlpha(25),
    );
  }

  // Add a new workspace item
  void addWorkspaceItem(String itemName) {
    if (itemName.isNotEmpty && !workspacePages.contains(itemName)) {
      setState(() {
        workspacePages.add(itemName);
      });
    }
  }

  // Show dialog to add a new workspace item
  void _showAddWorkspaceDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Workspace Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter item name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  addWorkspaceItem(controller.text);
                }
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
