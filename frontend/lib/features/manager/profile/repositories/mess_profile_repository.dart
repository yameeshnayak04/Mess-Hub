// lib/features/manager/profile/repositories/mess_profile_repository.dart

import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class MessProfileRepository {
  final DioClient _dio;
  MessProfileRepository(this._dio);

  Future<Map<String, dynamic>> getMyMess() async {
    final res = await _dio.get('/mess/my-mess');
    return (res.data['data'] as Map).cast<String, dynamic>();
  } // immediate model (no scheduling)

  Future<Map<String, dynamic>> updateMyMess({
    required Map<String, dynamic> fields,
    MultipartFile? imageFile,
  }) async {
    // Only fields backend allows to change
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
      if (v is Map || v is List) {
        form.fields.add(MapEntry(k, jsonEncode(v)));
      } else {
        form.fields.add(MapEntry(k, v?.toString() ?? ''));
      }
    });

    if (imageFile != null) {
      form.files.add(MapEntry('messImage', imageFile));
    }

    final res = await _dio.put('/mess/my-mess', data: form);
    return (res.data as Map).cast<String, dynamic>();
  } // immediate save
}
