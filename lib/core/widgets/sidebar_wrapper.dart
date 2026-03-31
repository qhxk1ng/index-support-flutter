import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class SidebarWrapper extends StatefulWidget {
  final UserEntity? user;
  final Color primaryColor;
  final Color secondaryColor;
  final List<SidebarMenuItem> menuItems;
  final Widget child;

  const SidebarWrapper({
    super.key,
    required this.user,
    required this.primaryColor,
    required this.secondaryColor,
    required this.menuItems,
    required this.child,
  });

  @override
  State<SidebarWrapper> createState() => SidebarWrapperState();
}

class SidebarWrapperState extends State<SidebarWrapper> with SingleTickerProviderStateMixin {
  bool _isSidebarExpanded = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void closeSidebar() {
    if (_isSidebarExpanded) {
      setState(() {
        _isSidebarExpanded = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        widget.child,
        
        // Overlay when sidebar is open
        if (_isSidebarExpanded)
          GestureDetector(
            onTap: closeSidebar,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSidebarExpanded ? 1.0 : 0.0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        
        // Animated Sidebar
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppSidebar(
              user: widget.user,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              menuItems: widget.menuItems,
              onClose: closeSidebar,
            ),
          ),
        ),
      ],
    );
  }
}
