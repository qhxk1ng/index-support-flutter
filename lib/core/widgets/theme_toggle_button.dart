import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isInAppBar;
  
  const ThemeToggleButton({
    super.key,
    this.isInAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    if (isInAppBar) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => themeProvider.toggleTheme(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
        ),
      );
    }
    
    return IconButton(
      onPressed: () => themeProvider.toggleTheme(),
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
