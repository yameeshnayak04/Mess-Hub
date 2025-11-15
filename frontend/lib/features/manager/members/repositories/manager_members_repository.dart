// lib/features/manager/members/repositories/manager_members_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ManagerMembersRepository {
  final DioClient _dio;
  ManagerMembersRepository(this._dio);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'];
    return fallback;
  }

  // List members of this manager's mess by status (Active, Inactive, Pending)
  Future<List<Map<String, dynamic>>> getMessMembers({String? status}) async {
    final res = await _dio.get('/membership/mess',
        queryParameters: {if (status != null) 'status': status});
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load members');
  }

  // Pending approvals
  Future<Map<String, dynamic>> approveMembership(String membershipId) async {
    final res = await _dio.put('/membership/approve/$membershipId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to approve membership');
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    final res = await _dio.put('/membership/reject/$membershipId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to reject membership');
  }

  // Member details for header
  Future<Map<String, dynamic>> getMemberDetails(String membershipId) async {
    final res = await _dio.get('/membership/member/$membershipId');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
      return Map<String, dynamic>.from(res.data['data'] as Map);
    }
    throw _msg(res, 'Failed to load member details');
  }

  // Attendance (manager-safe)
  Future<List<Map<String, dynamic>>> getMemberAttendance({
    required String membershipId,
    required int month,
    required int year,
  }) async {
    final res = await _dio.get('/attendance/member/$membershipId',
        queryParameters: {'month': month, 'year': year});
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load attendance');
  }

  // Leaves
  Future<List<Map<String, dynamic>>> getMemberLeaves(
      String membershipId) async {
    final res = await _dio.get('/leave/member/$membershipId');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load leaves');
  }

  // Bills
  Future<List<Map<String, dynamic>>> getMemberBills(String membershipId) async {
    final res = await _dio.get('/billing/member/$membershipId');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load bills');
  }

  Future<Map<String, dynamic>> approveDiscontinue(String membershipId) async {
    final res = await _dio.put('/membership/approve-discontinue/$membershipId');
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw _msg(res, 'Failed to approve discontinuation');
  }

  // NEW: reject customer discontinuation request
  Future<Map<String, dynamic>> rejectDiscontinue(String membershipId) async {
    final res = await _dio.put('/membership/reject-discontinue/$membershipId');
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw _msg(res, 'Failed to reject discontinuation');
  }
}
