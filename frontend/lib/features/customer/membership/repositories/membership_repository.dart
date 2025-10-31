// lib/features/customer/membership/repositories/membership_repository.dart
import 'package:mess_management_app/core/api/dio_client.dart';

class MembershipRepository {
  final DioClient _dio;
  MembershipRepository(this._dio);

  Future<Map<String, dynamic>> getMembershipDetails(String membershipId) async {
    final res = await _dio.get('/membership/details/$membershipId');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyMemberships() async {
    final res = await _dio.get('/membership/my-memberships');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> leaveMess(String membershipId) async {
    final res = await _dio.put('/membership/leave/$membershipId');
    return res.data;
  }
}
