// lib/features/manager/profile/repositories/mess_profile_repository.dart

import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

class MessProfileRepository {
  final DioClient _dio;
  MessProfileRepository(this._dio);

  Future<Map<String, dynamic>> getMyMess() async {
    final res = await _dio.get('/mess/my-mess');
    return (res.data['data'] as Map).cast<String, dynamic>();
  } // controller auto-applies scheduled updates when due

  Future<Map<String, dynamic>> scheduleUpdate({
    required Map<String, dynamic> fields,
    MultipartFile? imageFile,
  }) async {
    // Whitelist only fields that backend allows to change
    const allowedKeys = <String>{
      'address',
      'contactPhone',
      'maxCapacity',
      'timings',
      'plans',
      'dailyThaliRate',
      'rules',
      'tiffinService',
      'basicThaliDetails',
    };

    final filtered = <String, dynamic>{};
    fields.forEach((k, v) {
      if (allowedKeys.contains(k)) {
        filtered[k] = v;
      }
    });

    final form = FormData();
    filtered.forEach((k, v) {
      form.fields.add(MapEntry(k, v?.toString() ?? ''));
    });

    if (imageFile != null) {
      form.files.add(MapEntry('messImage', imageFile));
    }

    final res = await _dio.put('/mess/my-mess', data: form);
    return (res.data as Map).cast<String, dynamic>();
  } // writes scheduledUpdates + scheduledEffectiveFrom
}
