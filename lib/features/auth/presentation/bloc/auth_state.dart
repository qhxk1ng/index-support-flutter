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

class ProfileUpdated extends AuthAuthenticated {
  const ProfileUpdated({required super.user});
}

class RoleAdded extends AuthAuthenticated {
  const RoleAdded({required super.user});
}

class PasswordChanged extends AuthAuthenticated {
  const PasswordChanged({required super.user});
}

class AccountDeleted extends AuthState {}

class RoleUpgradeRequested extends AuthAuthenticated {
  final String message;
  const RoleUpgradeRequested({required super.user, required this.message});
  @override
  List<Object> get props => [user, message];
}

class RoleUpgradeRequestsLoaded extends AuthAuthenticated {
  final List<Map<String, dynamic>> requests;
  const RoleUpgradeRequestsLoaded({required super.user, required this.requests});
  @override
  List<Object> get props => [user, requests];
}

class AuthActionLoading extends AuthAuthenticated {
  const AuthActionLoading({required super.user});
}

class AuthActionError extends AuthAuthenticated {
  final String message;
  const AuthActionError({required super.user, required this.message});
  @override
  List<Object> get props => [user, message];
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object> get props => [message];
}
