import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/sidebar_wrapper.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/sales_personnel_entities.dart';
import '../bloc/sales_personnel_bloc.dart';
import '../bloc/sales_personnel_event.dart';
import '../bloc/sales_personnel_state.dart';
import 'log_activity_page.dart';
import 'sales_leads_page.dart';
import 'expenses_page.dart';
import 'activities_list_page.dart';

class SalesPersonnelDashboardPage extends StatefulWidget {
  const SalesPersonnelDashboardPage({super.key});

  @override
  State<SalesPersonnelDashboardPage> createState() => _SalesPersonnelDashboardPageState();
}

class _SalesPersonnelDashboardPageState extends State<SalesPersonnelDashboardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<SidebarWrapperState> _sidebarKey = GlobalKey<SidebarWrapperState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    _sidebarKey.currentState?.toggleSidebar();
  }

  List<SidebarMenuItem> _buildMenuItems(BuildContext context) {
    return [
      SidebarMenuItem(
        icon: Icons.dashboard_rounded,
        title: 'Dashboard',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
        },
      ),
      SidebarMenuItem(
        icon: Icons.location_on_rounded,
        title: 'Log Activity',
        onTap: () async {
          _sidebarKey.currentState?.closeSidebar();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SalesPersonnelBloc>(),
                child: const LogActivityPage(),
              ),
            ),
          );
          if (mounted) {
            context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
          }
        },
      ),
      SidebarMenuItem(
        icon: Icons.people_rounded,
        title: 'Sales Leads',
        onTap: () async {
          _sidebarKey.currentState?.closeSidebar();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SalesPersonnelBloc>(),
                child: const SalesLeadsPage(),
              ),
            ),
          );
          if (mounted) {
            context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
          }
        },
      ),
      SidebarMenuItem(
        icon: Icons.receipt_long_rounded,
        title: 'Expenses',
        onTap: () async {
          _sidebarKey.currentState?.closeSidebar();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SalesPersonnelBloc>(),
                child: const ExpensesPage(),
              ),
            ),
          );
          if (mounted) {
            context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
          }
        },
      ),
      SidebarMenuItem(
        icon: Icons.list_alt_rounded,
        title: 'Activities',
        onTap: () async {
          _sidebarKey.currentState?.closeSidebar();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SalesPersonnelBloc>(),
                child: const ActivitiesListPage(),
              ),
            ),
          );
          if (mounted) {
            context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        UserEntity? user;
        if (authState is AuthAuthenticated) {
          user = authState.user;
        }

        return SidebarWrapper(
          key: _sidebarKey,
          user: user,
          primaryColor: const Color(0xFF059669),
          secondaryColor: const Color(0xFF047857),
          menuItems: _buildMenuItems(context),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(user),
                  
                  // Dashboard Content
                  Expanded(
                    child: BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
                      builder: (context, state) {
                        if (state is SalesPersonnelLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF059669)),
                          );
                        }

                        if (state is SalesPersonnelError) {
                          return _buildErrorState(state.message);
                        }

                        if (state is DashboardLoaded) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                            },
                            color: const Color(0xFF059669),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildWelcomeSection(user),
                                      const SizedBox(height: 24),
                                      _buildStatsGrid(state.stats),
                                      const SizedBox(height: 28),
                                      _buildQuickActions(context),
                                      const SizedBox(height: 80),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<SalesPersonnelBloc>(),
                      child: const LogActivityPage(),
                    ),
                  ),
                );
                if (mounted) {
                  context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                }
              },
              backgroundColor: const Color(0xFF059669),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Log Activity'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(UserEntity? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleSidebar,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Track your performance',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Refresh Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading dashboard', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(UserEntity? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name?.split(' ').first ?? 'Sales Rep'}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track activities, leads & expenses',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SalesPersonnelStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Activities',
          stats.totalActivities.toString(),
          Icons.location_on_rounded,
          const Color(0xFF059669),
        ),
        _buildStatCard(
          'Sales Leads',
          stats.totalLeads.toString(),
          Icons.people_rounded,
          const Color(0xFF2563EB),
        ),
        _buildStatCard(
          'Expenses',
          '₹${stats.totalExpenseAmount.toStringAsFixed(0)}',
          Icons.account_balance_wallet_rounded,
          const Color(0xFFDC2626),
        ),
        _buildStatCard(
          'Time Spent',
          '${(stats.totalTimeSpent / 60).toStringAsFixed(0)} hrs',
          Icons.timer_rounded,
          const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Log Activity',
                Icons.add_location_alt_rounded,
                const Color(0xFF059669),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SalesPersonnelBloc>(),
                        child: const LogActivityPage(),
                      ),
                    ),
                  );
                  if (mounted) {
                    context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Add Lead',
                Icons.person_add_rounded,
                const Color(0xFF2563EB),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SalesPersonnelBloc>(),
                        child: const SalesLeadsPage(),
                      ),
                    ),
                  );
                  if (mounted) {
                    context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Record Expense',
                Icons.receipt_long_rounded,
                const Color(0xFFDC2626),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SalesPersonnelBloc>(),
                        child: const ExpensesPage(),
                      ),
                    ),
                  );
                  if (mounted) {
                    context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View Activities',
                Icons.list_alt_rounded,
                const Color(0xFFEA580C),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SalesPersonnelBloc>(),
                        child: const ActivitiesListPage(),
                      ),
                    ),
                  );
                  if (mounted) {
                    context.read<SalesPersonnelBloc>().add(LoadDashboardEvent());
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

}
