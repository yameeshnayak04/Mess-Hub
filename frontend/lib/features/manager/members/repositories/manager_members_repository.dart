// lib/features/manager/members/repositories/manager_members_repository.dart
import '../../../../core/api/dio_client.dart';

class ManagerMembersRepository {
  final DioClient _dio;
  ManagerMembersRepository(this._dio);

  // List members of this manager's mess by status (Active, Inactive, Pending)
  Future<List<dynamic>> getMessMembers({String? status}) async {
    final res = await _dio.get('/membership/mess', queryParameters: {
      if (status != null) 'status': status,
    });
    return (res.data['data'] as List);
  }

  // Pending approvals
  Future<Map<String, dynamic>> approveMembership(String membershipId) async {
    final res = await _dio.put('/membership/approve/$membershipId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    final res = await _dio.put('/membership/reject/$membershipId');
    return res.data as Map<String, dynamic>;
  }

  // Member details for header
  Future<Map<String, dynamic>> getMemberDetails(String membershipId) async {
    final res = await _dio.get('/membership/member/$membershipId');
    return res.data['data'] as Map<String, dynamic>;
  }

  // Attendance (manager-safe)
  Future<List<dynamic>> getMemberAttendance({
    required String membershipId,
    required int month,
    required int year,
  }) async {
    final res = await _dio.get(
      '/attendance/member-calendar/$membershipId',
      queryParameters: {'month': month, 'year': year},
    );
    return res.data['data'] as List;
  }

  // Leaves
  Future<List<dynamic>> getMemberLeaves(String membershipId) async {
    final res = await _dio.get('/leave/member/$membershipId');
    return res.data['data'] as List;
  }

  // Bills
  Future<List<dynamic>> getMemberBills(String membershipId) async {
    final res = await _dio.get('/billing/member/$membershipId');
    return res.data['data'] as List;
  }
}
