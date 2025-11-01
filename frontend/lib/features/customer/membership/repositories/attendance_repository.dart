// lib/features/attendance/repositories/attendance_repository.dart
import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

class AttendanceRepository {
  final DioClient _dio;
  AttendanceRepository(this._dio);

  String _msg(Response res) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    return 'Failed to perform attendance action';
  }

  Future<Map<String, dynamic>> skipMeal({
    required String membershipId,
    required String mealType,
    DateTime? date,
  }) async {
    final res = await _dio.post('/attendance/skip', data: {
      'membershipId': membershipId,
      'mealType': mealType,
      if (date != null) 'date': date.toIso8601String(),
    });
    if (res.statusCode != 200) throw _msg(res);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyCalendar({
    required String membershipId,
    int? month,
    int? year,
  }) async {
    final res = await _dio
        .get('/attendance/my-calendar/$membershipId', queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    if (res.statusCode != 200) throw _msg(res);
    return (res.data['data'] as List);
  }
}
