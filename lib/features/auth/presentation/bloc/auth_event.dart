part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class RegisterEvent extends AuthEvent {
  final String phoneNumber;
  final String name;
  final String email;
  final String role;
  final double latitude;
  final double longitude;
  final String address;
  
  const RegisterEvent({
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
  
  @override
  List<Object> get props => [phoneNumber, name, email, role, latitude, longitude, address];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String type;
  
  const SendOtpEvent({
    required this.phoneNumber,
    this.type = 'LOGIN', // Default to LOGIN type
  });
  
  @override
  List<Object> get props => [phoneNumber, type];
}

class VerifyOtpEvent extends AuthEvent {
  final String userId;
  final String otp;
  final String type;
  
  const VerifyOtpEvent({
    required this.userId,
    required this.otp,
    required this.type,
  });
  
  @override
  List<Object> get props => [userId, otp, type];
}

class SetPasswordEvent extends AuthEvent {
  final String userId;
  final String password;
  
  const SetPasswordEvent({
    required this.userId,
    required this.password,
  });
  
  @override
  List<Object> get props => [userId, password];
}

class LoginEvent extends AuthEvent {
  final String phoneNumber;
  final String? otp;
  final String? password;
  
  const LoginEvent({
    required this.phoneNumber,
    this.otp,
    this.password,
  });
  
  @override
  List<Object?> get props => [phoneNumber, otp, password];
}

class AdminLoginEvent extends AuthEvent {
  final String phoneNumber;
  final String password;
  
  const AdminLoginEvent({
    required this.phoneNumber,
    required this.password,
  });
  
  @override
  List<Object> get props => [phoneNumber, password];
}

class GetProfileEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String name;
  final String email;
  
  const UpdateProfileEvent({
    required this.name,
    required this.email,
  });
  
  @override
  List<Object> get props => [name, email];
}

class SwitchRoleEvent extends AuthEvent {
  final String role;
  
  const SwitchRoleEvent({required this.role});
  
  @override
  List<Object> get props => [role];
}

class AddRoleEvent extends AuthEvent {
  final String role;
  final double latitude;
  final double longitude;
  final String address;
  
  const AddRoleEvent({
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
  
  @override
  List<Object> get props => [role, latitude, longitude, address];
}

class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  
  const ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
  
  @override
  List<Object> get props => [currentPassword, newPassword];
}

class LogoutEvent extends AuthEvent {}
