// lib/features/attendance/repositories/attendance_repository.dart
import '../../../../core/api/dio_client.dart';

class AttendanceRepository {
  final DioClient _dio;
  AttendanceRepository(this._dio);

  Future<Map<String, dynamic>> skipMeal({
    required String membershipId,
    required String mealType, // 'Lunch' | 'Dinner'
    DateTime? date,
  }) async {
    final res = await _dio.post('/attendance/skip', data: {
      'membershipId': membershipId,
      'mealType': mealType,
      if (date != null) 'date': date.toIso8601String(),
    });
    return res.data;
  }

  // list of attendance entries for calendar
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
    return (res.data['data'] as List);
  }
}
