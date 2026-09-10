import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          // Ambient soft glow 1 (Top right)
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA))
                          .withOpacity(isDark ? 0.20 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Ambient soft glow 2 (Bottom left)
          Positioned(
            bottom: -80,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA))
                          .withOpacity(isDark ? 0.16 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Subtle linear transition overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0F172A).withOpacity(0.5),
                        const Color(0xFF0B1120).withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFFEEF2FF).withOpacity(0.5),
                        const Color(0xFFF8FAFC).withOpacity(0.85),
                      ],
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
