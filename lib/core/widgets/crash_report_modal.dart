import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../navigation/app_navigator.dart';
import '../theme/app_colors.dart';

/// Modal dialog and full-screen widget for handling unexpected app crashes
/// and providing an iOS-friendly "Report Issue" action.
class CrashReportModal {
  static bool _isShowing = false;
  static DateTime? _lastShownTime;

  /// Display a crash report popup modal
  static void show(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    final now = DateTime.now();
    if (_isShowing) return;
    if (_lastShownTime != null &&
        now.difference(_lastShownTime!) < const Duration(seconds: 4)) {
      return;
    }
    _isShowing = true;
    _lastShownTime = now;

    final errorString = error?.toString() ?? 'Unknown error';
    final stackString = stackTrace?.toString() ?? '';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CrashDialog(
        error: errorString,
        stackTrace: stackString,
        onDismiss: () {
          _isShowing = false;
        },
      ),
    ).then((_) {
      _isShowing = false;
    });
  }

  /// Format structured crash payload for sharing / email
  static String formatReport(String error, String stackTrace) {
    final now = DateTime.now().toIso8601String();
    final os = Platform.isIOS ? 'iOS ${Platform.operatingSystemVersion}' : Platform.operatingSystem;

    return '''
========================================
INDEX CARE CRASH REPORT
========================================
App: ${AppConfig.appName}
Timestamp: $now
OS: $os
Error:
$error

Stack Trace:
$stackTrace
========================================
''';
  }

  /// Launch email client with pre-filled crash report & copy to clipboard
  static Future<void> sendReport(
    BuildContext context,
    String error,
    String stackTrace,
  ) async {
    final report = formatReport(error, stackTrace);

    // 1. Copy full report to clipboard
    await Clipboard.setData(ClipboardData(text: report));

    // 2. Open mailto
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@indexinformatics.in',
      queryParameters: {
        'subject': '[Index Care iOS Crash Report] ${error.split('\n').first}',
        'body': report,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Ignored if device has no default mail client
    }

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Crash details copied to clipboard & report opened.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class _CrashDialog extends StatefulWidget {
  final String error;
  final String stackTrace;
  final VoidCallback onDismiss;

  const _CrashDialog({
    required this.error,
    required this.stackTrace,
    required this.onDismiss,
  });

  @override
  State<_CrashDialog> createState() => _CrashDialogState();
}

class _CrashDialogState extends State<_CrashDialog> {
  bool _showDetails = false;

  @override
  void dispose() {
    widget.onDismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'App Encountered a Problem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An unexpected issue occurred. You can report this directly to our support team so we can resolve it.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showDetails = !_showDetails),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showDetails
                          ? Icons.arrow_drop_down_rounded
                          : Icons.arrow_right_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    Text(
                      _showDetails ? 'Hide Details' : 'View Error Details',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showDetails) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SelectableText(
                  widget.error,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AppNavigator.navigateToHome();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Return Home'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await CrashReportModal.sendReport(
                    context,
                    widget.error,
                    widget.stackTrace,
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Report Crash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full screen replacement for Flutter's default ErrorWidget.builder
class CrashReportScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const CrashReportScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final errorString = details.exception.toString();
    final stackString = details.stack?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something Went Wrong',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected error occurred in this view. Please report this issue so our team can resolve it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      errorString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          AppNavigator.navigateToHome();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Return Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await CrashReportModal.sendReport(
                            context,
                            errorString,
                            stackString,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Report Crash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
