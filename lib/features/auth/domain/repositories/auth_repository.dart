import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String phoneNumber,
    required String name,
    required String email,
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  });
  
  Future<Either<Failure, String>> sendOtp(String phoneNumber, String type);
  
  Future<Either<Failure, void>> verifyOtp({
    required String userId,
    required String otp,
    required String type,
  });
  
  Future<Either<Failure, void>> setPassword({
    required String userId,
    required String password,
  });
  
  Future<Either<Failure, AuthResponseEntity>> login({
    required String phoneNumber,
    String? otp,
    String? password,
  });
  
  Future<Either<Failure, AuthResponseEntity>> adminLogin({
    required String phoneNumber,
    required String password,
  });
  
  Future<Either<Failure, UserEntity>> getProfile();
  
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    required String email,
  });
  
  Future<Either<Failure, void>> switchRole(String role);
  
  Future<Either<Failure, void>> addRole({
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  });
  
  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  Future<bool> isLoggedIn();
  
  Future<String?> getActiveRole();
}
