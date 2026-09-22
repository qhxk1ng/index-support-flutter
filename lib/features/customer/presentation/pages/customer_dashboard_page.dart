import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/app_snackbar.dart';
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
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    if (_animationController != null) return;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController = controller;

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
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
        icon: Icons.verified_user_outlined,
        title: 'Register Warranty',
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    _initAnimations();
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionError) {
          AppSnackbar.showError(context, state.message);
        }
      },
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
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(UserEntity? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fade = _fadeAnimation ?? const AlwaysStoppedAnimation(1.0);
    final slide = _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
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
        title: 'Register Warranty',
        description: 'Register and activate your new product',
        icon: Icons.verified_user_rounded,
        accentColor: const Color(0xFF10B981),
        darkBackground: const [Color(0xFF0C241B), Color(0xFF113829)],
        lightBackground: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        iconGradient: const [Color(0xFF059669), Color(0xFF10B981)],
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
        description: 'View and track all your products',
        icon: Icons.inventory_2_rounded,
        accentColor: const Color(0xFFF97316),
        darkBackground: const [Color(0xFF28160B), Color(0xFF3B200F)],
        lightBackground: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        iconGradient: const [Color(0xFFEA580C), Color(0xFFF97316)],
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
      _FeatureCard(
        title: 'Raise A Complaint',
        description: 'Submit a new service ticket',
        icon: Icons.report_problem_rounded,
        accentColor: const Color(0xFF3B82F6),
        darkBackground: const [Color(0xFF0D1D38), Color(0xFF132A52)],
        lightBackground: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        iconGradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
        description: 'Track your ongoing complaints',
        icon: Icons.confirmation_number_rounded,
        accentColor: const Color(0xFFA855F7),
        darkBackground: const [Color(0xFF201038), Color(0xFF2E1750)],
        lightBackground: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
        iconGradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.80,
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
    final bgColors = isDark ? feature.darkBackground : feature.lightBackground;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? feature.accentColor.withOpacity(0.32)
                  : feature.accentColor.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? feature.accentColor.withOpacity(0.12)
                    : feature.accentColor.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              if (isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: bgColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Soft ambient top-right glow contained within the card
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          feature.accentColor.withOpacity(isDark ? 0.22 : 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: feature.iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: feature.accentColor.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          feature.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Action Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: feature.accentColor.withOpacity(isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: feature.accentColor.withOpacity(isDark ? 0.35 : 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? feature.accentColor : feature.iconGradient.first,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: isDark ? feature.accentColor : feature.iconGradient.first,
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
      ),
    );
  }

}

class _FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<Color> darkBackground;
  final List<Color> lightBackground;
  final List<Color> iconGradient;
  final VoidCallback onTap;

  _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.darkBackground,
    required this.lightBackground,
    required this.iconGradient,
    required this.onTap,
  });
}
