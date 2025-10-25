import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_app/core/api/dio_client.dart';
import '../../../core/api/dio_client_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants.dart';
import '../../../models/user.dart';
import '../repositories/auth_repository.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    ref.watch(dioClientProvider),
    ref.watch(storageServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final DioClient _dioClient;
  final StorageService _storage;
  late final AuthRepository _repository;

  AuthNotifier(this._dioClient, this._storage)
      : super(const AsyncValue.loading()) {
    _repository = AuthRepository(_dioClient);
    _initialize();
  }

  Future<void> _initialize() async {
    // Try to get token from storage
    final token = await _storage.read(StorageKeys.accessToken);

    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (e) {
      await _storage.delete(StorageKeys.accessToken);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String phone, String kioskPin) async {
    state = const AsyncValue.loading();

    try {
      final response = await _repository.login(phone, kioskPin);
      final token = response['token'];
      final user = User.fromJson(response['data']);

      await _storage.write(StorageKeys.accessToken, token);

      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String kioskPin,
    required String role,
    Location? location,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _repository.register(
        name: name,
        phone: phone,
        kioskPin: kioskPin,
        role: role,
        location: location,
      );

      final token = response['token'];
      final user = User.fromJson(response['data']);

      await _storage.write(StorageKeys.accessToken, token);

      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? name,
    String? kioskPin,
  }) async {
    try {
      await _repository.updateProfile(name: name, kioskPin: kioskPin);
      // Refresh user data
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
