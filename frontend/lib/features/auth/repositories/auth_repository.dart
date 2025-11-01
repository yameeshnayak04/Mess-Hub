// lib/features/auth/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../models/user.dart';

class AuthRepository {
  final DioClient _dioClient;
  AuthRepository(this._dioClient);

  String _serverMessage(Response res) {
    final data = res.data;
    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<Map<String, dynamic>?> login(String phone, String password) async {
    final response = await _dioClient
        .post('/auth/login', data: {'phone': phone, 'password': password});
    if (response.statusCode == 200)
      return response.data as Map<String, dynamic>;
    if (response.statusCode == 401) return null;
    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _serverMessage(response));
  }

  Future<Map<String, dynamic>?> kioskLogin(String phone, String pin) async {
    final response = await _dioClient
        .post('/auth/kiosk-login', data: {'phone': phone, 'pin': pin});
    if (response.statusCode == 200)
      return response.data as Map<String, dynamic>;
    if (response.statusCode == 401 || response.statusCode == 403) {
      return {'error': _serverMessage(response)};
    }
    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _serverMessage(response));
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? pin,
    Location? location,
  }) async {
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
    if (response.statusCode == 201)
      return response.data as Map<String, dynamic>;
    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _serverMessage(response));
  }

  Future<User> getProfile() async {
    final response = await _dioClient.get('/users/profile/me');
    if (response.statusCode == 200) return User.fromJson(response.data['data']);
    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _serverMessage(response));
  }

  Future<void> updateProfile({String? name, String? pin}) async {
    final response = await _dioClient.put('/users/profile/me', data: {
      if (name != null) 'name': name,
      if (pin != null) 'pin': pin,
    });
    if (response.statusCode != 200) {
      throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: _serverMessage(response));
    }
  }

  Future<void> serverLogout() async {
    try {
      await _dioClient.post('/auth/logout'); // fixed leading slash
    } on DioException {
      // best effort
    }
  }
}
