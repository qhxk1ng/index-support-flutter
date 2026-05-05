import 'dart:io';
import 'package:dio/dio.dart';
import 'app_error.dart';
import 'exceptions.dart';

/// Maps any thrown object into a user-facing [AppError] with a nice title,
/// message and hint. Single source of truth for how raw backend / network
/// errors are translated for end users.
class ErrorMapper {
  ErrorMapper._();

  /// Map any exception to [AppError].
  static AppError from(Object error, {bool isMapRequest = false}) {
    // 1. Already an AppError — pass through.
    if (error is AppError) return error;

    // 2. Our own typed exceptions from repositories / data sources.
    if (error is NetworkException) return _mapFromText(error.message, isMapRequest: isMapRequest, fallbackTech: error.toString());
    if (error is ServerException) {
      return _serverFor(error.statusCode, error.message, isMapRequest: isMapRequest, tech: error.toString());
    }
    if (error is UnauthorizedException) {
      return _mapFromText(error.message, isMapRequest: isMapRequest, fallbackTech: error.toString());
    }
    if (error is ValidationException) {
      return AppError(
        type: AppErrorType.validation,
        title: 'Check your details',
        message: _cleanMessage(error.message) ?? 'Some of the information you entered isn\'t valid.',
        hint: 'Please review the fields and try again.',
        technicalDetails: error.toString(),
      );
    }
    if (error is CacheException) {
      return AppError(
        type: AppErrorType.unknown,
        title: 'Something went wrong',
        message: 'We couldn\'t load your saved data.',
        hint: 'Please try again or restart the app.',
        technicalDetails: error.toString(),
      );
    }

    // 3. Raw Dio exceptions (when interceptor hasn't translated yet).
    if (error is DioException) return _fromDio(error, isMapRequest: isMapRequest);

    // 4. Low-level socket / timeout errors.
    if (error is SocketException) {
      return const AppError(
        type: AppErrorType.noInternet,
        title: 'No internet connection',
        message: 'Please check your Wi-Fi or mobile data and try again.',
        hint: 'Make sure airplane mode is off.',
      );
    }
    if (error is HttpException) {
      return AppError(
        type: AppErrorType.serverDown,
        title: 'Server unreachable',
        message: 'Our servers are not responding right now.',
        hint: 'Please try again in a few minutes.',
        technicalDetails: error.toString(),
      );
    }

    // 5. Fallback — treat string representation as a backend message.
    return _mapFromText(error.toString(), isMapRequest: isMapRequest, fallbackTech: error.toString());
  }

