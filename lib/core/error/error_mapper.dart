import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'app_error.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Maps any thrown object into a user-facing [AppError] with a nice title,
/// message and hint. Single source of truth for how raw backend / network
/// errors are translated for end users.
class ErrorMapper {
  ErrorMapper._();

  /// Map any exception, failure, or error object to [AppError].
  static AppError from(Object error, {bool isMapRequest = false}) {
    // 1. Already an AppError — pass through.
    if (error is AppError) return error;

    // 2. Typed Failures from repositories
    if (error is Failure) {
      final specific = _fromServerText(error.message);
      if (specific != null) return specific;

      if (error is NetworkFailure) {
        return _mapFromText(error.message, isMapRequest: isMapRequest, fallbackTech: error.toString());
      }
      if (error is UnauthorizedFailure) {
        return _fromServerText(error.message) ??
            AppError(
              type: AppErrorType.sessionExpired,
              title: 'Session Expired',
              message: error.message.isNotEmpty ? error.message : 'Please sign in again to continue.',
              hint: 'Your session may have timed out for security reasons.',
              technicalDetails: error.toString(),
            );
      }
      if (error is ValidationFailure) {
        return _fromServerText(error.message) ??
            AppError(
              type: AppErrorType.validation,
              title: 'Check Your Details',
              message: _cleanMessage(error.message) ?? 'Some of the information you entered is not valid.',
              hint: 'Please review the fields and try again.',
              technicalDetails: error.toString(),
            );
      }
      if (error is NotFoundFailure) {
        return _fromServerText(error.message) ??
            AppError(
              type: AppErrorType.notFound,
              title: 'Not Found',
              message: _cleanMessage(error.message) ?? 'The requested item was not found.',
              hint: 'Please check your information and try again.',
              technicalDetails: error.toString(),
            );
      }
      if (error is PermissionFailure) {
        return _fromServerText(error.message) ??
            AppError(
              type: AppErrorType.permissionDenied,
              title: 'Access Denied',
              message: _cleanMessage(error.message) ?? 'You don\'t have permission to perform this action.',
              hint: 'Please contact support or an administrator if you believe this is a mistake.',
              technicalDetails: error.toString(),
            );
      }
      if (error is ServerFailure) {
        return _mapFromText(error.message, isMapRequest: isMapRequest, fallbackTech: error.toString());
      }
    }

    // 3. Typed exceptions from repositories / data sources.
    if (error is NetworkException) {
      return _mapFromText(error.message, isMapRequest: isMapRequest, fallbackTech: error.toString());
    }
    if (error is ServerException) {
      return _serverFor(error.statusCode, error.message, isMapRequest: isMapRequest, tech: error.toString());
    }
    if (error is UnauthorizedException) {
      return _fromServerText(error.message) ??
          AppError(
            type: AppErrorType.sessionExpired,
            title: 'Authentication Failed',
            message: _cleanMessage(error.message) ?? 'Please sign in again to continue.',
            hint: 'Your session may have expired.',
            technicalDetails: error.toString(),
          );
    }
    if (error is ValidationException) {
      return _fromServerText(error.message) ??
          AppError(
            type: AppErrorType.validation,
            title: 'Check Your Details',
            message: _cleanMessage(error.message) ?? 'Some of the information you entered is not valid.',
            hint: 'Please review the fields and try again.',
            technicalDetails: error.toString(),
          );
    }
    if (error is CacheException) {
      return AppError(
        type: AppErrorType.unknown,
        title: 'Cache Error',
        message: 'We couldn\'t load your saved data.',
        hint: 'Please try again or restart the app.',
        technicalDetails: error.toString(),
      );
    }

    // 4. Raw Dio exceptions (when not translated yet).
    if (error is DioException) {
      return _fromDio(error, isMapRequest: isMapRequest);
    }

    // 5. Low-level socket / network errors.
    if (error is SocketException) {
      return const AppError(
        type: AppErrorType.noInternet,
        title: 'No Internet Connection',
        message: 'Please check your Wi-Fi or mobile data and try again.',
        hint: 'Make sure airplane mode is off and you have internet access.',
      );
    }
    if (error is HttpException) {
      return AppError(
        type: AppErrorType.serverDown,
        title: 'Server Unreachable',
        message: 'Our servers are not responding right now.',
        hint: 'Please try again in a few minutes.',
        technicalDetails: error.toString(),
      );
    }

    // 6. String or generic fallback.
    final rawText = error.toString();
    return _mapFromText(rawText, isMapRequest: isMapRequest, fallbackTech: rawText);
  }

