// lib/features/customer/home/repositories/membership_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/membership.dart';
import 'package:dio/dio.dart';

class MembershipRepository {
  final DioClient _dioClient;
  MembershipRepository(this._dioClient);

  String _serverMessage(Response res) {
    final data = res.data;
    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return 'Failed to load memberships';
  }

  Future<List<Membership>> getMyMemberships() async {
    final res = await _dioClient.get('/membership/my-memberships');
    if (res.statusCode != 200) {
      throw _serverMessage(res);
    }
    if (res.data == null ||
        res.data['data'] == null ||
        res.data['data'] is! List) {
      return [];
    }
    final data = res.data['data'] as List;
    return data
        .where((item) => item is Map)
        .map((json) => Membership.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // FIXED: use request-discontinue endpoint instead of deprecated /leave
  Future<void> leaveMembership(String membershipId) async {
    final res =
        await _dioClient.put('/membership/request-discontinue/$membershipId');
    if (res.statusCode != 200) {
      throw res.data?['message'] ?? 'Failed to leave mess';
    }
  }

  Future<Map<String, dynamic>> getMessRating(String messId) async {
    final res = await _dioClient.get('/mess/$messId');
    if (res.statusCode != 200) {
      throw _serverMessage(res);
    }
    if (res.data == null ||
        res.data['data'] == null ||
        res.data['data'] is! Map) {
      throw 'Failed to get mess details for rating: Invalid data format or mess not found.';
    }
    final m = res.data['data'] as Map;
    return {
      'averageRating': (m['averageRating'] as num?)?.toDouble() ?? 0.0,
      'reviewCount': m['reviewCount'] as int? ?? 0,
    };
  }
}
