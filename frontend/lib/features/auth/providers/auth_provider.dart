// features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client_provider.dart';
import '../../../core/api/api_exception.dart';
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

  /// Signs in, then reads the full profile.
  ///
  /// The login response deliberately carries only the basics - id, name, phone,
  /// role. `hasMess` comes from GET /auth/me, because working it out means
  /// looking for the manager's mess. Skipping that second call leaves `hasMess`
  /// null, and the router reads null as "no mess yet" and sends a manager who
  /// already has one back to the create-mess wizard.
  Future<void> login(String phone, String password) async {
    try {
      _errorMessage = null;
      final result = await _repository.login(phone, password);
      await _storage.write(StorageKeys.accessToken, result.token);
      state = AsyncValue.data(await _profileOrFallback(result.user));
    } catch (error) {
      _errorMessage = _messageFor(error);
      // Keep state stable to avoid route churn on login failure
      state = const AsyncValue.data(null);
    }
  }

  /// The signed-in user with `hasMess` filled in, falling back to what the
  /// auth response gave us if that second call fails - a network blip should
  /// not undo a successful sign-in.
  Future<User> _profileOrFallback(User fallback) async {
    try {
      return await _repository.getProfile();
    } catch (_) {
      return fallback;
    }
  }

  String _messageFor(Object error) =>
      error is ApiException ? error.friendlyMessage : error.toString();

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
      final result = await _repository.register(
        name: name,
        phone: phone,
        password: password,
        role: role,
        pin: pin,
        location: location,
      );
      await _storage.write(StorageKeys.accessToken, result.token);
      // Same second call as login. A brand-new manager has no mess yet, so
      // this correctly reports hasMess: false and the router takes them to the
      // wizard - but it gets there by asking, not by leaving the field unset.
      state = AsyncValue.data(await _profileOrFallback(result.user));
    } catch (error) {
      // Repositories throw ApiException, which already carries the server's
      // message and code (PHONE_TAKEN included).
      _errorMessage = _messageFor(error);
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
