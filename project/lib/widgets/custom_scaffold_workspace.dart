import 'package:flutter/material.dart';
import 'package:project/workspace_dashboard.dart';
import 'package:project/work_page.dart';
import 'package:project/invitation_inbox_page.dart';
import 'package:project/dashboard.dart';

class CustomScaffoldWorkspace extends StatefulWidget {
  final Widget body;
  final String selectedPage;
  final Function(String) onItemSelected;

  const CustomScaffoldWorkspace({
    Key? key,
    required this.body,
    required this.selectedPage,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<CustomScaffoldWorkspace> createState() => _CustomScaffoldWorkspaceState();
}

class _CustomScaffoldWorkspaceState extends State<CustomScaffoldWorkspace> {
  bool _isPersonalSpaceHovered = false;

  Widget _buildNavItem(BuildContext context, String title, IconData icon, {bool isSelected = false}) {
    return _HoverSidebarItem(
      icon: icon,
      label: title,
      isSelected: isSelected,
      onTap: () {
        if (title == 'Home') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkspaceDashboardScreen()),
          );
        } else if (title == 'Work') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkPage()),
          );
        } else if (title == 'Inbox') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const InvitationInboxPage()),
          );
        }
        widget.onItemSelected(title);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'NeoNote',
                    style: TextStyle(
                      color: Color(0xFF255DE1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                _buildNavItem(context, 'Home', Icons.home, isSelected: widget.selectedPage == 'Home'),
                _HoverSidebarItem(
                  icon: Icons.person,
                  label: 'Switch to Personal Space',
                  isSelected: false,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildNavItem(context, 'Work', Icons.work, isSelected: widget.selectedPage == 'Work'),
                _buildNavItem(context, 'Inbox', Icons.inbox, isSelected: widget.selectedPage == 'Inbox'),
              ],
            ),
          ),
          Expanded(
            child: widget.body,
          ),
        ],
      ),
    );
  }
}

class _HoverSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _HoverSidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
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
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          widget.icon,
                          color: _getIconColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
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
      return const Color(0xFFE3F2FD);
    } else if (_isHovering) {
      return const Color(0xFFF5F5F5);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIconColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1);
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8);
    } else {
      return const Color(0xFF2D2D2D);
    }
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1);
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8);
    } else {
      return const Color(0xFF2D2D2D);
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
