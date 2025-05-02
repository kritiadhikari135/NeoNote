import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/quicknotes.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/page.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:project/dashboard.dart';
import 'package:project/personalScreen/notification.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:project/personalScreen/calender.dart';
import 'package:project/workspace_dashboard.dart'; // Add this import

import 'package:project/personalScreen/goal.dart';
import 'package:project/personalScreen/tasklist.dart';
import 'package:project/personalScreen/content_page.dart';

class CustomScaffold extends StatefulWidget {
  final String selectedPage;
  final Function(String) onItemSelected;
  final Widget body;
  final FloatingActionButton? floatingActionButton;

  const CustomScaffold({
    super.key,
    required this.selectedPage,
    required this.onItemSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  _CustomScaffoldState createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> with SingleTickerProviderStateMixin {
  List<String> personalSpacePages = ['Diary',  'Goals', 'Task List'];

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              color: const Color(0xFFEFEFF4),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'NeoNote',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF255DE1),
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildSidebarItem(Icons.home, 'Home', '/dashboard'),
                    // Notification with badge count
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        final unreadCount = notificationProvider.unreadCount;
                        return _buildSidebarItem(
                          Icons.notifications,
                          'Notification',
                          NotificationPage(),
                          badgeCount: unreadCount,
                        );
                      },
                    ),
                    // Switch to Team Space button
                    _buildSidebarItem(
                      Icons.work,
                      'Switch to Team Space',
                      WorkspaceDashboardScreen(),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF255DE1).withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Personal Space',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF255DE1),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Color(0xFF255DE1)),
                                  onPressed: () => _showAddPageDialog(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              for (var page in personalSpacePages)
                                _buildSidebarItem(_getIconForPage(page), page, _getPageByName(page)),
                              Consumer<PagesProvider>(
                                builder: (context, pagesProvider, child) {
                                  final topLevelPages = pagesProvider.getTopLevelPages();
                                  return Column(
                                    children: topLevelPages.map((pageModel) {
                                      return _CustomPageItem(
                                        pageModel: pageModel,
                                        isSelected: widget.selectedPage == pageModel.title,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ContentPage(page: pageModel),
                                            ),
                                          );
                                        },
                                        onDelete: () => _showDeleteConfirmationDialog(context, pageModel),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    _buildSidebarItem(Icons.calendar_today, 'Calendar', Calenderpage()),
                    _buildSidebarItem(Icons.delete, 'Bin', BinPage()),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: widget.body,
          ),
        ],
      ),
    );
  }

 Widget _buildSidebarItem(IconData icon, String label, dynamic destination, {int badgeCount = 0}) {
  bool isSelected = widget.selectedPage == label;

  return _HoverSidebarItem(
    icon: icon,
    label: label,
    isSelected: isSelected,
    badgeCount: badgeCount,
    onTap: () {
      // Delay navigation until the current frame is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (destination is String) {
          Navigator.pushNamed(context, destination);
        } else if (destination is Widget) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      });
    },
  );
}

  dynamic _getPageByName(String pageName) {
    switch (pageName) {
      case 'Diary':
        return '/diary';
      // case 'Quick Notes':
      //   return QuickNotesPage();
      case 'Goals':
        return GoalPage();
      case 'Task List':
        return TaskScreen();
      default:
        return Container();
    }
  }

  IconData _getIconForPage(String pageName) {
    switch (pageName) {
      case 'Diary':
        return Icons.menu_book; // Book icon for diary
      case 'Goals':
        return Icons.emoji_events; // Goal/trophy icon
      case 'Task List':
        return Icons.check_circle_outline; // Task icon
      default:
        return Icons.description; // Default page icon
    }
  }

  void _showAddPageDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Page'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter page title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  // Create a top-level page (no parentId)
                  Provider.of<PagesProvider>(context, listen: false)
                      .createPage(controller.text, "", parentId: null)
                      .then((newPage) {
                    Navigator.of(dialogContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ContentPage(page: newPage)),
                    );
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }



  void _showDeleteConfirmationDialog(BuildContext context, PageModel pageModel) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Close the dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
  onPressed: () {
    // Add the page to the bin
    Provider.of<BinProvider>(context, listen: false).addDeletedPage(pageModel);

    // Delete the page from the provider
    Provider.of<PagesProvider>(context, listen: false).deletePage(pageModel.id);

    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page moved to bin')),
    );

    // Close the current page (ContentPage)
    Navigator.of(dialogContext).pop(); // Close the dialog

    // Go back to Dashboard with a delay to prevent concurrent navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()), // Navigate to Dashboard
      );
    });
  },
  child: const Text('Delete'),
)

        ],
      );
    },
  );
}

}

