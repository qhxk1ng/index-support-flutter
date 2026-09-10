import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class RoleUpgradePage extends StatefulWidget {
  const RoleUpgradePage({super.key});

  @override
  State<RoleUpgradePage> createState() => _RoleUpgradePageState();
}

class _RoleUpgradePageState extends State<RoleUpgradePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedRole = UserRole.fieldPersonnel;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myRequests = [];
  bool _isLoadingRequests = true;

  final List<Map<String, dynamic>> _availableRoles = [
    {
      'role': UserRole.fieldPersonnel,
      'title': 'Field Personnel',
      'subtitle': 'Perform on-site customer visits, manage assigned service complaints & travel tracking.',
      'icon': Icons.engineering_rounded,
      'color': const Color(0xFF0284C7),
    },
    {
      'role': UserRole.salesPersonnel,
      'title': 'Sales Personnel',
      'subtitle': 'Manage customer sales leads, client visits, travel routes & business expenses.',
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'role': UserRole.installer,
      'title': 'Installer',
      'subtitle': 'Register customer installations, bind inverters & verify equipment warranties.',
      'icon': Icons.build_circle_outlined,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _fetchMyRequests() {
    context.read<AuthBloc>().add(GetMyRoleUpgradeRequestsEvent());
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.roles.contains(_selectedRole)) {
        AppSnackbar.showError(context, 'You already have the ${_formatRoleName(_selectedRole)} role.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    context.read<AuthBloc>().add(
          RequestRoleUpgradeEvent(
            requestedRole: _selectedRole,
            reason: _reasonController.text.trim(),
          ),
        );
  }

  String _formatRoleName(String role) {
    return role.replaceAll('_', ' ').split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Account Upgrade'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RoleUpgradeRequested) {
            setState(() {
              _isSubmitting = false;
              _reasonController.clear();
            });
            AppSnackbar.showSuccess(context, state.message);
            _fetchMyRequests();
          } else if (state is RoleUpgradeRequestsLoaded) {
            setState(() {
              _myRequests = state.requests;
              _isLoadingRequests = false;
            });
          } else if (state is AuthActionError) {
            final wasSubmitting = _isSubmitting;
            setState(() {
              _isSubmitting = false;
              _isLoadingRequests = false;
            });
            if (wasSubmitting) {
              AppSnackbar.showError(context, state.message);
            }
          } else if (state is AuthError) {
            final wasSubmitting = _isSubmitting;
            setState(() {
              _isSubmitting = false;
              _isLoadingRequests = false;
            });
            if (wasSubmitting) {
              AppSnackbar.showError(context, state.message);
            }
          }
        },
        builder: (context, state) {
          UserEntity? user;
          if (state is AuthAuthenticated) {
            user = state.user;
          }

          final existingRoles = user?.roles ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Request Role Upgrade',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Apply to upgrade your account to Field Personnel or Sales Personnel. '
                        'Once approved by administrators at admin.indexinformatics.in, you can seamlessly switch between roles.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          const Text(
                            'Your Current Roles: ',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          ...existingRoles.map(
                            (r) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                _formatRoleName(r),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Upgrade Form ─────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Desired Role',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._availableRoles.map((roleInfo) {
                        final role = roleInfo['role'] as String;
                        final isAlreadyOwned = existingRoles.contains(role);
                        final isSelected = _selectedRole == role;
                        final color = roleInfo['color'] as Color;

                        return GestureDetector(
                          onTap: isAlreadyOwned
                              ? null
                              : () => setState(() => _selectedRole = role),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : (isAlreadyOwned ? Colors.grey.shade200 : Colors.grey.shade300),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    roleInfo['icon'] as IconData,
                                    color: color,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            roleInfo['title'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isAlreadyOwned ? Colors.grey.shade500 : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (isAlreadyOwned) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Already Active',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        roleInfo['subtitle'] as String,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isAlreadyOwned)
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    color: isSelected ? color : Colors.grey.shade400,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      // Reason Text Field
                      const Text(
                        'Reason for Upgrade Request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe your role, territory, or reason for requesting this upgrade...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please provide a brief reason for the request';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Upgrade Request',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── My Requests History ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Upgrade Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _fetchMyRequests,
                      tooltip: 'Refresh Status',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_isLoadingRequests)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_myRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        'No upgrade requests submitted yet.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ..._myRequests.map((req) {
                    final status = req['status']?.toString() ?? 'PENDING';
                    final roleReq = req['requestedRole']?.toString() ?? '';
                    final reason = req['reason']?.toString() ?? '';
                    final adminNote = req['adminNote']?.toString() ?? '';
                    final createdAt = req['createdAt']?.toString() ?? '';
                    final statusColor = _getStatusColor(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatRoleName(roleReq),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: $reason',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                          if (adminNote.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Admin Note: $adminNote',
                                      style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
