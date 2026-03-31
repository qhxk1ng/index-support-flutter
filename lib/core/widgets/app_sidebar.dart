import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class AppSidebar extends StatelessWidget {
  final UserEntity? user;
  final Color primaryColor;
  final Color secondaryColor;
  final List<SidebarMenuItem> menuItems;
  final VoidCallback onClose;

  const AppSidebar({
    super.key,
    required this.user,
    required this.primaryColor,
    required this.secondaryColor,
    required this.menuItems,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile Section
              _buildProfileSection(context),
              
              const Divider(color: Colors.white24, height: 1, thickness: 1),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...menuItems.map((item) => _buildMenuItem(context, item)),
                    
                    const Divider(color: Colors.white24, height: 32, thickness: 1),
                    
                    // Account Settings
                    _buildMenuItem(
                      context,
                      SidebarMenuItem(
                        icon: Icons.settings_rounded,
                        title: 'Account Settings',
                        onTap: () {
                          onClose();
                          _showAccountSettings(context);
                        },
                      ),
                    ),
                    
                    // Help
                    _buildMenuItem(
                      context,
                      SidebarMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          onClose();
                          _showHelp(context);
                        },
                      ),
                    ),
                    
                    // Logout
                    _buildMenuItem(
                      context,
                      SidebarMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        isDestructive: true,
                        onTap: () {
                          _handleLogout(context);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Hero(
            tag: 'user_avatar_${user?.id ?? 'guest'}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            user?.name ?? 'Guest User',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            user?.email ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Role Badge
          if (user?.activeRole != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                _formatRole(user!.activeRole),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SidebarMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: item.isDestructive
                    ? Colors.red[300]
                    : Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: item.isDestructive
                        ? Colors.red[300]
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (item.trailing != null) item.trailing!,
            ],
          ),
        ),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'CUSTOMER':
        return 'Customer';
      case 'INSTALLER':
        return 'Installer';
      case 'FIELD_PERSONNEL':
        return 'Field Personnel';
      case 'SALES_PERSONNEL':
        return 'Sales Personnel';
      default:
        return role;
    }
  }

  void _showAccountSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AccountSettingsSheet(user: user),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HelpSheet(),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class SidebarMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });
}

// Account Settings Sheet
class _AccountSettingsSheet extends StatelessWidget {
  final UserEntity? user;

  const _AccountSettingsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_rounded, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Profile Info
              _buildSettingItem(
                icon: Icons.person_outline,
                title: 'Name',
                value: user?.name ?? 'Not set',
              ),
              _buildSettingItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: user?.email ?? 'Not set',
              ),
              _buildSettingItem(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: user?.phoneNumber ?? 'Not set',
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Help Sheet
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildHelpItem(
                icon: Icons.phone_outlined,
                title: 'Call Support',
                subtitle: '+91 1800-XXX-XXXX',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening dialer...')),
                  );
                },
              ),
              
              _buildHelpItem(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@indexinformatics.in',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email...')),
                  );
                },
              ),
              
              _buildHelpItem(
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live chat coming soon!')),
                  );
                },
              ),
              
              _buildHelpItem(
                icon: Icons.article_outlined,
                title: 'FAQs',
                subtitle: 'Frequently asked questions',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQs coming soon!')),
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
