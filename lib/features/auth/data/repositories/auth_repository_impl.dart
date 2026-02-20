import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/storage_service.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  String _sanitizeErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('dioexception') ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('handshakeexception') ||
        msg.contains('errno') ||
        msg.contains('type \'') ||
        msg.contains('unexpected character')) {
      return 'Something went wrong. Please try again.';
    }
    if (msg.contains('timeout')) {
      return 'Connection timed out. Please check your internet.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String name,
    required String email,
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final result = await remoteDataSource.register(
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        role: role,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, String>> sendOtp(String phoneNumber, String type) async {
    try {
      final result = await remoteDataSource.sendOtp(phoneNumber, type);
      return Right(result['userId'] as String);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, void>> verifyOtp({
    required String userId,
    required String otp,
    required String type,
  }) async {
    try {
      await remoteDataSource.verifyOtp(userId: userId, otp: otp, type: type);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, void>> setPassword({
    required String userId,
    required String password,
  }) async {
    try {
      await remoteDataSource.setPassword(userId: userId, password: password);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String phoneNumber,
    String? otp,
    String? password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        phoneNumber: phoneNumber,
        otp: otp,
        password: password,
      );
      
      await storageService.saveToken(result.token);
      await storageService.saveUserData((result.user as UserModel).toJson());
      await storageService.saveActiveRole(result.user.activeRole);
      await storageService.setLoggedIn(true);
      
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, AuthResponseEntity>> adminLogin({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.adminLogin(
        phoneNumber: phoneNumber,
        password: password,
      );
      
      await storageService.saveToken(result.token);
      await storageService.saveUserData((result.user as UserModel).toJson());
      await storageService.saveActiveRole(result.user.activeRole);
      await storageService.setLoggedIn(true);
      
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final result = await remoteDataSource.getProfile();
      await storageService.saveUserData(result.toJson());
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.updateProfile(
        name: name,
        email: email,
      );
      await storageService.saveUserData(result.toJson());
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, void>> switchRole(String role) async {
    try {
      await remoteDataSource.switchRole(role);
      await storageService.saveActiveRole(role);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, void>> addRole({
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      await remoteDataSource.addRole(
        role: role,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }
  
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await storageService.clearAll();
      return const Right(null);
    } on ServerException catch (e) {
      await storageService.clearAll();
      return const Right(null);
    } catch (e) {
      await storageService.clearAll();
      return const Right(null);
    }
  }
  
  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(_sanitizeErrorMessage(e)));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await storageService.isLoggedIn();
  }
  
  @override
  Future<String?> getActiveRole() async {
    return await storageService.getActiveRole();
  }
}
