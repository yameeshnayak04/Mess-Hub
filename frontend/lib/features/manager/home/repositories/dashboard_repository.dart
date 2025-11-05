// lib/features/manager/dashboard/repositories/dashboard_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/dashboard_stats.dart';

class DashboardRepository {
  final DioClient _dioClient;
  DashboardRepository(this._dioClient);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'] as String;
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'] as String;
    return fallback;
  }

  // Meal-aware stats for current window (Lunch/Dinner)
  Future<DashboardStats> getDashboardStats() async {
    final res = await _dioClient.get('/mess/my-mess/dashboard');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
      return DashboardStats.fromJson(
          Map<String, dynamic>.from(res.data['data'] as Map));
    }
    throw _msg(res, 'Failed to load dashboard stats');
  }

  Future<List<Map<String, dynamic>>> getMembersRemaining() async {
    try {
      final res = await _dioClient.get('/mess/dashboard/members-remaining');
      if (res.statusCode == 200 &&
          res.data is Map &&
          res.data['data'] is List) {
        return List<Map<String, dynamic>>.from(res.data['data'] as List);
      }
      throw _msg(res, 'Failed to load members remaining');
    } on DioException catch (e) {
      // Graceful fallback when route isn’t deployed yet
      if (e.response?.statusCode == 404) {
        throw 'Members remaining route not found';
      }
      rethrow;
    }
  }

  // Drill-down lists shown in MemberDetailDialog (server is meal-aware)
  Future<List<Map<String, dynamic>>> getMembersEating() async {
    final res = await _dioClient.get('/mess/dashboard/members-eating');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load members eating');
  }

  Future<List<Map<String, dynamic>>> getMembersOnLeave() async {
    final res = await _dioClient.get('/mess/dashboard/members-on-leave');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load members on leave');
  }

  Future<List<Map<String, dynamic>>> getMembersSkipped() async {
    final res = await _dioClient.get('/mess/dashboard/members-skipped');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load skipped members');
  }

  // Payments (manager)
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final res = await _dioClient.get('/billing/pending-approvals');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load pending approvals');
  }

  Future<Map<String, dynamic>> approvePayment(String billId) async {
    final res = await _dioClient.put('/billing/approve-payment/$billId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to approve payment');
  }

  Future<Map<String, dynamic>> rejectPayment(String billId) async {
    final res = await _dioClient.put('/billing/reject-payment/$billId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to reject payment');
  }

  // Membership join approvals (manager)
  Future<List<Map<String, dynamic>>> getPendingJoinRequests() async {
    final res = await _dioClient
        .get('/membership/mess', queryParameters: {'status': 'Pending'});
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load join requests');
  }

  Future<Map<String, dynamic>> approveMembership(String membershipId) async {
    final res = await _dioClient.put('/membership/approve/$membershipId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to approve membership');
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    final res = await _dioClient.put('/membership/reject/$membershipId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to reject membership');
  }

  // Today’s menu (manager’s mess)
  Future<Map<String, dynamic>?> getTodaysMenu() async {
    final messRes = await _dioClient.get('/mess/my-mess');
    final messMap = messRes.data['data'];
    final messId = messMap is Map ? messMap['_id'] as String? : null;
    if (messId == null) return null;

    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');

    final menuRes = await _dioClient.get(
      '/menu/$messId',
      queryParameters: {'startDate': '$y-$m-$d', 'endDate': '$y-$m-$d'},
    );
    if (menuRes.statusCode == 200 &&
        menuRes.data is Map &&
        menuRes.data['data'] is List) {
      final list = (menuRes.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return list.isNotEmpty ? list.first : null;
    }
    throw _msg(menuRes, 'Failed to load today’s menu');
  }
}
