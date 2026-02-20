part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  
  const AuthAuthenticated({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class RegistrationSuccess extends AuthState {
  final String userId;
  final String phoneNumber;
  
  const RegistrationSuccess({
    required this.userId,
    required this.phoneNumber,
  });
  
  @override
  List<Object> get props => [userId, phoneNumber];
}

class OtpSent extends AuthState {
  final String phoneNumber;
  final String userId;
  
  const OtpSent({
    required this.phoneNumber,
    required this.userId,
  });
  
  @override
  List<Object> get props => [phoneNumber, userId];
}

class OtpVerified extends AuthState {}

class PasswordSet extends AuthState {}

class ProfileUpdated extends AuthState {
  final UserEntity user;
  
  const ProfileUpdated({required this.user});
  
  @override
  List<Object> get props => [user];
}

class RoleAdded extends AuthState {}

class PasswordChanged extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object> get props => [message];
}