  // ── Dio-specific mapping ───────────────────────────────────────────────
  static AppError _fromDio(DioException e, {required bool isMapRequest}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: AppErrorType.timeout,
          title: 'Connection timed out',
          message: isMapRequest
              ? 'The map server took too long to respond.'
              : 'The server took too long to respond.',
          hint: 'Check your internet speed and try again.',
          technicalDetails: e.toString(),
        );
      case DioExceptionType.connectionError:
        return AppError(
          type: AppErrorType.noInternet,
          title: 'No internet connection',
          message: 'We couldn\'t reach our servers.',
          hint: 'Please check your network and try again.',
          technicalDetails: e.toString(),
        );
      case DioExceptionType.cancel:
        return AppError(
          type: AppErrorType.unknown,
          title: 'Request cancelled',
          message: 'The request was cancelled before completing.',
          hint: 'Please try again.',
          technicalDetails: e.toString(),
        );
      case DioExceptionType.badCertificate:
        return AppError(
          type: AppErrorType.serverDown,
          title: 'Secure connection failed',
          message: 'We couldn\'t establish a secure connection to the server.',
          hint: 'Please try again later.',
          technicalDetails: e.toString(),
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = e.response?.statusCode;
        final msg = _extractMessage(e.response?.data);
        if (status != null) return _serverFor(status, msg, isMapRequest: isMapRequest, tech: e.toString());
        // Likely a socket/unknown error wrapped by Dio.
        final raw = e.error?.toString() ?? '';
        if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
          return const AppError(
            type: AppErrorType.noInternet,
            title: 'No internet connection',
            message: 'Please check your Wi-Fi or mobile data and try again.',
            hint: 'Make sure airplane mode is off.',
          );
        }
        return _mapFromText(msg ?? e.message ?? 'unknown', isMapRequest: isMapRequest, fallbackTech: e.toString());
    }
  }

  // ── HTTP status → AppError ─────────────────────────────────────────────
  static AppError _serverFor(int? status, String? message, {required bool isMapRequest, required String tech}) {
    final clean = _cleanMessage(message);
    switch (status) {
      case 400:
        // Try to detect specific server messages before defaulting to validation.
        final byText = _fromServerText(message);
        if (byText != null) return byText.copyWith(technicalDetails: tech);
        return AppError(
          type: AppErrorType.validation,
          title: 'Invalid request',
          message: clean ?? 'The information you provided is invalid.',
          hint: 'Please check your entries and try again.',
          technicalDetails: tech,
        );
      case 401:
        final byText = _fromServerText(message);
        if (byText != null) return byText.copyWith(technicalDetails: tech);
        return AppError(
          type: AppErrorType.sessionExpired,
          title: 'Session expired',
          message: 'Please sign in again to continue.',
          hint: 'Your session may have timed out for security reasons.',
          technicalDetails: tech,
        );
      case 403:
        return AppError(
          type: AppErrorType.permissionDenied,
          title: 'Access denied',
          message: clean ?? 'You don\'t have permission to perform this action.',
          hint: 'Contact your administrator if you think this is a mistake.',
          technicalDetails: tech,
        );
      case 404:
        final byText = _fromServerText(message);
        if (byText != null) return byText.copyWith(technicalDetails: tech);
        return AppError(
          type: AppErrorType.notFound,
          title: 'Not found',
          message: clean ?? 'We couldn\'t find what you were looking for.',
          hint: 'It may have been removed or never existed.',
          technicalDetails: tech,
        );
      case 409:
        final byText = _fromServerText(message);
        if (byText != null) return byText.copyWith(technicalDetails: tech);
        return AppError(
          type: AppErrorType.validation,
          title: 'Conflict',
          message: clean ?? 'That action conflicts with existing data.',
          hint: 'Please refresh and try again.',
          technicalDetails: tech,
        );
      case 422:
        return AppError(
          type: AppErrorType.validation,
          title: 'Check your details',
          message: clean ?? 'Some fields are invalid.',
          hint: 'Please review the form and try again.',
          technicalDetails: tech,
        );
      case 429:
        return AppError(
          type: AppErrorType.timeout,
          title: 'Too many requests',
          message: 'You\'ve tried too many times. Please wait a moment.',
          hint: 'Try again in a minute or two.',
          technicalDetails: tech,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          type: isMapRequest ? AppErrorType.mapServerDown : AppErrorType.serverDown,
          title: isMapRequest ? 'Map service unavailable' : 'Server is down',
          message: isMapRequest
              ? 'Our map server is temporarily unavailable.'
              : 'Our servers are temporarily unavailable.',
          hint: 'Please try again in a few minutes.',
          technicalDetails: tech,
        );
      default:
        return AppError(
          type: AppErrorType.unknown,
          title: 'Something went wrong',
          message: clean ?? 'An unexpected error occurred.',
          hint: 'Please try again.',
          technicalDetails: tech,
        );
    }
  }

  // ── Text pattern matching (backend message strings) ────────────────────
  static AppError _mapFromText(String raw, {required bool isMapRequest, String? fallbackTech}) {
    final specific = _fromServerText(raw);
    if (specific != null) return specific.copyWith(technicalDetails: fallbackTech);

    final lower = raw.toLowerCase();

    if (lower.contains('no internet') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable')) {
      return AppError(
        type: AppErrorType.noInternet,
        title: 'No internet connection',
        message: 'Please check your Wi-Fi or mobile data and try again.',
        hint: 'Make sure airplane mode is off.',
        technicalDetails: fallbackTech,
      );
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return AppError(
        type: AppErrorType.timeout,
        title: 'Connection timed out',
        message: 'The server took too long to respond.',
        hint: 'Check your internet speed and try again.',
        technicalDetails: fallbackTech,
      );
    }
    if (lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout')) {
      return AppError(
        type: isMapRequest ? AppErrorType.mapServerDown : AppErrorType.serverDown,
        title: isMapRequest ? 'Map service unavailable' : 'Server is down',
        message: isMapRequest
            ? 'Our map server is temporarily unavailable.'
            : 'Our servers are temporarily unavailable.',
        hint: 'Please try again in a few minutes.',
        technicalDetails: fallbackTech,
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      title: 'Something went wrong',
      message: _cleanMessage(raw) ?? 'An unexpected error occurred.',
      hint: 'Please try again.',
      technicalDetails: fallbackTech,
    );
  }

  /// Matches known backend / auth messages regardless of status code.
  static AppError? _fromServerText(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();

    // Auth: credentials
    if (lower.contains('invalid password') || lower.contains('wrong password')) {
      return const AppError(
        type: AppErrorType.wrongPassword,
        title: 'Wrong password',
        message: 'The password you entered is incorrect.',
        hint: 'Double-check your password, or tap "Forgot Password" to reset it.',
      );
    }
    if (lower.contains('invalid credentials')) {
      return const AppError(
        type: AppErrorType.invalidCredentials,
        title: 'Invalid credentials',
        message: 'Your phone number or password is incorrect.',
        hint: 'Please check both and try again.',
      );
    }

    // Auth: user
    if (lower.contains('user not found') ||
        lower.contains('no user') ||
        lower.contains('account not found') ||
        (lower.contains('user') && lower.contains('does not exist'))) {
      return const AppError(
        type: AppErrorType.userNotFound,
        title: 'Account not found',
        message: 'No account exists with this phone number.',
        hint: 'Please register first, or double-check the number.',
      );
    }

    if (lower.contains('password not set')) {
      return const AppError(
        type: AppErrorType.invalidCredentials,
        title: 'Password not set',
        message: 'This account doesn\'t have a password yet.',
        hint: 'Please sign in with OTP or reset your password.',
      );
    }
    if (lower.contains('inactive') || lower.contains('deactivated')) {
      return const AppError(
        type: AppErrorType.accountInactive,
        title: 'Account inactive',
        message: 'Your account has been deactivated.',
        hint: 'Please contact support for assistance.',
      );
    }
    if (lower.contains('locked')) {
      return const AppError(
        type: AppErrorType.accountLocked,
        title: 'Account locked',
        message: 'Your account has been temporarily locked.',
        hint: 'Try again later or contact support.',
      );
    }
    if (lower.contains('already exists') || lower.contains('already registered')) {
      return const AppError(
        type: AppErrorType.phoneAlreadyExists,
        title: 'Phone already registered',
        message: 'This phone number is already linked to an account.',
        hint: 'Try signing in instead, or use a different number.',
      );
    }

    // OTP
    if (lower.contains('expired') && lower.contains('otp')) {
      return const AppError(
        type: AppErrorType.otpExpired,
        title: 'OTP expired',
        message: 'The verification code has expired.',
        hint: 'Tap "Resend OTP" to get a new code.',
      );
    }
    if (lower.contains('invalid') && lower.contains('otp')) {
      return const AppError(
        type: AppErrorType.otpInvalid,
        title: 'Invalid OTP',
        message: 'The verification code you entered is incorrect.',
        hint: 'Please check the code and try again.',
      );
    }

    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? data['detail']) as String?;
    }
    return null;
  }

  /// Trim technical noise from a string that may still be shown to users.
  static String? _cleanMessage(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower.contains('dioexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('errno') ||
        lower.contains('stacktrace') ||
        lower.startsWith('exception:') ||
        lower.startsWith('type \'')) {
      return null;
    }
    return trimmed;
  }
}

extension _AppErrorCopy on AppError {
  AppError copyWith({String? technicalDetails}) => AppError(
        type: type,
        title: title,
        message: message,
        hint: hint,
        technicalDetails: technicalDetails ?? this.technicalDetails,
      );
}
