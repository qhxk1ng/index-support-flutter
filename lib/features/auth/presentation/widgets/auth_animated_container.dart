import 'package:flutter/material.dart';

class AuthAnimatedContainer extends StatefulWidget {
  final Widget logo;
  final Widget form;
  final Widget bottomContent;

  const AuthAnimatedContainer({
    super.key,
    required this.logo,
    required this.form,
    required this.bottomContent,
  });

  @override
  State<AuthAnimatedContainer> createState() => _AuthAnimatedContainerState();
}

class _AuthAnimatedContainerState extends State<AuthAnimatedContainer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _logoFade;
  late Animation<double> _formFade;
  late Animation<Offset> _logoSlide;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    ));
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),
          SlideTransition(
            position: _logoSlide,
            child: FadeTransition(
              opacity: _logoFade,
              child: widget.logo,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          SlideTransition(
            position: _formSlide,
            child: FadeTransition(
              opacity: _formFade,
              child: widget.form,
            ),
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: _formFade,
            child: widget.bottomContent,
          ),
        ],
      ),
    );
  }
}
