// lib/features/customer/membership/repositories/membership_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/json_parse.dart';
import '../../../../models/bill.dart';
import '../../../../models/membership.dart';
import '../../../../models/membership_details.dart';
import '../../../../models/menu.dart';

class MembershipRepository {
  final DioClient _dio;
  MembershipRepository(this._dio);

  /// One route serves both the customer and their mess manager; the backend
  /// decides who may see it.
  Future<MembershipDetails> getMembershipDetails(String membershipId) async {
    try {
      final res = await _dio.get('/memberships/$membershipId');
      return MembershipDetails.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Membership>> getMyMemberships() async {
    try {
      final res = await _dio.get('/memberships/mine');
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Membership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Asks to leave the mess for good.
  ///
  /// This immediately raises the partial bill for the month so far AND
  /// freezes the membership: no more attendance and no new leave until the
  /// manager approves or rejects the request.
  Future<Map<String, dynamic>> requestDiscontinuation(
      String membershipId) async {
    try {
      final res = await _dio.post('/memberships/$membershipId/discontinue');
      return Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Kept under the old name so existing callers keep working.
  Future<Map<String, dynamic>> leaveMess(String membershipId) =>
      requestDiscontinuation(membershipId);
}
