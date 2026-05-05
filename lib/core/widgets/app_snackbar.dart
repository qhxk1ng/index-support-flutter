import 'package:flutter/material.dart';
import '../error/app_error.dart';
import '../error/error_mapper.dart';
import '../theme/app_colors.dart';

/// Lightweight, non-blocking notifications used for transient errors and
/// positive confirmations. For critical / blocking errors prefer
/// `AppErrorDialog.show`.
class AppSnackbar {
  AppSnackbar._();

  /// Show an error as a snackbar (good for non-blocking failures, e.g. a
  /// single action that failed but the user can continue using the app).
  static void showError(
    BuildContext context,
    Object error, {
    bool isMapRequest = false,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final mapped =
        error is AppError ? error : ErrorMapper.from(error, isMapRequest: isMapRequest);
    _show(
      context,
      icon: mapped.icon,
      title: mapped.title,
      message: mapped.message,
      background: mapped.accentColor,
      duration: duration,
      action: action,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.check_circle_rounded,
      title: title ?? 'Success',
      message: message,
      background: AppColors.success,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.info_rounded,
      title: title ?? 'Info',
      message: message,
      background: AppColors.info,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.warning_amber_rounded,
      title: title ?? 'Heads up',
      message: message,
      background: AppColors.warning,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color background,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: background.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: action.onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
