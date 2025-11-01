// lib/features/customer/membership/repositories/leave_repository.dart
import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

class LeaveRepository {
  final DioClient _dio;
  LeaveRepository(this._dio);

  String _msg(Response res) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    return 'Failed to apply leave';
  }

  Future<Map<String, dynamic>> applyLeave({
    required String membershipId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await _dio.post('/leave/apply/$membershipId', data: {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
    if (res.statusCode != 201 && res.statusCode != 200) throw _msg(res);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyLeaves(String membershipId) async {
    final res = await _dio.get('/leave/my/$membershipId');
    if (res.statusCode != 200) throw _msg(res);
    return (res.data['data'] as List);
  }
}
