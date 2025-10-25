import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';

class DiscoverRepository {
  final DioClient _dioClient;

  DiscoverRepository(this._dioClient);

  Future<List<Mess>> discoverMesses({
    String? cuisine,
    String? serviceType,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (cuisine != null) queryParams['cuisine'] = cuisine;
    if (serviceType != null) queryParams['serviceType'] = serviceType;

    final response = await _dioClient.get(
      '/mess/discover',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List;
    return data.map((json) => Mess.fromJson(json)).toList();
  }

  Future<Mess> getMessById(String messId) async {
    final response = await _dioClient.get('/mess/$messId');
    return Mess.fromJson(response.data['data']);
  }

  Future<void> joinMess(String messId, String planName) async {
    await _dioClient.post(
      '/membership/join/$messId',
      data: {'planName': planName},
    );
  }
}
