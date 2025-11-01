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

  // Login with phone + password
  Future<void> login(String phone, String password) async {
    try {
      _errorMessage = null;
      final resp = await _repository.login(phone, password);
      if (resp == null) {
        // 401
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
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> kioskLogin(String phone, String pin) async {
    try {
      _errorMessage = null;
      final resp = await _repository.kioskLogin(phone, pin);
      if (resp != null && resp.containsKey('error')) {
        state = const AsyncValue.data(null);
        _errorMessage = resp['error'] as String? ?? 'Invalid credentials';
        return;
      }
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
      state = AsyncValue.error(e, st);
    }
  }

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
    } catch (e, st) {
      _errorMessage =
          e is DioException && e.message != null ? e.message : e.toString();
      state = AsyncValue.error(e, st);
    }
  }

  // Refresh profile (after app resume or profile update)
  Future<void> refreshProfile() async {
    try {
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      // Don't log out, just keep old state if refresh fails
    }
  }

  // Clear last auth error (call on input change)
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
