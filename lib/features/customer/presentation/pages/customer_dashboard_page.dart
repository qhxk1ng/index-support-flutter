import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/warranty_entity.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import 'raise_complaint_page.dart';
import 'existing_tickets_page.dart';
import 'warranty_registration_page.dart';
import 'registered_products_page.dart';
import 'account_settings_page.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(label: 'Requests', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
    _NavItem(label: 'Warranty', icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          _RequestsTab(),
          _WarrantyTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isActive = index == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}

// ---------------------------------------------------------------------------
// HOME TAB
// ---------------------------------------------------------------------------
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(GetComplaintsEvent());
    context.read<CustomerBloc>().add(GetWarrantiesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with logo + notification
          SliverToBoxAdapter(child: _buildHeader()),

          // Greeting + New Service Request button
          SliverToBoxAdapter(child: _buildGreetingSection(context)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Your Requests section header
          SliverToBoxAdapter(child: _buildSectionHeader('Your Requests', () {
            // Find parent dashboard state and switch to Requests tab
            final dashboardState = context.findAncestorStateOfType<_CustomerDashboardPageState>();
            dashboardState?.setState(() => dashboardState._selectedIndex = 1);
          })),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Request cards
          SliverToBoxAdapter(child: _buildRequestPreview()),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Warranty Status card
          SliverToBoxAdapter(child: _buildWarrantyStatusCard()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Image.asset('assets/icons/app_icon.png', width: 36, height: 36),
          const SizedBox(width: 10),
          const Text(
            'index care',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _iconButton(Icons.notifications_none_rounded, () {}),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context) {
    final user = context.select<AuthBloc, UserEntity?>((bloc) {
      final state = bloc.state;
      return state is AuthAuthenticated ? state.user : null;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user?.name ?? 'Guest'}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How can we help you today?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // New Service Request button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<CustomerBloc>(),
                      child: const RaiseComplaintPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'New Service Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A884),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPreview() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is ComplaintsLoaded && state.complaints.isNotEmpty) {
          final complaints = state.complaints.take(3).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: complaints.map((c) => _RequestCard(complaint: c)).toList(),
            ),
          );
        }
        if (state is CustomerLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWarrantyStatusCard() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is WarrantiesLoaded && state.warranties.isNotEmpty) {
          final warranty = state.warranties.first;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _WarrantyCard(warranty: warranty),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// REQUEST CARD
// ---------------------------------------------------------------------------
class _RequestCard extends StatelessWidget {
  final ComplaintEntity complaint;
  const _RequestCard({required this.complaint});

  Color _statusColor(String status) {
    return AppColors.getStatusColor(status);
  }

  Color _statusBg(String status) {
    final c = _statusColor(status);
    return c.withOpacity(0.12);
  }

  String _subtitle() {
    if (complaint.assignments != null && complaint.assignments!.isNotEmpty) {
      return 'Technician Assigned';
    }
    if (complaint.status.toUpperCase() == 'COMPLETED') return 'Completed';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final statusLabel = complaint.status.replaceAll('_', ' ').split(' ').map((w) {
      return w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '';
    }).join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'REQ${(complaint.ticketNumber ?? complaint.id.substring(0, 6)).toString().padLeft(5, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(complaint.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            complaint.description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WARRANTY CARD
// ---------------------------------------------------------------------------
class _WarrantyCard extends StatelessWidget {
  final WarrantyEntity warranty;
  const _WarrantyCard({required this.warranty});

  @override
  Widget build(BuildContext context) {
    final isActive = warranty.isApproved && !warranty.boardWarrantyExpired && !warranty.batteryWarrantyExpired;
    final expiry = warranty.boardWarrantyExpiry ?? warranty.batteryWarrantyExpiry;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: isActive ? const Color(0xFF059669) : const Color(0xFFEF4444),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Warranty Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? 'Active' : 'Expired',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isActive ? const Color(0xFF059669) : AppColors.error,
                  ),
                ),
                if (expiry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Valid till ${DateFormat('dd MMM yyyy').format(expiry)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REQUESTS TAB
// ---------------------------------------------------------------------------
class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(GetComplaintsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<CustomerBloc>().add(GetComplaintsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerError) {
            return _errorView(state.message, () => context.read<CustomerBloc>().add(GetComplaintsEvent()));
          }
          if (state is ComplaintsLoaded) {
            if (state.complaints.isEmpty) {
              return _emptyView('No Requests Yet', 'You haven\'t raised any service requests', Icons.inbox_outlined);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.complaints.length,
              itemBuilder: (_, i) => _RequestCard(complaint: state.complaints[i]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WARRANTY TAB
// ---------------------------------------------------------------------------
class _WarrantyTab extends StatefulWidget {
  const _WarrantyTab();

  @override
  State<_WarrantyTab> createState() => _WarrantyTabState();
}

class _WarrantyTabState extends State<_WarrantyTab> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(GetWarrantiesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Warranties',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => di.sl<CustomerBloc>(),
                  child: const WarrantyRegistrationPage(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerError) {
            return _errorView(state.message, () => context.read<CustomerBloc>().add(GetWarrantiesEvent()));
          }
          if (state is WarrantiesLoaded) {
            if (state.warranties.isEmpty) {
              return _emptyView('No Warranties', 'Register a product to see warranty status', Icons.verified_user_outlined);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.warranties.length,
              itemBuilder: (_, i) => _WarrantyCard(warranty: state.warranties[i]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROFILE TAB
// ---------------------------------------------------------------------------
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsPage();
  }
}

// ---------------------------------------------------------------------------
// SHARED HELPERS
// ---------------------------------------------------------------------------
Widget _emptyView(String title, String subtitle, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      ],
    ),
  );
}

Widget _errorView(String message, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
