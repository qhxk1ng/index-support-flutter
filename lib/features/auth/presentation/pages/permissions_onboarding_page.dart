import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsOnboardingPage extends StatefulWidget {
  final Widget child;

  const PermissionsOnboardingPage({super.key, required this.child});

  @override
  State<PermissionsOnboardingPage> createState() =>
      _PermissionsOnboardingPageState();
}

class _PermissionsOnboardingPageState extends State<PermissionsOnboardingPage>
    with TickerProviderStateMixin {
  static const _prefKey = 'permissions_onboarding_done';

  bool _loading = true;
  bool _onboardingDone = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _iconBounceController;
  late Animation<double> _iconBounce;

  final List<_PermissionStep> _steps = [
    _PermissionStep(
      icon: Icons.location_on_rounded,
      color: const Color(0xFF2563EB),
      title: 'Location Access',
      description:
          'We need your location to connect you with nearby technicians, '
          'enable live tracking during service visits, and provide accurate '
          'distance estimates.',
      whyNeeded: [
        'Find technicians closest to you',
        'Live tracking of technician en-route',
        'Accurate service area detection',
      ],
      permission: Permission.locationWhenInUse,
    ),
    _PermissionStep(
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFF59E0B),
      title: 'Notifications',
      description:
          'Stay updated with real-time alerts about your service requests, '
          'technician arrivals, and important account updates.',
      whyNeeded: [
        'Service request status updates',
        'Technician arrival notifications',
        'Important account alerts',
      ],
      permission: Permission.notification,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconBounce = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconBounceController,
        curve: Curves.elasticOut,
      ),
    );

    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_prefKey) ?? false;
    if (mounted) {
      setState(() {
        _onboardingDone = done;
        _loading = false;
      });
      if (!done) {
        _fadeController.forward();
        _iconBounceController.forward();
      }
    }
  }

  Future<void> _requestCurrentPermission() async {
    final step = _steps[_currentPage];
    await step.permission.request();
    _goNext();
  }

  void _goNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) {
      setState(() => _onboardingDone = true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _iconBounceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_onboardingDone) {
      return widget.child;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 16),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _steps.length,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _iconBounceController.reset();
                      _iconBounceController.forward();
                    },
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _buildStepPage(step);
                    },
                  ),
                ),

                // Dots + Buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _steps.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? _steps[_currentPage].color
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Allow button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _requestCurrentPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _steps[_currentPage].color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Allow ${_steps[_currentPage].title}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Not now
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: _goNext,
                          child: Text(
                            'Not Now',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildStepPage(_PermissionStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          ScaleTransition(
            scale: _iconBounce,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: step.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 52, color: step.color),
            ),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Why we need it
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we need this',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: step.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                ...step.whyNeeded.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: step.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _PermissionStep {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> whyNeeded;
  final Permission permission;

  const _PermissionStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.whyNeeded,
    required this.permission,
  });
}
