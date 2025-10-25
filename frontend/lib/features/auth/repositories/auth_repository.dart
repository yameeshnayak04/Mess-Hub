import '../../../core/api/dio_client.dart';
import '../../../models/user.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<Map<String, dynamic>> login(String phone, String kioskPin) async {
    final response = await _dioClient.post(
      '/auth/login',
      data: {
        'phone': phone,
        'kioskPin': kioskPin,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String kioskPin,
    required String role,
    Location? location,
  }) async {
    final response = await _dioClient.post(
      '/auth/register',
      data: {
        'name': name,
        'phone': phone,
        'kioskPin': kioskPin,
        'role': role,
        if (location != null) 'location': location.toJson(),
      },
    );
    return response.data;
  }

  Future<User> getProfile() async {
    final response = await _dioClient.get('/users/profile/me');
    return User.fromJson(response.data['data']);
  }

  Future<void> updateProfile({
    String? name,
    String? kioskPin,
  }) async {
    await _dioClient.put(
      '/users/profile/me',
      data: {
        if (name != null) 'name': name,
        if (kioskPin != null) 'kioskPin': kioskPin,
      },
    );
  }
}
