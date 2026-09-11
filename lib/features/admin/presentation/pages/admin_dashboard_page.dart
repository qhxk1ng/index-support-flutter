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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = 'ALL';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'ALL', 'label': 'All Actions', 'icon': Icons.grid_view_rounded},
    {'id': 'TICKETS', 'label': 'Active Tickets', 'icon': Icons.confirmation_number_rounded},
    {'id': 'WARRANTY', 'label': 'Warranties', 'icon': Icons.pending_actions_rounded},
    {'id': 'USERS', 'label': 'Users & Customers', 'icon': Icons.person_search_rounded},
    {'id': 'TECHNICIANS', 'label': 'Technicians', 'icon': Icons.engineering_rounded},
    {'id': 'INSTALLERS', 'label': 'Installers', 'icon': Icons.build_circle_rounded},
    {'id': 'FIELD_SALES', 'label': 'Field & Sales', 'icon': Icons.people_alt_rounded},
    {'id': 'RANKINGS', 'label': 'Rankings', 'icon': Icons.emoji_events_rounded},
    {'id': 'TRACKING', 'label': 'Live Tracking', 'icon': Icons.map_rounded},
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildAdminDrawer(context, isDark),
      body: Container(
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  Scaffold.of(ctx).openDrawer();
                },
                tooltip: 'Navigation Menu',
              ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${_getFilteredActionsCount()} options',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildScrollableCategoryTabs(isDark),
              const SizedBox(height: 20),
              _buildQuickActions(stats, isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  int _getFilteredActionsCount() {
    if (_selectedCategory == 'ALL') return 8;
    return 1;
  }

  Widget _buildScrollableCategoryTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          final id = cat['id'] as String;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = id;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
                        color: color.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
    final List<Widget> actionCards = [];

    void addCard(String category, Widget card) {
      if (_selectedCategory == 'ALL' || _selectedCategory == category) {
        if (actionCards.isNotEmpty) {
          actionCards.add(const SizedBox(height: 16));
        }
        actionCards.add(card);
      }
    }

    addCard(
      'WARRANTY',
      _buildActionCard(
        'Warranty Approvals',
        'Review pending warranties',
        Icons.pending_actions_rounded,
        const Color(0xFFDC2626),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarrantyApprovalsPage())),
        0,
        isDark,
      ),
    );

    addCard(
      'TICKETS',
      _buildActionCard(
        'Active Tickets',
        '${stats.totalComplaints - stats.completedComplaints} active',
        Icons.confirmation_number_rounded,
        const Color(0xFFEF4444),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTicketsPage())),
        1,
        isDark,
      ),
    );

    addCard(
      'USERS',
      _buildActionCard(
        'Find Users',
        'Search and manage customers',
        Icons.person_search_rounded,
        const Color(0xFFF59E0B),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindUsersPage())),
        2,
        isDark,
      ),
    );

    addCard(
      'TECHNICIANS',
      _buildActionCard(
        'Field Technicians',
        '${stats.totalFieldPersonnel} personnel',
        Icons.engineering_rounded,
        const Color(0xFF10B981),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldTechniciansPage())),
        3,
        isDark,
      ),
    );

    addCard(
      'INSTALLERS',
      _buildActionCard(
        'Installers',
        '${stats.totalInstallers} installers',
        Icons.build_circle_rounded,
        const Color(0xFF3B82F6),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallersPage())),
        4,
        isDark,
      ),
    );

    addCard(
      'FIELD_SALES',
      _buildActionCard(
        'Field Staff & Sales',
        'Field personnel & sales team',
        Icons.people_alt_rounded,
        const Color(0xFF0EA5E9),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldStaffSalesPage())),
        5,
        isDark,
      ),
    );

    addCard(
      'RANKINGS',
      _buildActionCard(
        'Technician Rankings',
        'Performance leaderboard',
        Icons.emoji_events_rounded,
        const Color(0xFFF59E0B),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianRankingsPage())),
        6,
        isDark,
      ),
    );

    addCard(
      'TRACKING',
      _buildActionCard(
        'Live Tracking',
        'View all staff on map',
        Icons.map_rounded,
        const Color(0xFF6366F1),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveTrackingOverviewPage())),
        7,
        isDark,
      ),
    );

    return Column(children: actionCards);
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, int index, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
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

  Widget _buildAdminDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF7F1D1D), const Color(0xFF450A0A)]
                      : [const Color(0xFFDC2626), const Color(0xFF991B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Center',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Index Care Support Management',
                    style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Navigation items list
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    color: const Color(0xFFDC2626),
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.confirmation_number_rounded,
                    title: 'Active Tickets',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTicketsPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.pending_actions_rounded,
                    title: 'Warranty Approvals',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WarrantyApprovalsPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_rounded,
                    title: 'Find Users',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FindUsersPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.engineering_rounded,
                    title: 'Field Technicians',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldTechniciansPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.build_circle_rounded,
                    title: 'Installers',
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallersPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Field Staff & Sales',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldStaffSalesPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.emoji_events_rounded,
                    title: 'Technician Rankings',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianRankingsPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.map_rounded,
                    title: 'Live Tracking Overview',
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveTrackingOverviewPage()));
                    },
                  ),
                ],
              ),
            ),

            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
            // Sign Out
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFEF4444).withOpacity(0.08),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(LogoutEvent());
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white30 : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
