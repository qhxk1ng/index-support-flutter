import 'package:flutter/material.dart';
import '../error/app_error.dart';
import '../error/error_mapper.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

/// Rich, animated error popup. Automatically picks icon/colour from the
/// [AppError.type]. Offers a "Retry" button for retriable errors, plus an
/// optional "Show details" disclosure for technical debugging.
class AppErrorDialog extends StatefulWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String primaryActionLabel;

  const AppErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.primaryActionLabel = 'OK',
  });

  /// Convenience: show the dialog directly from any [Object] error.
  /// Prefer this from BLoC listeners, catch blocks, etc.
  static Future<void> show(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool isMapRequest = false,
    String primaryActionLabel = 'OK',
  }) {
    final mapped =
        error is AppError ? error : ErrorMapper.from(error, isMapRequest: isMapRequest);
    return showFor(
      context,
      mapped,
      onRetry: onRetry,
      onDismiss: onDismiss,
      primaryActionLabel: primaryActionLabel,
    );
  }

  /// Show with an already-mapped [AppError].
  static Future<void> showFor(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String primaryActionLabel = 'OK',
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Error',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AppErrorDialog(
              error: error,
              onRetry: onRetry,
              onDismiss: onDismiss,
              primaryActionLabel: primaryActionLabel,
            ),
          ),
        );
      },
    );
  }

  @override
  State<AppErrorDialog> createState() => _AppErrorDialogState();
}

class _AppErrorDialogState extends State<AppErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final err = widget.error;
    final accent = err.accentColor;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(accent),
          const SizedBox(height: 20),
          Text(
            err.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            err.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (err.hint != null) ...[
            const SizedBox(height: 12),
            _buildHintBanner(isDark, accent, err.hint!),
          ],
          if (err.technicalDetails != null) _buildDetailsToggle(isDark),
          if (_showDetails && err.technicalDetails != null)
            _buildTechnicalBox(isDark, err.technicalDetails!),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildIcon(Color accent) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.error.icon, color: accent, size: 38),
    );
  }

  Widget _buildHintBanner(bool isDark, Color accent, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => setState(() => _showDetails = !_showDetails),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: isDark ? Colors.white54 : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              _showDetails ? 'Hide details' : 'Show details',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalBox(bool isDark, String tech) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tech,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.white54 : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canRetry = widget.onRetry != null && widget.error.isRetriable;
    if (canRetry) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismiss?.call();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              height: 48,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRetry!();
              },
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: widget.primaryActionLabel,
        height: 48,
        onPressed: () {
          Navigator.of(context).pop();
          widget.onDismiss?.call();
        },
      ),
    );
  }
}
