// lib/features/customer/profile/repositories/user_profile_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/user.dart';

class UserProfileRepository {
  final DioClient _dio;
  UserProfileRepository(this._dio);

  Future<User> getProfile() async {
    try {
      final res = await _dio.get('/auth/me');
      return User.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// PATCH /auth/me - the profile route moved off /users and became a partial
  /// update. Only a customer may set a kiosk PIN; the backend rejects it for
  /// managers.
  Future<User> updateProfile({String? name, String? pin}) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (name != null) 'name': name,
        if (pin != null) 'pin': pin,
      });
      return User.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
