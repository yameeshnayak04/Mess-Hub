// lib/features/customer/discover/repositories/discover_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';
import '../../../../models/membership.dart';

class DiscoverRepository {
  final DioClient _dioClient;
  DiscoverRepository(this._dioClient);

  /// Results come back nearest-first, sorted by the database using PostGIS
  /// against the customer's saved location - there is no client-side sorting
  /// or filtering to do any more (`search` is a server-side filter now).
  Future<List<Mess>> discoverMesses({
    String? cuisine,
    String? serviceType,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await _dioClient.get('/messes/discover', queryParameters: {
        'page': page,
        'limit': limit,
        if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
        if (serviceType != null && serviceType.isNotEmpty)
          'serviceType': serviceType,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      });
      final data = DioClient.unwrap(res) as List;
      return data
          .whereType<Map>()
          .map((e) => Mess.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<Mess> getMessById(String messId) async {
    try {
      final res = await _dioClient.get('/messes/$messId');
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Joining now identifies the plan by id, not by its display name.
  Future<Membership> joinMess(String messId, String planId) async {
    try {
      final res = await _dioClient.post(
        '/memberships/join/$messId',
        data: {'planId': int.tryParse(planId) ?? planId},
      );
      return Membership.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
