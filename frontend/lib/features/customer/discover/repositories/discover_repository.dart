// lib/features/discover/repositories/discover_repository.dart
import 'package:dio/dio.dart'; // Import Dio
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';

class DiscoverRepository {
  final DioClient _dioClient;
  DiscoverRepository(this._dioClient);

  Future<List<Mess>> discoverMesses({
    String? cuisine,
    String? serviceType,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (cuisine != null) 'cuisine': cuisine,
      if (serviceType != null) 'serviceType': serviceType,
      // 'search' is not a supported param in your backend 'discoverMesses'
      // if (search != null) 'search': search,
    };

    final response =
        await _dioClient.get('/mess/discover', queryParameters: queryParams);

    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      return data.map((json) => Mess.fromJson(json)).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data['message'] ?? 'Failed to load messes',
    );
  }

  Future<Mess> getMessById(String messId) async {
    final response = await _dioClient.get('/mess/$messId');
    if (response.statusCode == 200) {
      return Mess.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data['message'] ?? 'Failed to load mess details',
    );
  }

  Future<void> joinMess(String messId, String planName) async {
    final response = await _dioClient
        .post('/membership/join/$messId', data: {'planName': planName});

    if (response.statusCode == 201) {
      return; // Success
    }

    // Throw a specific error message for the UI
    throw response.data['message'] ?? 'Failed to join mess';
  }
}
