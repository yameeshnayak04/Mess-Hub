// lib/features/manager/dashboard/repositories/dashboard_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/dashboard_stats.dart';

class DashboardRepository {
  final DioClient _dioClient;
  DashboardRepository(this._dioClient);

  // Core stats
  Future<DashboardStats> getDashboardStats() async {
    final res = await _dioClient.get('/mess/my-mess/dashboard');
    return DashboardStats.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // Drill-downs for live cards
  Future<List<dynamic>> getMembersEating() async {
    final res = await _dioClient.get('/mess/dashboard/members-eating');
    return (res.data['data'] as List);
  }

  Future<List<dynamic>> getMembersOnLeave() async {
    final res = await _dioClient.get('/mess/dashboard/members-on-leave');
    return (res.data['data'] as List);
  }

  Future<List<dynamic>> getMembersSkipped() async {
    final res = await _dioClient.get('/mess/dashboard/members-skipped');
    return (res.data['data'] as List);
  }

  // Pending approvals (billing)
  Future<List<dynamic>> getPendingApprovals() async {
    final res = await _dioClient.get('/billing/pending-approvals');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> approvePayment(String billId) async {
    final res = await _dioClient.put('/billing/approve-payment/$billId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectPayment(String billId) async {
    final res = await _dioClient.put('/billing/reject-payment/$billId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateMonthlyBills(
      {int? month, int? year}) async {
    final res = await _dioClient.post('/billing/generate-bills', data: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return res.data as Map<String, dynamic>;
  }

  // Pending join requests and actions
  Future<List<dynamic>> getPendingJoinRequests() async {
    final res = await _dioClient
        .get('/membership/mess', queryParameters: {'status': 'Pending'});
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> approveMembership(String membershipId) async {
    final res = await _dioClient.put('/membership/approve/$membershipId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    final res = await _dioClient.put('/membership/reject/$membershipId');
    return res.data as Map<String, dynamic>;
  }

  // Today’s menu for manager’s mess
  Future<Map<String, dynamic>?> getTodaysMenu() async {
    final messRes = await _dioClient.get('/mess/my-mess');
    final messId =
        (messRes.data['data'] as Map<String, dynamic>)['_id'] as String?;
    if (messId == null) return null;

    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');

    final menuRes = await _dioClient
        .get('/menu/$messId', queryParameters: {'startDate': '$y-$m-$d'});
    final list = (menuRes.data['data'] as List);
    return list.isNotEmpty ? (list.first as Map<String, dynamic>) : null;
  }
}
