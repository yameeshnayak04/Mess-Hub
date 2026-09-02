// lib/features/manager/home/repositories/dashboard_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/bill.dart';
import '../../../../models/dashboard_stats.dart';
import '../../../../models/membership.dart';
import '../../../../models/menu.dart';

class DashboardRepository {
  final DioClient _dioClient;
  DashboardRepository(this._dioClient);

  /// The whole live dashboard in one call - counts, current/next meal, and
  /// today's menu. The backend computes the counts with a single grouped
  /// query, so there is nothing left to stitch together here.
  Future<DashboardStats> getDashboardStats({String? meal}) async {
    try {
      final res = await _dioClient.get(
        '/messes/my-mess/dashboard',
        queryParameters: {if (meal != null) 'meal': meal},
      );
      return DashboardStats.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<DashboardMember>> getMembersByStatus(
    String status, {
    String? meal,
  }) async {
    try {
      final res = await _dioClient.get(
        '/messes/my-mess/dashboard/members',
        queryParameters: {
          'status': status,
          if (meal != null) 'meal': meal,
          'limit': 100,
        },
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => DashboardMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<DashboardMember>> getMembersRemaining({String? meal}) =>
      getMembersByStatus('Remaining', meal: meal);

  Future<List<DashboardMember>> getMembersEating({String? meal}) =>
      getMembersByStatus('Present', meal: meal);

  Future<List<DashboardMember>> getMembersOnLeave({String? meal}) =>
      getMembersByStatus('Leave', meal: meal);

  Future<List<DashboardMember>> getMembersSkipped({String? meal}) =>
      getMembersByStatus('Skipped', meal: meal);

  // ------------------------------------------------------------- action centre

  Future<List<Bill>> getPendingApprovals() async {
    try {
      final res = await _dioClient.get(
        '/billing/mess',
        queryParameters: {'status': 'Pending Approval', 'limit': 50},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<Bill> approvePayment(String billId) async {
    try {
      final res = await _dioClient.post('/billing/$billId/approve');
      return Bill.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<Bill> rejectPayment(String billId) async {
    try {
      final res = await _dioClient.post('/billing/$billId/reject');
      return Bill.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Membership>> getPendingJoinRequests() async {
    try {
      final res = await _dioClient.get(
        '/memberships/mess',
        queryParameters: {'status': 'Pending', 'limit': 50},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Membership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<Membership> approveMembership(String membershipId) async {
    try {
      final res = await _dioClient.post('/memberships/$membershipId/approve');
      return Membership.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<void> rejectMembership(String membershipId) async {
    try {
      DioClient.unwrap(
          await _dioClient.post('/memberships/$membershipId/reject'));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Today's menu already comes back on the dashboard payload, so this is only
  /// for screens that want it on its own.
  Future<Menu?> getTodaysMenu() async {
    try {
      final stats = await getDashboardStats();
      return stats.todaysMenu;
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
