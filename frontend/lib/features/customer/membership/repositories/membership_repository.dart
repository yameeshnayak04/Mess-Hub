// lib/features/customer/membership/repositories/membership_repository.dart

import 'package:mess_management_app/core/api/dio_client.dart';
import 'package:dio/dio.dart';

class MembershipRepository {
  final DioClient _dio;
  MembershipRepository(this._dio);

  String _msg(Response res) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) {
      return d['message'] as String;
    }
    return 'Failed to load membership';
  }

  Future<Map<String, dynamic>> getMembershipDetails(String membershipId) async {
    final res = await _dio.get('/membership/details/$membershipId');
    if (res.statusCode != 200) throw _msg(res);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyMemberships() async {
    final res = await _dio.get('/membership/my-memberships');
    if (res.statusCode != 200) throw _msg(res);
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> leaveMess(String membershipId) async {
    final res = await _dio.put('/membership/request-discontinue/$membershipId');
    if (res.statusCode != 200) throw _msg(res);
    return res.data as Map<String, dynamic>;
  }
}
