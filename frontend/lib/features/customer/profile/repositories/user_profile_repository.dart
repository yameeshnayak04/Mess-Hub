// lib/features/customer/profile/repositories/user_profile_repository.dart
import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

class UserProfileRepository {
  final DioClient dio;
  UserProfileRepository(this.dio);

  String _msg(Response res) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'];
    return 'Failed to update profile';
  }

  // Update any subset of fields; backend supports name and (for customers) pin
  Future<Map<String, dynamic>> updateProfile(
      {String? name, String? pin}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (pin != null) body['pin'] = pin;

    final res = await dio.put('/users/profile/me', data: body);
    if (res.statusCode != 200) {
      throw _msg(res);
    }
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'success': true};
  }
}
