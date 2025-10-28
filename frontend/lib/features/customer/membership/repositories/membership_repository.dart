import 'package:mess_management_app/core/api/dio_client.dart';

class MembershipRepository {
  final DioClient _dio;
  MembershipRepository(this._dio);

  // Customer
  Future<Map<String, dynamic>> joinMess(String messId,
      {required String planName}) async {
    final res = await _dio
        .post('/membership/join/$messId', data: {'planName': planName});
    return res.data;
  }

  Future<List<dynamic>> getMyMemberships() async {
    final res = await _dio.get('/membership/my-memberships');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> leaveMess(String membershipId) async {
    final res = await _dio.put('/membership/leave/$membershipId');
    return res.data;
  }

  // Manager
  Future<List<dynamic>> getMessMembers({String? status}) async {
    final res = await _dio.get('/membership/mess', queryParameters: {
      if (status != null) 'status': status,
    });
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> approveMembership(String membershipId) async {
    final res = await _dio.put('/membership/approve/$membershipId');
    return res.data;
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    final res = await _dio.put('/membership/reject/$membershipId');
    return res.data;
  }
}
