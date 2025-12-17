// features/auth/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client_provider.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants.dart';
import '../../../models/user.dart';
import '../repositories/auth_repository.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(dioClient, storage);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final DioClient _dioClient;
  final StorageService _storage;
  late final AuthRepository _repository;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthNotifier(this._dioClient, this._storage)
      : super(const AsyncValue.loading()) {
    _repository = AuthRepository(_dioClient);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final token = await _storage.read(StorageKeys.accessToken);
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      await _storage.delete(StorageKeys.accessToken);
      state = const AsyncValue.data(null);
    }
  }

  // Login with phone + password (unchanged)
  Future<void> login(String phone, String password) async {
    try {
      _errorMessage = null;
      final resp = await _repository.login(phone, password);
      if (resp == null) {
        state = const AsyncValue.data(null);
        _errorMessage = 'Invalid credentials';
        return;
      }
      final token = resp['token'] as String;
      final user = User.fromJson(resp['data'] as Map<String, dynamic>);
      await _storage.write(StorageKeys.accessToken, token);
      state = AsyncValue.data(user);
    } catch (e, st) {
      _errorMessage =
          e is DioException && e.message != null ? e.message : e.toString();
      // Keep state stable to avoid route churn on login failure
      state = const AsyncValue.data(null);
    }
  }

  // Register new user: on failure, keep state = data(null) and expose message
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? pin,
    Location? location,
  }) async {
    try {
      _errorMessage = null;
      final resp = await _repository.register(
        name: name,
        phone: phone,
        password: password,
        role: role,
        pin: pin,
        location: location,
      );
      final token = resp['token'] as String;
      final user = User.fromJson(resp['data'] as Map<String, dynamic>);
      await _storage.write(StorageKeys.accessToken, token);
      state = AsyncValue.data(user);
    } catch (e) {
      // Extract server message (handles 409 USER_EXISTS cleanly)
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          _errorMessage = data['message'] as String;
        } else {
          _errorMessage = e.message ?? 'Registration failed';
        }
      } else {
        _errorMessage = e.toString();
      }
      // IMPORTANT: keep state stable so UI stays on Register screen
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      // Keep old state on refresh failure
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> logout() async {
    try {
      await _repository.serverLogout();
    } finally {
      await _storage.deleteAll();
      _dioClient.clearAuthToken();
      state = const AsyncValue.data(null);
    }
  }
}
