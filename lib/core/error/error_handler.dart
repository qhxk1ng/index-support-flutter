import 'package:dio/dio.dart';
import 'app_error.dart';
import 'error_mapper.dart';
import 'failures.dart';

/// Translates any repository / data source error (DioException, Exception, Failure, etc.)
/// into a clean, strongly-typed [Failure] with an exact, human-readable message.
Failure mapExceptionToFailure(Object error) {
  // If already a Failure, pass through
  if (error is Failure) return error;

  // Let ErrorMapper inspect and categorize the error
  final appError = ErrorMapper.from(error);

  switch (appError.type) {
    case AppErrorType.noInternet:
    case AppErrorType.timeout:
      return NetworkFailure(appError.message);

    case AppErrorType.wrongPassword:
    case AppErrorType.invalidCredentials:
    case AppErrorType.sessionExpired:
      return UnauthorizedFailure(appError.message);

    case AppErrorType.validation:
    case AppErrorType.phoneAlreadyExists:
    case AppErrorType.otpInvalid:
    case AppErrorType.otpExpired:
    case AppErrorType.passwordNotSet:
      return ValidationFailure(appError.message);

    case AppErrorType.userNotFound:
    case AppErrorType.notFound:
      return NotFoundFailure(appError.message);

    case AppErrorType.permissionDenied:
    case AppErrorType.accountInactive:
    case AppErrorType.accountLocked:
      return PermissionFailure(appError.message);

    case AppErrorType.serverDown:
    case AppErrorType.mapServerDown:
    case AppErrorType.locationDisabled:
    case AppErrorType.locationPermissionDenied:
    case AppErrorType.unknown:
    default:
      return ServerFailure(appError.message);
  }
}
