// lib/features/customer/home/repositories/membership_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/membership.dart';
import '../../../../models/mess.dart';

class MembershipRepository {
  final DioClient _dioClient;
  MembershipRepository(this._dioClient);

  /// Every membership this customer has, active or not.
  ///
  /// `rateRupees` on each is the plan's CURRENT rate, re-read on every call.
  /// Do not stash it anywhere long-lived - a manager can change a plan's price
  /// and it applies to existing members from their next bill.
  Future<List<Membership>> getMyMemberships() async {
    try {
      final res = await _dioClient.get('/memberships/mine');
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Membership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Asks to leave the mess. Also freezes the membership and raises the
  /// partial bill for the month so far.
  Future<void> leaveMembership(String membershipId) async {
    try {
      final res = await _dioClient.post('/memberships/$membershipId/discontinue');
      DioClient.unwrap(res);
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// The rating now arrives nested on the mess as `rating: { average, count }`
  /// and is maintained by a database trigger, so it is always current.
  Future<MessRating> getMessRating(String messId) async {
    try {
      final res = await _dioClient.get('/messes/$messId');
      final mess = Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
      return mess.rating;
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
