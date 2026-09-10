import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:index_care_app/core/error/app_error.dart';
import 'package:index_care_app/core/error/error_handler.dart';
import 'package:index_care_app/core/error/error_mapper.dart';
import 'package:index_care_app/core/error/failures.dart';

void main() {
  group('ErrorMapper & mapExceptionToFailure Tests', () {
    test('Maps wrong/invalid password correctly', () {
      final err1 = ErrorMapper.from('Invalid password');
      expect(err1.type, AppErrorType.wrongPassword);
      expect(err1.title, 'Wrong Password');

      final failure = mapExceptionToFailure('Invalid password');
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'The password you entered is incorrect.');
    });

    test('Maps user not found correctly', () {
      final err = ErrorMapper.from('User not found. Please register first.');
      expect(err.type, AppErrorType.userNotFound);
      expect(err.title, 'Account Not Found');

      final failure = mapExceptionToFailure('User not found');
      expect(failure, isA<NotFoundFailure>());
    });

    test('Maps password not set correctly', () {
      final err = ErrorMapper.from('Password not set for this account. Please use OTP login.');
      expect(err.type, AppErrorType.passwordNotSet);
      expect(err.title, 'Password Not Set');

      final failure = mapExceptionToFailure('Password not set');
      expect(failure, isA<ValidationFailure>());
    });

    test('Maps already registered phone correctly', () {
      final err = ErrorMapper.from('This phone number is already registered. Please log in.');
      expect(err.type, AppErrorType.phoneAlreadyExists);
      expect(err.title, 'Phone Already Registered');

      final failure = mapExceptionToFailure('phone already exists');
      expect(failure, isA<ValidationFailure>());
    });

    test('Maps OTP errors correctly', () {
      final errInvalid = ErrorMapper.from('Invalid or wrong OTP');
      expect(errInvalid.type, AppErrorType.otpInvalid);

      final errExpired = ErrorMapper.from('OTP has expired');
      expect(errExpired.type, AppErrorType.otpExpired);
    });

    test('Maps SocketException & Network failures correctly', () {
      final errSocket = ErrorMapper.from(const SocketException('Failed host lookup'));
      expect(errSocket.type, AppErrorType.noInternet);
      expect(errSocket.title, 'No Internet Connection');

      final failure = mapExceptionToFailure(const SocketException('Connection refused'));
      expect(failure, isA<NetworkFailure>());
    });

    test('Maps DioException timeouts correctly', () {
      final dioTimeout = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final err = ErrorMapper.from(dioTimeout);
      expect(err.type, AppErrorType.timeout);
      expect(err.title, 'Connection Timed Out');
    });

    test('Maps 502/503 HTML server errors correctly', () {
      final dio502Html = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 502,
          data: '<!DOCTYPE html><html><head><title>502 Bad Gateway</title></head><body><h1>Bad Gateway</h1></body></html>',
        ),
        type: DioExceptionType.badResponse,
      );
      final err = ErrorMapper.from(dio502Html);
      expect(err.type, AppErrorType.serverDown);
      expect(err.title, 'Server Temporarily Unavailable');
      expect(err.message, contains('temporarily unavailable'));
    });

    test('Maps location disabled & permission errors correctly', () {
      final errDisabled = ErrorMapper.from('Location services are disabled');
      expect(errDisabled.type, AppErrorType.locationDisabled);

      final errDenied = ErrorMapper.from('Location permission denied');
      expect(errDenied.type, AppErrorType.locationPermissionDenied);
    });

    test('Failure.toString() returns clean message instead of class name', () {
      const failure = ServerFailure('Upgrade request already pending approval');
      expect(failure.toString(), 'Upgrade request already pending approval');
      expect('$failure', 'Upgrade request already pending approval');
    });

    test('Maps 400 DioException with JSON message to contextual title without Something Went Wrong', () {
      final dio400 = DioException(
        requestOptions: RequestOptions(path: '/user/role-upgrade-request'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/role-upgrade-request'),
          statusCode: 400,
          data: {'message': 'Upgrade request already pending approval'},
        ),
        type: DioExceptionType.badResponse,
      );
      final err = ErrorMapper.from(dio400);
      expect(err.title, isNot(contains('Something went wrong')));
      expect(err.title, isNot(contains('Something Went Wrong')));
      expect(err.message, 'Upgrade request already pending approval');
    });
  });
}