  // ── Dio-specific mapping ───────────────────────────────────────────────
  static AppError _fromDio(DioException e, {required bool isMapRequest}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: AppErrorType.timeout,
          title: 'Connection Timed Out',
          message: isMapRequest
              ? 'The map server took too long to respond.'
              : 'The server took too long to respond.',
          hint: 'Check your internet connection speed and tap Retry.',
          technicalDetails: e.toString(),
        );

      case DioExceptionType.connectionError:
        return AppError(
          type: AppErrorType.noInternet,
          title: 'No Internet Connection',
          message: 'Could not connect to the server.',
          hint: 'Please check your Wi-Fi or mobile data and try again.',
          technicalDetails: e.toString(),
        );

      case DioExceptionType.cancel:
        return AppError(
          type: AppErrorType.unknown,
          title: 'Request Cancelled',
          message: 'The request was cancelled before completing.',
          hint: 'Please try again.',
          technicalDetails: e.toString(),
        );

      case DioExceptionType.badCertificate:
        return AppError(
          type: AppErrorType.serverDown,
          title: 'Secure Connection Failed',
          message: 'We couldn\'t establish a secure connection to the server.',
          hint: 'Please check your device date/time settings or try again later.',
          technicalDetails: e.toString(),
        );

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = e.response?.statusCode;
        final msg = extractDioMessage(e);

        if (status != null) {
          return _serverFor(status, msg, isMapRequest: isMapRequest, tech: e.toString());
        }

