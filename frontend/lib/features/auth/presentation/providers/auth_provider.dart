// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mess_management_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mess_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:mess_management_system/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;

  AuthState({this.isLoading = false, this.error, this.user});

  factory AuthState.initial() => AuthState();

  AuthState copyWith({bool? isLoading, String? error, User? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial());

  // Updated to include PIN parameter
  Future<void> sendRegistrationOtp(
      String name, String phone, String role, String? pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendRegistrationOtp(name, phone, role, pin);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyRegistrationOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.verifyRegistrationOtp(phone, otp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', user.token);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> sendLoginOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendLoginOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyLoginOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.verifyLoginOtp(phone, otp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', user.token);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
