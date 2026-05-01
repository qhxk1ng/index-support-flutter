import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'active_tickets_page.dart';
import 'find_users_page.dart';
import 'field_technicians_page.dart';
import 'installers_page.dart';
import 'live_tracking_overview_page.dart';
import 'field_staff_sales_page.dart';
import 'technician_rankings_page.dart';
import 'warranty_approvals_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()..add(GetDashboardStatsEvent()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView();

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> with TickerProviderStateMixin {
  bool _isSidebarExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF7F1D1D), const Color(0xFF450A0A)]
                    : [const Color(0xFFDC2626), const Color(0xFF991B1B)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                      child: BlocBuilder<AdminBloc, AdminState>(
                        builder: (context, state) {
                          if (state is AdminLoading) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
                          }

                          if (state is AdminError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFDC2626)),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<AdminBloc>().add(GetDashboardStatsEvent());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state is DashboardStatsLoaded) {
                            return _buildDashboardContent(state.stats, isDark);
                          }

                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildSidebar(isDark),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Center',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                'Manage your system',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
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

  Widget _buildDashboardContent(DashboardStatsEntity stats, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildStatsGrid(stats, isDark),
              const SizedBox(height: 36),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildQuickActions(stats, isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStatsEntity stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildStatCard('Total Customers', stats.totalCustomers.toString(), Icons.people_alt_rounded, const Color(0xFFDC2626), 0, isDark),
        _buildStatCard('Total Complaints', stats.totalComplaints.toString(), Icons.report_gmailerrorred_rounded, const Color(0xFFEF4444), 1, isDark),
        _buildStatCard('Completed', stats.completedComplaints.toString(), Icons.check_circle_rounded, const Color(0xFF10B981), 2, isDark),
        _buildStatCard('Warranties', stats.totalWarranties.toString(), Icons.verified_rounded, const Color(0xFFF59E0B), 3, isDark),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, int index, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isDark ? 0.1 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(DashboardStatsEntity stats, bool isDark) {
    return Column(
      children: [
        _buildActionCard('Warranty Approvals', 'Review pending warranties', Icons.pending_actions_rounded, const Color(0xFFDC2626), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WarrantyApprovalsPage()));
        }, 0, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Active Tickets', '${stats.totalComplaints - stats.completedComplaints} active', Icons.confirmation_number_rounded, const Color(0xFFEF4444), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTicketsPage()));
        }, 1, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Find Users', 'Search and manage customers', Icons.person_search_rounded, const Color(0xFFF59E0B), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FindUsersPage()));
        }, 2, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Field Technicians', '${stats.totalFieldPersonnel} personnel', Icons.engineering_rounded, const Color(0xFF10B981), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldTechniciansPage()));
        }, 3, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Installers', '${stats.totalInstallers} installers', Icons.build_circle_rounded, const Color(0xFF3B82F6), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallersPage()));
        }, 4, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Field Staff & Sales', 'Field personnel & sales team', Icons.people_alt_rounded, const Color(0xFF0EA5E9), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldStaffSalesPage()));
        }, 5, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Technician Rankings', 'Performance leaderboard', Icons.emoji_events_rounded, const Color(0xFFF59E0B), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianRankingsPage()));
        }, 6, isDark),
        const SizedBox(height: 16),
        _buildActionCard('Live Tracking', 'View all staff on map', Icons.map_rounded, const Color(0xFF6366F1), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveTrackingOverviewPage()));
        }, 7, isDark),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, int index, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.white,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isDark ? 0.05 : 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : Colors.grey[500],
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.arrow_forward_rounded, size: 20, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(bool isDark) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarExpanded ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                                ),
                                Text(
                                  'System Manager',
                                  style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: _toggleSidebar,
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), thickness: 1, height: 1),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          _buildSidebarItem(icon: Icons.dashboard_rounded, title: 'Dashboard', onTap: _toggleSidebar),
                          _buildSidebarItem(icon: Icons.settings_rounded, title: 'Settings', onTap: _toggleSidebar),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), thickness: 1, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSidebarItem(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        isDestructive: true,
                        onTap: () {
                          _toggleSidebar();
                          context.read<AuthBloc>().add(LogoutEvent());
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSidebarExpanded)
            Positioned(
              left: 300,
              top: 0,
              bottom: 0,
              right: -MediaQuery.of(context).size.width,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? const Color(0xFFEF4444) : Colors.white70, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? const Color(0xFFEF4444) : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
