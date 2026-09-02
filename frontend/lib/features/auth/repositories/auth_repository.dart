// lib/features/auth/repositories/auth_repository.dart
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../models/user.dart';

/// What a successful login/register hands back: the user plus their token.
class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository {
  final DioClient _dioClient;
  AuthRepository(this._dioClient);

  /// Both login and register return `data: { user, token }`.
  AuthResult _readAuthResult(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AuthResult(
      user: User.fromJson(Map<String, dynamic>.from(map['user'] as Map)),
      token: map['token'] as String,
    );
  }

  Future<AuthResult> login(String phone, String password) async {
    try {
      final res = await _dioClient.post(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );
      return _readAuthResult(DioClient.unwrap(res));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// A Customer must send a PIN and a location; a Manager must send neither -
  /// the backend rejects those fields outright for managers.
  Future<AuthResult> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? pin,
    Location? location,
  }) async {
    final isCustomer = role == 'Customer';
    try {
      final res = await _dioClient.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        if (isCustomer && pin != null) 'pin': pin,
        if (isCustomer && location != null) 'location': location.toJson(),
      });
      return _readAuthResult(DioClient.unwrap(res));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<User> getProfile() async {
    try {
      final res = await _dioClient.get('/auth/me');
      return User.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// PATCH, not PUT - and the profile route now lives under /auth.
  Future<User> updateProfile({String? name, String? pin}) async {
    try {
      final res = await _dioClient.patch('/auth/me', data: {
        if (name != null) 'name': name,
        if (pin != null) 'pin': pin,
      });
      return User.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Tokens are stateless, so this is best-effort: the client dropping the
  /// token is what actually ends the session.
  Future<void> serverLogout() async {
    try {
      await _dioClient.post('/auth/logout');
    } on Object catch (_) {
      // ignored on purpose
    }
  }
}

/// Re-exported so callers can catch a single error type.
typedef AuthException = ApiException;
