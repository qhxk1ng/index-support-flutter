import 'package:flutter/material.dart';
import '../error/app_error.dart';
import '../error/error_mapper.dart';
import '../theme/app_colors.dart';

/// Full-page or embedded widget for displaying an [AppError] with
/// appropriate iconography, title, message, hint, and an optional Retry button.
class AppErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? customTitle;
  final String? customMessage;

  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final appError = error is AppError ? (error as AppError) : ErrorMapper.from(error ?? 'An unexpected error occurred');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: appError.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                appError.icon,
                size: 36,
                color: appError.accentColor,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              customTitle ?? appError.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              customMessage ?? appError.message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Hint
            if (appError.hint != null && appError.hint!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appError.hint!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Retry Button
            if (onRetry != null && appError.isRetriable) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appError.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