/// A custom sidebar item with enhanced hover effects
class _HoverSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final int badgeCount;

  const _HoverSidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.badgeCount = 0,
  });

  @override
  _HoverSidebarItemState createState() => _HoverSidebarItemState();
}

class _HoverSidebarItemState extends State<_HoverSidebarItem> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _getShadow(),
              border: _getBorder(),
            ),
            transform: Matrix4.translationValues(0, _translateAnimation.value, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.transparent,
                splashColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                highlightColor: const Color(0xFFE3F2FD).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Icon with scale animation
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          widget.icon,
                          color: _getIconColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text with scale animation
                      Expanded(
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: widget.isSelected ? 0.3 : 0,
                              shadows: _isHovering || widget.isSelected ? [
                                Shadow(
                                  color: const Color(0xFF255DE1).withOpacity(0.3),
                                  blurRadius: 2.0,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                      if (widget.badgeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return const Color(0xFFE3F2FD); // Light blue for selected item
    } else if (_isHovering) {
      return const Color(0xFFF5F5F5); // Light gray for hover
    } else {
      return Colors.transparent;
    }
  }

  Color _getIconColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1); // Blue for selected item
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8); // Slightly transparent blue for hover
    } else {
      return Colors.black54; // Default color
    }
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1); // Blue for selected item
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8); // Slightly transparent blue for hover
    } else {
      return Colors.black87; // Default color
    }
  }

  List<BoxShadow>? _getShadow() {
    if (widget.isSelected || _isHovering) {
      return [
        BoxShadow(
          color: const Color(0xFF255DE1).withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Border? _getBorder() {
    if (widget.isSelected) {
      return Border(
        left: BorderSide(
          color: const Color(0xFF255DE1),
          width: 3,
        ),
      );
    }
    return null;
  }
}

/// A custom sidebar item for user-created pages with enhanced hover effects
class _CustomPageItem extends StatefulWidget {
  final PageModel pageModel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;

  const _CustomPageItem({
    required this.pageModel,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  _CustomPageItemState createState() => _CustomPageItemState();
}

class _CustomPageItemState extends State<_CustomPageItem> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _getShadow(),
              border: _getBorder(),
            ),
            transform: Matrix4.translationValues(0, _translateAnimation.value, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.transparent,
                splashColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                highlightColor: const Color(0xFFE3F2FD).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Icon with scale animation
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          Icons.description,
                          color: _getIconColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text with scale animation
                      Expanded(
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.pageModel.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: widget.isSelected ? 0.3 : 0,
                              shadows: _isHovering || widget.isSelected ? [
                                Shadow(
                                  color: const Color(0xFF255DE1).withOpacity(0.3),
                                  blurRadius: 2.0,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: _isHovering ? Colors.red : Colors.red.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: widget.onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return const Color(0xFFE3F2FD); // Light blue for selected item
    } else if (_isHovering) {
      return const Color(0xFFF5F5F5); // Light gray for hover
    } else {
      return Colors.transparent;
    }
  }

  Color _getIconColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1); // Blue for selected item
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8); // Slightly transparent blue for hover
    } else {
      return Colors.black54; // Default color
    }
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1); // Blue for selected item
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8); // Slightly transparent blue for hover
    } else {
      return Colors.black87; // Default color
    }
  }

  List<BoxShadow>? _getShadow() {
    if (widget.isSelected || _isHovering) {
      return [
        BoxShadow(
          color: const Color(0xFF255DE1).withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Border? _getBorder() {
    if (widget.isSelected) {
      return Border(
        left: BorderSide(
          color: const Color(0xFF255DE1),
          width: 3,
        ),
      );
    }
    return null;
  }
}