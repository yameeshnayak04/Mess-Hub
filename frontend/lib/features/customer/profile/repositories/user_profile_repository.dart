// lib/features/customer/profile/repositories/user_profile_repository.dart
import '../../../../core/api/dio_client.dart';

class UserProfileRepository {
  final DioClient dio;
  UserProfileRepository(this.dio);

  // Update any subset of fields; backend supports name and (for customers) pin
  Future<Map<String, dynamic>> updateProfile(
      {String? name, String? pin}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (pin != null) body['pin'] = pin;
    final res = await dio.put('users/profile/me', data: body);
    return (res.data as Map).cast<String, dynamic>();
  } // PUT /users/profile/me [attached_file:64][attached_file:3]
}
