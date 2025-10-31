// lib/features/customer/home/repositories/membership_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/membership.dart';
import '../../../../models/mess.dart'; // Import Mess model

class MembershipRepository {
  final DioClient _dioClient;

  MembershipRepository(this._dioClient);

  Future<List<Membership>> getMyMemberships() async {
    final response = await _dioClient.get('/membership/my-memberships');

    // *** FIX 1: Add null checks for response data ***
    if (response.data == null ||
        response.data['data'] == null ||
        response.data['data'] is! List) {
      print("Invalid data structure received from /my-memberships");
      return []; // Return empty list on bad data
    }

    final data = response.data['data'] as List;

    // *** FIX 2: Filter out any potential nulls from the list before mapping ***
    return data
        .where((item) => item is Map<String, dynamic>) // Ensure item is a map
        .map((json) => Membership.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> leaveMembership(String membershipId) async {
    final response = await _dioClient.put('/membership/leave/$membershipId');
    if (response.statusCode != 200) {
      // Throw the error message from the backend
      throw response.data?['message'] ?? 'Failed to leave mess';
    }
  }

  Future<Map<String, dynamic>> getMessRating(String messId) async {
    final res = await _dioClient.get('/mess/$messId');

    // *** CRITICAL FIX 3: Check if res.data or res.data['data'] is null ***
    if (res.data == null ||
        res.data['data'] == null ||
        res.data['data'] is! Map<String, dynamic>) {
      // If data is null (e.g., mess not found), throw a clear error
      // instead of crashing.
      throw 'Failed to get mess details for rating: Invalid data format or mess not found.';
    }

    // If we are here, res.data['data'] is a valid Map
    final m = res.data['data'] as Map<String, dynamic>;
    return {
      'averageRating': (m['averageRating'] as num?)?.toDouble(),
      'reviewCount': m['reviewCount'] as int? ?? 0,
    };
  }
}
