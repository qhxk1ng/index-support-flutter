import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/widgets/sidebar_wrapper.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/customer_bloc.dart';
import 'raise_complaint_page.dart';
import 'existing_tickets_page.dart';
import 'warranty_registration_page.dart';
import 'registered_products_page.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage>
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
        icon: Icons.dashboard_outlined,
        title: 'Dashboard',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
        },
      ),
      SidebarMenuItem(
        icon: Icons.report_problem_outlined,
        title: 'Raise Complaint',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const RaiseComplaintPage(),
              ),
            ),
          );
        },
      ),
      SidebarMenuItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Existing Tickets',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const ExistingTicketsPage(),
              ),
            ),
          );
        },
      ),
      SidebarMenuItem(
        icon: Icons.verified_user_outlined,
        title: 'Register Product',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const WarrantyRegistrationPage(),
              ),
            ),
          );
        },
      ),
      SidebarMenuItem(
        icon: Icons.inventory_2_outlined,
        title: 'Registered Products',
        onTap: () {
          _sidebarKey.currentState?.closeSidebar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const RegisteredProductsPage(),
              ),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserEntity? user;
        if (state is AuthAuthenticated) {
          user = state.user;
        }

        return SidebarWrapper(
          key: _sidebarKey,
          user: user,
          primaryColor: const Color(0xFF1E3A8A),
          secondaryColor: const Color(0xFF3B82F6),
          menuItems: _buildMenuItems(context),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  _buildTopBar(user),
                  
                  // Welcome Section
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(user),
                          const SizedBox(height: 32),
                          _buildFeatureGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(UserEntity? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Logo/Title
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
          
          const Spacer(),
          
          // Theme Toggle
          const ThemeToggleButton(),
          const SizedBox(width: 12),
          
          // Notification Icon
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(UserEntity? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.name ?? 'Guest',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can we help you today?',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureCard(
        title: 'Raise A Complaint',
        description: 'Submit a new service request',
        icon: Icons.report_problem_outlined,
        color: const Color(0xFF1E3A8A),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const RaiseComplaintPage(),
              ),
            ),
          );
        },
      ),
      _FeatureCard(
        title: 'Existing Tickets',
        description: 'View your active complaints',
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFF7C3AED),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const ExistingTicketsPage(),
              ),
            ),
          );
        },
      ),
      _FeatureCard(
        title: 'Register for Warranty',
        description: 'Register your new product',
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF059669),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const WarrantyRegistrationPage(),
              ),
            ),
          );
        },
      ),
      _FeatureCard(
        title: 'Registered Products',
        description: 'View your products',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFEA580C),
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<CustomerBloc>(),
                child: const RegisteredProductsPage(),
              ),
            ),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildFeatureCard(features[index]),
        );
      },
    );
  }

  Widget _buildFeatureCard(_FeatureCard feature) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? LinearGradient(
                    colors: [
                      feature.color.withOpacity(0.3),
                      feature.color.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : feature.gradient,
            borderRadius: BorderRadius.circular(24),
            border: isDark 
                ? Border.all(
                    color: feature.color.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: feature.color.withOpacity(isDark ? 0.1 : 0.3),
                blurRadius: isDark ? 12 : 20,
                offset: Offset(0, isDark ? 4 : 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}
