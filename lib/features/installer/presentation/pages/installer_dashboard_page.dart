import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import 'dart:async';

class InstallerDashboardPage extends StatefulWidget {
  const InstallerDashboardPage({super.key});

  @override
  State<InstallerDashboardPage> createState() => _InstallerDashboardPageState();
}

class _InstallerDashboardPageState extends State<InstallerDashboardPage> {
  bool _isSidebarExpanded = false;
  List<Map<String, dynamic>> _issues = [];
  bool _isLoadingIssues = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      await BackgroundLocationService.start();
    } catch (e) {
      debugPrint('Background location start error: $e');
    }
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoadingIssues = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/api/installer/issues');

      if (mounted) {
        setState(() {
          _issues = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
          _isLoadingIssues = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading issues: $e');
      if (mounted) {
        setState(() => _isLoadingIssues = false);
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String installerName = 'Installer';
        if (state is AuthAuthenticated) {
          installerName = state.user.name;
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF4C1D95), const Color(0xFF2E1065)]
                        : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(isDark),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              )
                            ],
                          ),
                          child: _buildDashboardContent(installerName, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildSidebar(installerName, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              onPressed: _toggleSidebar,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Installer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          const ThemeToggleButton(),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(String installerName, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadIssues();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              installerName,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            Text('Installation Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937), letterSpacing: -0.5)),
            const SizedBox(height: 16),

            _isLoadingIssues
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : _issues.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 64, color: isDark ? Colors.white38 : Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No pending installation tasks', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _issues.map((i) => _buildIssueCard(i, isDark)).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task #${issue['ticketNumber'] ?? issue['id']?.substring(0, 8) ?? 'Unknown'}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6), letterSpacing: -0.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue['address'] ?? 'No address provided',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['customerName'] ?? 'Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue['description'] ?? issue['issueDescription'] ?? 'No description',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (issue['images'] != null && (issue['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (issue['images'] as List).length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(issue['images'][index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Installation completion tapped')));
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Mark Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(String installerName, bool isDark) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarExpanded ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.construction, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            installerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Installer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleSidebar,
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSidebarItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        _toggleSidebar();
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
              _buildSidebarItem(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                isDestructive: true,
                onTap: () {
                  _toggleSidebar();
                  context.read<AuthBloc>().add(LogoutEvent());
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red[300] : Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: isDestructive ? Colors.red[300] : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
