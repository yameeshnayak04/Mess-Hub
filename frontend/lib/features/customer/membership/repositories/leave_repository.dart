import '../../../../core/api/dio_client.dart';

class LeaveRepository {
  final DioClient _dio;
  LeaveRepository(this._dio);

  // Customer
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

  // Manager
  Future<List<dynamic>> getLeaveRequestsForMyMess() async {
    final res = await _dio.get('/leave/requests/my-mess');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> approveLeave(String leaveId) async {
    final res = await _dio.put('/leave/approve/$leaveId');
    return res.data;
  }

  Future<Map<String, dynamic>> rejectLeave(String leaveId) async {
    final res = await _dio.put('/leave/reject/$leaveId');
    return res.data;
  }
}
