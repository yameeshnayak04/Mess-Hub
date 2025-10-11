// This file contains the state management logic for authentication using Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mess_management_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mess_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:mess_management_system/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Part 1: Define the State
// This class holds the state for our authentication process.
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;

  AuthState({this.isLoading = false, this.error, this.user});

  // A factory method to create the initial state.
  factory AuthState.initial() => AuthState();

  // A copyWith method to easily create a new state object from an existing one.
  AuthState copyWith({bool? isLoading, String? error, User? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

// Part 2: Define the Notifier
// This class contains all the business logic and manages the AuthState.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial());

  Future<void> sendRegistrationOtp(
      String name, String phone, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendRegistrationOtp(name, phone, role);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw the exception so the UI can catch it.
    }
  }

  Future<void> verifyRegistrationOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.verifyRegistrationOtp(phone, otp);
      // --- ADD THIS SECTION ---
      // Save the token securely on the device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', user.token);
      // ------------------------
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

// Find the verifyLoginOtp method and update it
  Future<void> verifyLoginOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.verifyLoginOtp(phone, otp);
      // --- ADD THIS SECTION ---
      // Save the token securely on the device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', user.token);
      // ------------------------
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
}

// Part 3: Define the Providers
// These are the global providers that our UI will use to access the state and logic.

// A provider for our AuthRemoteDataSource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

// A provider for our AuthRepository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

// The main StateNotifierProvider for our authentication feature.
// The UI will watch this provider to get the AuthState and call methods on the AuthNotifier.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
