// lib/features/customer/membership/repositories/leave_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/json_parse.dart';
import '../../../../models/leave.dart';

class LeaveRepository {
  final DioClient _dio;
  LeaveRepository(this._dio);

  /// Applies for leave. Dates are plain calendar days, sent as 'YYYY-MM-DD' -
  /// NOT ISO timestamps. Sending an instant here is what used to shift a
  /// leave by a day across the timezone boundary.
  ///
  /// The backend enforces two rules and reports them as readable messages:
  /// leave must start tomorrow or later, and it must be at least the mess's
  /// minimum number of consecutive days (that one is a database trigger).
  Future<Map<String, dynamic>> applyLeave({
    required String membershipId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final res = await _dio.post('/leave/$membershipId', data: {
        'startDate': formatCalendarDate(startDate),
        'endDate': formatCalendarDate(endDate),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Leave history for a membership. Readable by the member themselves or by
  /// their mess manager - the backend decides based on who is asking.
  Future<List<Leave>> getLeaves(
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/leave/$membershipId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Leave.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Kept under the old name so existing callers keep working.
  Future<List<Leave>> getMyLeaves(String membershipId) =>
      getLeaves(membershipId);
}
