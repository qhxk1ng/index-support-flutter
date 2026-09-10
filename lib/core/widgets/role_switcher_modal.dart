import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class RoleSwitcherModal {
  static void show(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final roles = user.roles;
        final currentActiveRole = user.activeRole ?? UserRole.customer;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Switch Active Role',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Currently operating as ${_formatRoleName(currentActiveRole)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 16),

              // Role Cards List
              ...roles.map((role) {
                final isActive = (role.toUpperCase() == currentActiveRole.toUpperCase());
                final roleMeta = _getRoleMetadata(role);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: isActive
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            context.read<AuthBloc>().add(SwitchRoleEvent(role: role));
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? roleMeta.color.withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? roleMeta.color : Colors.grey.shade200,
                          width: isActive ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: roleMeta.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              roleMeta.icon,
                              color: roleMeta.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roleMeta.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  roleMeta.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleMeta.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your warranties and profile data are shared across roles.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatRoleName(String role) {
    return role.replaceAll('_', ' ').split(' ').map((s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }).join(' ');
  }

  static _RoleMeta _getRoleMetadata(String role) {
    switch (role.toUpperCase()) {
      case UserRole.customer:
        return _RoleMeta(
          title: 'Customer',
          description: 'Register warranties & raise support complaints',
          icon: Icons.person_rounded,
          color: const Color(0xFF0284C7),
        );
      case UserRole.fieldPersonnel:
        return _RoleMeta(
          title: 'Field Personnel',
          description: 'On-site service visits & complaint resolution',
          icon: Icons.engineering_rounded,
          color: const Color(0xFF0284C7),
        );
      case UserRole.salesPersonnel:
        return _RoleMeta(
          title: 'Sales Personnel',
          description: 'Manage sales leads, travel routes & expenses',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        );
      case UserRole.installer:
        return _RoleMeta(
          title: 'Installer',
          description: 'Installation registration & device commissioning',
          icon: Icons.build_circle_outlined,
          color: const Color(0xFFF59E0B),
        );
      case UserRole.admin:
        return _RoleMeta(
          title: 'Admin',
          description: 'System administration & management portal',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF6366F1),
        );
      default:
        return _RoleMeta(
          title: _formatRoleName(role),
          description: 'Application role',
          icon: Icons.badge_outlined,
          color: AppColors.primary,
        );
    }
  }
}

class _RoleMeta {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _RoleMeta({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
