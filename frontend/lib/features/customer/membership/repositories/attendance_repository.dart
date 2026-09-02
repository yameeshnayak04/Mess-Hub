// lib/features/customer/membership/repositories/attendance_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/attendance.dart';

class AttendanceRepository {
  final DioClient _dio;
  AttendanceRepository(this._dio);

  /// Skips a meal for TODAY only.
  ///
  /// The old API took an arbitrary `date`, which let a customer add skips to
  /// past days and manufacture rebates. The backend now derives the date
  /// itself and refuses once the meal window has closed, so there is no date
  /// to pass.
  Future<AttendanceRecord> skipMeal({
    required String membershipId,
    required String meal, // 'Lunch' | 'Dinner'
  }) async {
    try {
      final res = await _dio.post(
        '/attendance/$membershipId/skip',
        data: {'meal': meal},
      );
      return AttendanceRecord.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// One month of attendance, already grouped per day by the backend.
  /// Serves both the customer viewing their own calendar and a manager
  /// viewing a member's - the same route covers both.
  Future<AttendanceCalendar> getCalendar({
    required String membershipId,
    int? month,
    int? year,
  }) async {
    try {
      final res = await _dio.get(
        '/attendance/$membershipId/calendar',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return AttendanceCalendar.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
