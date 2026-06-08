import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RegisterEvent>(_onRegister);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SetPasswordEvent>(_onSetPassword);
    on<LoginEvent>(_onLogin);
    on<AdminLoginEvent>(_onAdminLogin);
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<SwitchRoleEvent>(_onSwitchRole);
    on<AddRoleEvent>(_onAddRole);
    on<LogoutEvent>(_onLogout);
    on<ChangePasswordEvent>(_onChangePassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // isLoggedIn is just a SharedPreferences read — keep it quick.
      final isLoggedIn = await authRepository.isLoggedIn()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint('AuthBloc: isLoggedIn timed out');
        return false;
      });
      
      if (isLoggedIn) {
        // getProfile is a network call — 6s is enough for a slow connection.
        final result = await authRepository.getProfile()
            .timeout(const Duration(seconds: 6), onTimeout: () {
          debugPrint('AuthBloc: getProfile timed out');
          return Left<Failure, UserEntity>(const ServerFailure('Request timed out'));
        });
        result.fold(
          (failure) => emit(AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user: user)),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Safety net: if anything unexpected fails, go to login screen
      // instead of staying stuck on loading forever
      debugPrint('AuthBloc _onCheckAuthStatus error: $e');
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.register(
      phoneNumber: event.phoneNumber,
      name: event.name,
      email: event.email,
      role: event.role,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (data) => emit(RegistrationSuccess(
        userId: data['userId'] as String,
        phoneNumber: data['phoneNumber'] as String,
      )),
    );
  }
  
  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.sendOtp(event.phoneNumber, event.type);
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (userId) => emit(OtpSent(phoneNumber: event.phoneNumber, userId: userId)),
    );
  }
  
  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.verifyOtp(
      userId: event.userId,
      otp: event.otp,
      type: event.type,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(OtpVerified()),
    );
  }
  
  Future<void> _onSetPassword(
    SetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.setPassword(
      userId: event.userId,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(PasswordSet()),
    );
  }
  
  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.login(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResponse) => emit(AuthAuthenticated(user: authResponse.user)),
    );
  }
  
  Future<void> _onAdminLogin(
    AdminLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.adminLogin(
      phoneNumber: event.phoneNumber,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResponse) => emit(AuthAuthenticated(user: authResponse.user)),
    );
  }
  
  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.getProfile();
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
  
  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.updateProfile(
      name: event.name,
      email: event.email,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(ProfileUpdated(user: user)),
    );
  }
  
  Future<void> _onSwitchRole(
    SwitchRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.switchRole(event.role);
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) {
        add(GetProfileEvent());
      },
    );
  }
  
  Future<void> _onAddRole(
    AddRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.addRole(
      role: event.role,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(RoleAdded()),
    );
  }
  
  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(PasswordChanged()),
    );
  }
  
  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final locationService = sl<LocationTrackingService>();
    locationService.stopTracking();
    await BackgroundLocationService.stop();

    final result = await authRepository.deleteAccount();

    await result.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (_) async {
        emit(AccountDeleted());
      },
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Stop location tracking first to mark user offline
    final locationService = sl<LocationTrackingService>();
    locationService.stopTracking();
    await BackgroundLocationService.stop();

    final result = await authRepository.logout();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
