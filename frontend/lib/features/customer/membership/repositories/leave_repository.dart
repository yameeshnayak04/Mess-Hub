// lib/features/customer/membership/repositories/leave_repository.dart
import '../../../../core/api/dio_client.dart';

class LeaveRepository {
  final DioClient _dio;
  LeaveRepository(this._dio);

  Future<Map<String, dynamic>> applyLeave({
    required String membershipId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await _dio.post('/leave/apply/$membershipId', data: {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
    return res.data;
  }

  Future<List<dynamic>> getMyLeaves(String membershipId) async {
    final res = await _dio.get('/leave/my/$membershipId');
    return (res.data['data'] as List);
  }
}
