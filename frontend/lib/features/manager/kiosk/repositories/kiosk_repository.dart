// lib/features/manager/kiosk/repositories/kiosk_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/attendance.dart';
import '../../../../models/dashboard_stats.dart';
import '../../../../models/mess.dart';
import '../../../../models/membership.dart';

class KioskRepository {
  final DioClient _dio;
  KioskRepository(this._dio);

  Future<Mess> getMyMess() async {
    try {
      final res = await _dio.get('/messes/my-mess');
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Membership>> getActiveMembers() async {
    try {
      final res = await _dio.get(
        '/memberships/mess',
        queryParameters: {'status': 'Active', 'limit': 100},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Membership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// The three old "members eating / on leave / skipped" endpoints are now one
  /// filtered route. `meal` defaults to whatever is being served right now.
  Future<List<DashboardMember>> getMembersByStatus(
    String status, {
    String? meal,
  }) async {
    try {
      final res = await _dio.get(
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

  Future<List<DashboardMember>> getMembersEatingNow({String? meal}) =>
      getMembersByStatus('Present', meal: meal);

  Future<List<DashboardMember>> getMembersOnLeave({String? meal}) =>
      getMembersByStatus('Leave', meal: meal);

  Future<List<DashboardMember>> getMembersSkipped({String? meal}) =>
      getMembersByStatus('Skipped', meal: meal);

  /// Still expected for this meal and nothing recorded yet - the queue the
  /// kiosk is really working through.
  Future<List<DashboardMember>> getMembersRemaining({String? meal}) =>
      getMembersByStatus('Remaining', meal: meal);

  /// Normal check-in: the member picks their name and types their PIN.
  ///
  /// Body fields changed: `userId`/`kioskPin`/`mealType` are now
  /// `membershipId`/`pin`/`meal`. The backend refuses if something is already
  /// recorded for this meal - including an approved Leave, which needs the
  /// deliberate override below.
  Future<AttendanceRecord> markPresent({
    required String membershipId,
    required String pin,
    required String meal,
  }) async {
    try {
      final res = await _dio.post('/attendance/kiosk/mark', data: {
        'membershipId': int.tryParse(membershipId) ?? membershipId,
        'pin': pin,
        'meal': meal,
      });
      return AttendanceRecord.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// The member is mid-leave but has turned up anyway.
  ///
  /// This is a separate, explicit action rather than a flag on markPresent:
  /// it also corrects the leave record, so the member never keeps a rebate for
  /// days they did not take. It only ever affects TODAY and only the meal
  /// being served - there is no way to edit another day from here.
  Future<LeaveOverrideResult> overrideLeaveAndMarkPresent({
    required String membershipId,
    required String pin,
    required String meal,
  }) async {
    try {
      final res = await _dio.post('/attendance/kiosk/override-leave', data: {
        'membershipId': int.tryParse(membershipId) ?? membershipId,
        'pin': pin,
        'meal': meal,
      });
      return LeaveOverrideResult.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// A walk-in buying thalis. These are sales, not attendance, so they go to
  /// their own table - the endpoint is `walkin`, not the old `daily`.
  Future<Map<String, dynamic>> recordWalkinSale({
    required String meal,
    int quantity = 1,
  }) async {
    try {
      final res = await _dio.post(
        '/attendance/kiosk/walkin',
        data: {'meal': meal, 'quantity': quantity},
      );
      return Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
