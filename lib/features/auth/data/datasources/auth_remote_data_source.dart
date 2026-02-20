import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String name,
    required String email,
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  });
  
  Future<Map<String, dynamic>> sendOtp(String phoneNumber, String type);
  
  Future<void> verifyOtp({
    required String userId,
    required String otp,
    required String type,
  });
  
  Future<void> setPassword({
    required String userId,
    required String password,
  });
  
  Future<AuthResponseModel> login({
    required String phoneNumber,
    String? otp,
    String? password,
  });
  
  Future<AuthResponseModel> adminLogin({
    required String phoneNumber,
    required String password,
  });
  
  Future<UserModel> getProfile();
  
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  });
  
  Future<void> switchRole(String role);
  
  Future<void> addRole({
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  });

  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  
  AuthRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String name,
    required String email,
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'role': role,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
    
    return response.data['data'] as Map<String, dynamic>;
  }
  
  @override
  Future<Map<String, dynamic>> sendOtp(String phoneNumber, String type) async {
    final response = await apiClient.post(
      ApiEndpoints.sendOtp,
      data: {
        'phoneNumber': phoneNumber,
        'type': type,
      },
    );
    
    return response.data['data'] as Map<String, dynamic>;
  }
  
  @override
  Future<void> verifyOtp({
    required String userId,
    required String otp,
    required String type,
  }) async {
    await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'userId': userId,
        'otp': otp,
        'type': type,
      },
    );
  }
  
  @override
  Future<void> setPassword({
    required String userId,
    required String password,
  }) async {
    await apiClient.post(
      ApiEndpoints.setPassword,
      data: {
        'userId': userId,
        'password': password,
      },
    );
  }
  
  @override
  Future<AuthResponseModel> login({
    required String phoneNumber,
    String? otp,
    String? password,
  }) async {
    final Map<String, dynamic> data = {'phoneNumber': phoneNumber};
    
    if (password != null) {
      data['password'] = password;
    } else if (otp != null) {
      data['otp'] = otp;
    }
    
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: data,
    );
    
    return AuthResponseModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  @override
  Future<AuthResponseModel> adminLogin({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.adminLogin,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    
    return AuthResponseModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.updateProfile,
      data: {
        'name': name,
        'email': email,
      },
    );
    
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  @override
  Future<void> switchRole(String role) async {
    await apiClient.post(
      ApiEndpoints.switchRole,
      data: {'role': role},
    );
  }
  
  @override
  Future<void> addRole({
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await apiClient.post(
      ApiEndpoints.addRole,
      data: {
        'role': role,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  @override
  Future<void> logout() async {
    await apiClient.post(ApiEndpoints.logout);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
