import '../../../../core/api/dio_client.dart';
import '../../../../models/membership.dart';

class MembershipRepository {
  final DioClient _dioClient;

  MembershipRepository(this._dioClient);

  Future<List<Membership>> getMyMemberships() async {
    final response = await _dioClient.get('/membership/my-memberships');
    final data = response.data['data'] as List;
    return data.map((json) => Membership.fromJson(json)).toList();
  }

  Future<void> leaveMembership(String membershipId) async {
    await _dioClient.put('/membership/leave/$membershipId');
  }
}
