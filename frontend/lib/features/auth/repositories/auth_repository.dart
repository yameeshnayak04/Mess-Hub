import 'package:dio/dio.dart'; // Import Dio
import '../../../core/api/dio_client.dart';
import '../../../models/user.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  // Login with phone and password
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      if (response.statusCode == 401) return null; // invalid creds
      // Propagate other errors
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Kiosk login with phone and PIN (for customers)
  Future<Map<String, dynamic>?> kioskLogin(String phone, String pin) async {
    try {
      final response = await _dioClient.post(
        '/auth/kiosk-login',
        data: {
          'phone': phone,
          'pin': pin,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      // Return null on auth failure (401, 403)
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Pass the error message back to the provider
        return {'error': response.data['message'] ?? 'Invalid credentials'};
      }
      // Propagate other errors
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? pin,
    Location? location,
  }) async {
    try {
      final response = await _dioClient.post(
        '/auth/register',
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          'role': role,
          if (pin != null) 'pin': pin,
          if (location != null) 'location': location.toJson(),
        },
      );

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }

      // Handle registration validation errors
      if (response.statusCode == 400) {
        throw response.data['message'] ?? 'Registration failed';
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getProfile() async {
    final response = await _dioClient.get('/users/profile/me');
    if (response.statusCode == 200) {
      return User.fromJson(response.data['data']);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
    );
  }

  Future<void> updateProfile({
    String? name,
    String? pin,
  }) async {
    final response = await _dioClient.put(
      '/users/profile/me',
      data: {
        if (name != null) 'name': name,
        if (pin != null) 'pin': pin,
      },
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    }
  }

  Future<void> serverLogout() async {
    try {
      await _dioClient.post('auth/logout'); // Optional backend endpoint
    } on DioException {
      // Best-effort; ignore backend failures
    }
  }
}
