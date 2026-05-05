import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Broad categorization of user-facing errors. Used for styling/icon choice
/// and for deciding which recovery actions to offer.
enum AppErrorType {
  noInternet,
  timeout,
  serverDown,
  mapServerDown,
  wrongPassword,
  userNotFound,
  invalidCredentials,
  accountInactive,
  accountLocked,
  phoneAlreadyExists,
  otpInvalid,
  otpExpired,
  validation,
  permissionDenied,
  sessionExpired,
  notFound,
  unknown,
}

/// A single, ready-to-display error description produced by [ErrorMapper].
/// Widgets consume this directly — no further parsing/transformation needed.
class AppError {
  final AppErrorType type;
  final String title;
  final String message;
  final String? hint;

  /// Optional raw/technical detail. Never shown to end users, but useful
  /// when the user taps "Show details" or for debug logs.
  final String? technicalDetails;

  const AppError({
    required this.type,
    required this.title,
    required this.message,
    this.hint,
    this.technicalDetails,
  });

  IconData get icon {
    switch (type) {
      case AppErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case AppErrorType.timeout:
        return Icons.timer_off_rounded;
      case AppErrorType.serverDown:
        return Icons.cloud_off_rounded;
      case AppErrorType.mapServerDown:
        return Icons.map_outlined;
      case AppErrorType.wrongPassword:
        return Icons.lock_person_rounded;
      case AppErrorType.userNotFound:
        return Icons.person_off_rounded;
      case AppErrorType.invalidCredentials:
        return Icons.lock_outline_rounded;
      case AppErrorType.accountInactive:
      case AppErrorType.accountLocked:
        return Icons.block_rounded;
      case AppErrorType.phoneAlreadyExists:
        return Icons.phone_disabled_rounded;
      case AppErrorType.otpInvalid:
      case AppErrorType.otpExpired:
        return Icons.pin_rounded;
      case AppErrorType.validation:
        return Icons.edit_note_rounded;
      case AppErrorType.permissionDenied:
        return Icons.do_not_disturb_on_rounded;
      case AppErrorType.sessionExpired:
        return Icons.schedule_rounded;
      case AppErrorType.notFound:
        return Icons.search_off_rounded;
      case AppErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  /// Accent colour for the header / icon background.
  Color get accentColor {
    switch (type) {
      case AppErrorType.noInternet:
      case AppErrorType.timeout:
        return AppColors.warning;
      case AppErrorType.serverDown:
      case AppErrorType.mapServerDown:
        return AppColors.info;
      case AppErrorType.wrongPassword:
      case AppErrorType.invalidCredentials:
      case AppErrorType.userNotFound:
      case AppErrorType.accountInactive:
      case AppErrorType.accountLocked:
      case AppErrorType.phoneAlreadyExists:
      case AppErrorType.otpInvalid:
      case AppErrorType.otpExpired:
      case AppErrorType.permissionDenied:
      case AppErrorType.sessionExpired:
        return AppColors.error;
      case AppErrorType.validation:
      case AppErrorType.notFound:
      case AppErrorType.unknown:
        return AppColors.error;
    }
  }

  /// True if the user can recover by simply retrying after a while
  /// (no internet, timeout, server down, etc.). UI can show a "Retry" button.
  bool get isRetriable {
    switch (type) {
      case AppErrorType.noInternet:
      case AppErrorType.timeout:
      case AppErrorType.serverDown:
      case AppErrorType.mapServerDown:
      case AppErrorType.unknown:
        return true;
      default:
        return false;
    }
  }
}
