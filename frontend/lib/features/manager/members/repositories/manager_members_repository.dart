// lib/features/manager/members/repositories/manager_members_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/attendance.dart';
import '../../../../models/bill.dart';
import '../../../../models/leave.dart';
import '../../../../models/membership.dart';
import '../../../../models/membership_details.dart';
import '../../../customer/membership/repositories/membership_repository.dart'
    show MembershipDetails;

class ManagerMembersRepository {
  final DioClient _dio;
  ManagerMembersRepository(this._dio);

  Future<List<Membership>> getMessMembers({
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final res = await _dio.get('/memberships/mess', queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      });
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Membership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Approve / reject a join request. Both are POST now, under the membership
  /// rather than as verbs in the path.
  Future<Membership> approveMembership(String membershipId) async {
    try {
      final res = await _dio.post('/memberships/$membershipId/approve');
      return Membership.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<void> rejectMembership(String membershipId) async {
    try {
      DioClient.unwrap(await _dio.post('/memberships/$membershipId/reject'));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Same route the customer uses; the backend allows a manager through for
  /// anyone in their own mess.
  Future<MembershipDetails> getMemberDetails(String membershipId) async {
    try {
      final res = await _dio.get('/memberships/$membershipId');
      return MembershipDetails.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<AttendanceCalendar> getMemberAttendance({
    required String membershipId,
    int? month,
    int? year,
  }) async {
    try {
      final res = await _dio.get(
        '/attendance/$membershipId/calendar',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return AttendanceCalendar.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Leave>> getMemberLeaves(String membershipId) async {
    try {
      final res = await _dio.get('/leave/$membershipId');
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Leave.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Bill>> getMemberBills(String membershipId) async {
    try {
      final res = await _dio.get('/billing/membership/$membershipId');
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Closing a membership for good. The backend refuses with
  /// OUTSTANDING_BILLS while anything is still Due or awaiting approval.
  Future<void> approveDiscontinue(String membershipId) async {
    try {
      DioClient.unwrap(
          await _dio.post('/memberships/$membershipId/discontinue/approve'));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Declining un-freezes the membership: attendance and leave work again,
  /// and billing goes back to counting the whole month.
  Future<void> rejectDiscontinue(String membershipId) async {
    try {
      DioClient.unwrap(
          await _dio.post('/memberships/$membershipId/discontinue/reject'));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
