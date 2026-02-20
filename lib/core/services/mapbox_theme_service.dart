import 'package:flutter/material.dart';

class MapboxThemeService {
  /// Returns Mapbox style URL based on current time
  /// Dark mode: 6pm (18:00) to 6am (06:00)
  /// Light mode: 6am (06:00) to 6pm (18:00)
  static String getMapboxStyleUrl() {
    final now = DateTime.now();
    final hour = now.hour;

    // Dark mode: 6pm (18) to 6am (6)
    if (hour >= 18 || hour < 6) {
      return 'mapbox://styles/mapbox/dark-v11';
    }
    // Light mode: 6am (6) to 6pm (18)
    return 'mapbox://styles/mapbox/light-v11';
  }

  /// Returns whether it's currently dark mode
  static bool isDarkMode() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 18 || hour < 6;
  }

  /// Get accent color based on theme
  static Color getAccentColor(bool isDark) {
    return isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  }

  /// Get text color based on theme
  static Color getTextColor(bool isDark) {
    return isDark ? Colors.white : const Color(0xFF1F2937);
  }

  /// Get background color based on theme
  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF111827) : Colors.white;
  }
}