        final raw = e.error?.toString() ?? e.message ?? '';
        if (raw.contains('SocketException') ||
            raw.contains('Failed host lookup') ||
            raw.contains('Network is unreachable') ||
            raw.contains('Connection refused')) {
          return const AppError(
            type: AppErrorType.noInternet,
            title: 'No Internet Connection',
            message: 'Please check your Wi-Fi or mobile data and try again.',
            hint: 'Make sure airplane mode is off.',
          );
        }
        return _mapFromText(msg ?? raw, isMapRequest: isMapRequest, fallbackTech: e.toString());
    }
  }

  // ── HTTP status → AppError ─────────────────────────────────────────────
  static AppError _serverFor(int? status, String? message, {required bool isMapRequest, required String tech}) {
    final clean = _cleanMessage(message);

    // First, check if backend returned a specific recognizable text (e.g. wrong password, user not found)
    final byText = _fromServerText(clean ?? message);
    if (byText != null) return byText.copyWith(technicalDetails: tech);

    switch (status) {
      case 400:
        return AppError(
          type: AppErrorType.validation,
          title: 'Request Notice',
          message: clean ?? 'The server could not process the request. Please verify your inputs.',
          hint: 'Please review the information and try again.',
          technicalDetails: tech,
        );

      case 401:
        return AppError(
          type: AppErrorType.invalidCredentials,
          title: 'Authentication Failed',
          message: clean ?? 'Your credentials or session is invalid. Please sign in again.',
          hint: 'Please check your phone number and password and try again.',
          technicalDetails: tech,
        );

      case 403:
        return AppError(
          type: AppErrorType.permissionDenied,
          title: 'Access Restricted',
          message: clean ?? 'You do not have permission to perform this action.',
          hint: 'Contact your administrator if you think this is a mistake.',
          technicalDetails: tech,
        );

      case 404:
        return AppError(
          type: AppErrorType.notFound,
          title: 'Not Found',
          message: clean ?? 'The requested information or resource was not found.',
          hint: 'Please double-check and try again.',
          technicalDetails: tech,
        );

      case 409:
        return AppError(
          type: AppErrorType.phoneAlreadyExists,
          title: 'Already Exists',
          message: clean ?? 'This record, phone number, or request already exists.',
          hint: 'Please check your information or try again.',
          technicalDetails: tech,
        );

      case 422:
        return AppError(
          type: AppErrorType.validation,
          title: 'Validation Error',
          message: clean ?? 'Some fields contain invalid data.',
          hint: 'Please review the form and try again.',
          technicalDetails: tech,
        );

      case 429:
        return AppError(
          type: AppErrorType.timeout,
          title: 'Too Many Requests',
          message: clean ?? 'You have tried too many times. Please wait a moment.',
          hint: 'Please wait a minute before trying again.',
          technicalDetails: tech,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        final hasSpecific500Msg = clean != null &&
            clean.isNotEmpty &&
            !clean.toLowerCase().contains('internal server error') &&
            clean.length < 200;

        return AppError(
          type: isMapRequest ? AppErrorType.mapServerDown : AppErrorType.serverDown,
          title: isMapRequest ? 'Map Service Unavailable' : 'Server Temporarily Unavailable',
          message: isMapRequest
              ? 'Our map server is temporarily unavailable.'
              : (hasSpecific500Msg
                  ? clean
                  : 'Our servers are currently experiencing issues. Please try again shortly.'),
          hint: 'Please try again in a few minutes.',
          technicalDetails: tech,
        );

      default:
        return AppError(
          type: AppErrorType.unknown,
          title: 'Action Notice',
          message: clean ?? 'The request could not be completed. Please try again.',
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

    // Network / Socket errors
    if (lower.contains('no internet') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception') ||
        lower.contains('failed to connect') ||
        lower.contains('handshakeexception')) {
      return AppError(
        type: AppErrorType.noInternet,
        title: 'No Internet Connection',
        message: 'Please check your Wi-Fi or mobile data and try again.',
        hint: 'Make sure airplane mode is off and you have internet access.',
        technicalDetails: fallbackTech,
      );
    }

    // Timeouts
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return AppError(
        type: AppErrorType.timeout,
        title: 'Connection Timed Out',
        message: 'The server took too long to respond.',
        hint: 'Check your internet speed and tap Retry.',
        technicalDetails: fallbackTech,
      );
    }

    // Server Errors 502 / 503 / 504
    if (lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('internal server error') ||
        lower.contains('server error occurred') ||
        lower.contains('server is down')) {
      return AppError(
        type: isMapRequest ? AppErrorType.mapServerDown : AppErrorType.serverDown,
        title: isMapRequest ? 'Map Service Unavailable' : 'Server Temporarily Unavailable',
        message: isMapRequest
            ? 'Our map server is temporarily unavailable.'
            : 'Our servers are currently undergoing maintenance or experiencing high load.',
        hint: 'Please try again in a few minutes.',
        technicalDetails: fallbackTech,
      );
    }

    // Location errors
    if (lower.contains('location services are disabled') || lower.contains('gps disabled')) {
      return AppError(
        type: AppErrorType.locationDisabled,
        title: 'Location Services Disabled',
        message: 'Your device location/GPS is currently turned off.',
        hint: 'Please enable location services in device settings and try again.',
        technicalDetails: fallbackTech,
      );
    }
    if (lower.contains('location permission') || lower.contains('location permissions')) {
      return AppError(
        type: AppErrorType.locationPermissionDenied,
        title: 'Location Permission Required',
        message: 'The app needs location access to perform this action.',
        hint: 'Please grant location permissions in app settings.',
        technicalDetails: fallbackTech,
      );
    }

    final cleaned = _cleanMessage(raw);
    final text = cleaned ?? raw;
    final textLower = text.toLowerCase();

    // Derive a clean, contextual title instead of generic "Something Went Wrong"
    String title = 'Notice';
    AppErrorType type = AppErrorType.unknown;
    if (textLower.contains('already exists') ||
        textLower.contains('already pending') ||
        textLower.contains('already registered') ||
        textLower.contains('already active') ||
        textLower.contains('already assigned')) {
      title = 'Already Exists';
      type = AppErrorType.phoneAlreadyExists;
    } else if (textLower.contains('required') ||
        textLower.contains('invalid') ||
        textLower.contains('must be') ||
        textLower.contains('cannot be')) {
      title = 'Validation Notice';
      type = AppErrorType.validation;
    } else if (textLower.contains('permission') ||
        textLower.contains('not authorized') ||
        textLower.contains('denied') ||
        textLower.contains('forbidden') ||
        textLower.contains('restricted')) {
      title = 'Access Denied';
      type = AppErrorType.permissionDenied;
    } else if (textLower.contains('not found') || textLower.contains('does not exist')) {
      title = 'Not Found';
      type = AppErrorType.notFound;
    } else if (textLower.contains('fail') || textLower.contains('error')) {
      title = 'Action Notice';
    }

    return AppError(
      type: type,
      title: title,
      message: text.isNotEmpty ? text : 'The requested action could not be completed.',
      hint: 'Please review your details or try again in a moment.',
      technicalDetails: fallbackTech,
    );
  }

  /// Matches known backend / auth messages regardless of status code.
  static AppError? _fromServerText(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();

    // 0. Location: GPS / Permission (Check first to avoid colliding with 'disabled')
    if (lower.contains('location services') ||
        lower.contains('location services are disabled') ||
        lower.contains('location services disabled') ||
        lower.contains('gps disabled')) {
      return const AppError(
        type: AppErrorType.locationDisabled,
        title: 'Location Services Disabled',
        message: 'Your device location/GPS is currently turned off.',
        hint: 'Please turn on location services in device settings and try again.',
      );
    }
    if (lower.contains('location permission') ||
        lower.contains('location permissions')) {
      return const AppError(
        type: AppErrorType.locationPermissionDenied,
        title: 'Location Permission Required',
        message: 'Location access is required to capture your location.',
        hint: 'Please enable location permission in app settings.',
      );
    }

    // 1. Auth: Password errors
    if (lower.contains('invalid password') ||
        lower.contains('wrong password') ||
        lower.contains('incorrect password') ||
        lower.contains('password is incorrect')) {
      return const AppError(
        type: AppErrorType.wrongPassword,
        title: 'Wrong Password',
        message: 'The password you entered is incorrect.',
        hint: 'Double-check your password, or tap "Forgot Password" to reset it.',
      );
    }

    // 2. Auth: Credentials mismatch
    if (lower.contains('invalid credentials') || lower.contains('bad credentials')) {
      return const AppError(
        type: AppErrorType.invalidCredentials,
        title: 'Invalid Credentials',
        message: 'Your phone number or password is incorrect.',
        hint: 'Please check both your phone number and password, then try again.',
      );
    }

    // 3. Auth: User / Account not found
    if (lower.contains('user not found') ||
        lower.contains('account not found') ||
        lower.contains('no user') ||
        (lower.contains('user') && lower.contains('does not exist')) ||
        (lower.contains('account') && lower.contains('does not exist'))) {
      return const AppError(
        type: AppErrorType.userNotFound,
        title: 'Account Not Found',
        message: 'No account exists with this phone number.',
        hint: 'Please register first, or double-check the phone number entered.',
      );
    }

    // 4. Auth: Password not set
    if (lower.contains('password not set') || lower.contains('no password')) {
      return const AppError(
        type: AppErrorType.passwordNotSet,
        title: 'Password Not Set',
        message: 'This account does not have a password set yet.',
        hint: 'Please sign in with OTP or tap "Forgot Password" to set a password.',
      );
    }

    // 5. Auth: Account Inactive / Locked / Deactivated
    if (lower.contains('account is inactive') ||
        lower.contains('account deactivated') ||
        lower.contains('account is disabled') ||
        lower.contains('account disabled') ||
        lower.contains('account suspended') ||
        lower.contains('user deactivated') ||
        lower.contains('user is inactive') ||
        lower.contains('user disabled') ||
        lower.contains('deactivated') ||
        lower.contains('suspended')) {
      return const AppError(
        type: AppErrorType.accountInactive,
        title: 'Account Deactivated',
        message: 'Your account has been deactivated or disabled.',
        hint: 'Please contact customer support for assistance.',
      );
    }
    if (lower.contains('locked') || lower.contains('temporarily locked')) {
      return const AppError(
        type: AppErrorType.accountLocked,
        title: 'Account Locked',
        message: 'Your account has been temporarily locked for security.',
        hint: 'Please wait a few minutes or contact support.',
      );
    }

    // 6. Auth: Phone already exists / registered
    if (lower.contains('already exists') ||
        lower.contains('already registered') ||
        lower.contains('phone number is already linked') ||
        lower.contains('phone number is already registered')) {
      return const AppError(
        type: AppErrorType.phoneAlreadyExists,
        title: 'Phone Already Registered',
        message: 'This phone number is already registered with an account.',
        hint: 'Please sign in with your password, or use "Forgot Password".',
      );
    }

    // 7. OTP: Expired or Invalid
    if (lower.contains('expired') && lower.contains('otp')) {
      return const AppError(
        type: AppErrorType.otpExpired,
        title: 'OTP Expired',
        message: 'The verification code has expired.',
        hint: 'Tap "Resend" to get a fresh 6-digit code.',
      );
    }
    if (lower.contains('invalid') && lower.contains('otp')) {
      return const AppError(
        type: AppErrorType.otpInvalid,
        title: 'Invalid OTP',
        message: 'The verification code entered is incorrect.',
        hint: 'Please check the 6-digit code and try again.',
      );
    }

    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Robust extraction of error message from DioException response
  static String? extractDioMessage(DioException e) {
    final data = e.response?.data;
    if (data == null) {
      if (e.error is SocketException) {
        return 'Could not connect to the server. Please check your internet connection.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'The server took too long to respond. Please check your connection speed and retry.';
      }
      if (e.message != null && e.message!.isNotEmpty && !e.message!.contains('DioException')) {
        return e.message;
      }
      return null;
    }

    // If data is already a Map
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['detail'] ?? data['msg'] ?? data['description'];
      if (msg != null) {
        if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
        if (msg is List && msg.isNotEmpty) {
          return msg.map((item) => item.toString()).join('\n');
        }
        if (msg is Map) {
          final nestedMsg = msg['message'] ?? msg['error'] ?? msg['detail'];
          if (nestedMsg != null) return nestedMsg.toString();
        }
      }
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.map((item) => item.toString()).join('\n');
        }
        if (errors is Map && errors.isNotEmpty) {
          return errors.values.map((item) => item.toString()).join('\n');
        }
      }
    }

    // If data is a String
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;

      // Check if it's HTML (e.g. 502 Bad Gateway / Nginx page / PHP error)
      if (trimmed.startsWith('<') || trimmed.contains('<!DOCTYPE') || trimmed.contains('<html')) {
        final statusCode = e.response?.statusCode ?? 500;
        if (statusCode == 502 || statusCode == 504) {
          return 'Our server is temporarily unavailable (Bad Gateway). Please try again in a moment.';
        }
        if (statusCode == 503) {
          return 'Service temporarily unavailable. Please try again in a moment.';
        }
        return 'Server error ($statusCode). Please try again in a few minutes.';
      }

      // Try parsing string as JSON
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final msg = decoded['message'] ?? decoded['error'] ?? decoded['detail'] ?? decoded['msg'] ?? decoded['description'];
          if (msg != null) {
            if (msg is String && msg.trim().isNotEmpty) return msg.trim();
            if (msg is List && msg.isNotEmpty) return msg.map((item) => item.toString()).join('\n');
          }
          if (decoded['errors'] != null) {
            final errors = decoded['errors'];
            if (errors is List && errors.isNotEmpty) return errors.map((i) => i.toString()).join('\n');
            if (errors is Map && errors.isNotEmpty) return errors.values.map((i) => i.toString()).join('\n');
          }
        }
      } catch (_) {}

      // If it's a plain string and not raw technical noise
      final clean = _cleanMessage(trimmed);
      if (clean != null) return clean;
    }

    return null;
  }

  /// Trim technical noise from a string that may still be shown to users.
  static String? _cleanMessage(String? raw) {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Remove leading Exception prefixes
    final prefixes = [
      'Exception: ',
      'ServerException: ',
      'NetworkException: ',
      'UnauthorizedException: ',
      'ValidationException: ',
      'ServerFailure(',
      'NetworkFailure(',
      'ValidationFailure(',
      'UnauthorizedFailure(',
      'NotFoundFailure(',
      'PermissionFailure(',
      'Failure: ',
      'Error: ',
    ];
    for (final p in prefixes) {
      if (trimmed.startsWith(p)) {
        trimmed = trimmed.substring(p.length).trim();
        if (p.endsWith('(') && trimmed.endsWith(')')) {
          trimmed = trimmed.substring(0, trimmed.length - 1).trim();
        }
      }
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('<!doctype') || lower.contains('<html')) {
      return 'The server returned an unexpected web page instead of data.';
    }
    if (lower.contains('handshakeexception')) {
      return 'Secure connection to server failed. Please check network settings.';
    }
    if (lower.contains('socketexception') || lower.contains('failed host lookup')) {
      return 'Could not reach the server. Please check your internet connection.';
    }
    if (lower.startsWith('type \'') && lower.contains('is not a subtype')) {
      return 'Unexpected data format received from the server.';
    }
    if (lower.contains('syntaxerror')) {
      return 'Invalid server response format.';
    }
    if (lower.contains('dioexception')) {
      // If there's a readable message after colon, extract it
      final colonIdx = trimmed.lastIndexOf(':');
      if (colonIdx != -1 && colonIdx < trimmed.length - 1) {
        final candidate = trimmed.substring(colonIdx + 1).trim();
        if (candidate.isNotEmpty && !candidate.toLowerCase().contains('dioexception')) {
          return candidate;
        }
      }
      return 'Network request failed. Please check your connection.';
    }

    return trimmed;
  }
}

extension AppErrorCopy on AppError {
  AppError copyWith({String? technicalDetails}) => AppError(
        type: type,
        title: title,
        message: message,
        hint: hint,
        technicalDetails: technicalDetails ?? this.technicalDetails,
      );
}
