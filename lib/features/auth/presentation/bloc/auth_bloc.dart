import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/auth_response_entity.dart';
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
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final isLoggedIn = await authRepository.isLoggedIn();
    
    if (isLoggedIn) {
      final result = await authRepository.getProfile();
      result.fold(
        (failure) => emit(AuthUnauthenticated()),
        (user) => emit(AuthAuthenticated(user: user)),
      );
    } else {
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
  
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Stop location tracking first to mark user offline
    final locationService = sl<LocationTrackingService>();
    locationService.stopTracking();

    final result = await authRepository.logout();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
