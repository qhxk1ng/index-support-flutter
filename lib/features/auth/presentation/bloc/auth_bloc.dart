import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;
  
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
    on<RequestRoleUpgradeEvent>(_onRequestRoleUpgrade);
    on<GetMyRoleUpgradeRequestsEvent>(_onGetMyRoleUpgradeRequests);
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
      final isLoggedIn = await authRepository.isLoggedIn()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint('AuthBloc: isLoggedIn timed out');
        return false;
      });
      
      if (isLoggedIn) {
        final result = await authRepository.getProfile()
            .timeout(const Duration(seconds: 6), onTimeout: () {
          debugPrint('AuthBloc: getProfile timed out');
          return Left<Failure, UserEntity>(const NetworkFailure('Connection timed out'));
        });
        
        await result.fold(
          (failure) async {
            if (failure is UnauthorizedFailure) {
              // Token is invalid / expired -> sign out
              _currentUser = null;
              emit(AuthUnauthenticated());
            } else {
              // Network error or server temporary issue -> fallback to cached user data
              final storageService = sl<StorageService>();
              final cachedData = await storageService.getUserData();
              if (cachedData != null) {
                try {
                  final userModel = UserModel.fromJson(cachedData);
                  final userEntity = userModel.toEntity();
                  _currentUser = userEntity;
                  emit(AuthAuthenticated(user: userEntity));
                  return;
                } catch (_) {}
              }
              _currentUser = null;
              emit(AuthUnauthenticated());
            }
          },
          (user) async {
            _currentUser = user;
            emit(AuthAuthenticated(user: user));
          },
        );
      } else {
        _currentUser = null;
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('AuthBloc _onCheckAuthStatus error: $e');
      _currentUser = null;
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
    
    try {
      final result = await authRepository.login(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
        password: event.password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          return const Left(NetworkFailure('Connection timed out. Please check your internet connection.'));
        },
      );
      
      result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (authResponse) {
          _currentUser = authResponse.user;
          emit(AuthAuthenticated(user: authResponse.user));
        },
      );
    } catch (e) {
      emit(const AuthError(message: 'Login failed. Please try again.'));
    }
  }
  
  Future<void> _onAdminLogin(
    AdminLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await authRepository.adminLogin(
        phoneNumber: event.phoneNumber,
        password: event.password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          return const Left(NetworkFailure('Connection timed out. Please check your internet connection.'));
        },
      );
      
      result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (authResponse) {
          _currentUser = authResponse.user;
          emit(AuthAuthenticated(user: authResponse.user));
        },
      );
    } catch (e) {
      emit(const AuthError(message: 'Admin login failed. Please try again.'));
    }
  }
  
  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }
    
    final result = await authRepository.getProfile();
    
    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }
  
  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }
    
    final result = await authRepository.updateProfile(
      name: event.name,
      email: event.email,
    );
    
    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (user) {
        _currentUser = user;
        emit(ProfileUpdated(user: user));
      },
    );
  }
  
  Future<void> _onSwitchRole(
    SwitchRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }
    
    final result = await authRepository.switchRole(event.role);
    
    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (_) {
        add(GetProfileEvent());
      },
    );
  }
  
  Future<void> _onAddRole(
    AddRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }
    
    final result = await authRepository.addRole(
      role: event.role,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
    );
    
    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (_) {
        if (_currentUser != null) {
          emit(RoleAdded(user: _currentUser!));
        } else {
          emit(const AuthError(message: 'User session not found.'));
        }
      },
    );
  }
  
  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }
    
    final result = await authRepository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    
    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (_) {
        if (_currentUser != null) {
          emit(PasswordChanged(user: _currentUser!));
        } else {
          emit(const AuthError(message: 'User session not found.'));
        }
      },
    );
  }
  
  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }

    final locationService = sl<LocationTrackingService>();
    locationService.stopTracking();
    await BackgroundLocationService.stop();

    final result = await authRepository.deleteAccount();

    await result.fold(
      (failure) async {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (_) async {
        _currentUser = null;
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
    try {
      final locationService = sl<LocationTrackingService>();
      locationService.stopTracking();
    } catch (e) {
      debugPrint('Location tracking stop error: $e');
    }

    try {
      await BackgroundLocationService.stop().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('BackgroundLocationService.stop timed out');
        },
      );
    } catch (e) {
      debugPrint('Background location stop error: $e');
    }

    try {
      await authRepository.logout().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('authRepository.logout timed out');
          return const Right(null);
        },
      );
    } catch (e) {
      debugPrint('authRepository.logout error: $e');
    }

    // Always guarantee transition to AuthUnauthenticated
    _currentUser = null;
    emit(AuthUnauthenticated());
  }

  Future<void> _onRequestRoleUpgrade(
    RequestRoleUpgradeEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }

    final result = await authRepository.requestRoleUpgrade(
      requestedRole: event.requestedRole,
      reason: event.reason,
    );

    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (data) {
        if (_currentUser != null) {
          emit(RoleUpgradeRequested(
            user: _currentUser!,
            message: data['message']?.toString() ?? 'Role upgrade requested successfully',
          ));
        } else {
          emit(const AuthError(message: 'User session not found.'));
        }
      },
    );
  }

  Future<void> _onGetMyRoleUpgradeRequests(
    GetMyRoleUpgradeRequestsEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentUser != null) {
      emit(AuthActionLoading(user: _currentUser!));
    } else {
      emit(AuthLoading());
    }

    final result = await authRepository.getMyUpgradeRequests();

    result.fold(
      (failure) {
        if (_currentUser != null) {
          emit(AuthActionError(user: _currentUser!, message: failure.message));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (requests) {
        if (_currentUser != null) {
          emit(RoleUpgradeRequestsLoaded(user: _currentUser!, requests: requests));
        } else {
          emit(const AuthError(message: 'User session not found.'));
        }
      },
    );
  }
}
