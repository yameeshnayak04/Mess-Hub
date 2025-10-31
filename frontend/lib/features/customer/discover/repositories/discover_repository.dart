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

    try {
      final response =
          await _dioClient.get('/mess/discover', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data?['data'] is List) {
        final data = response.data['data'] as List;
        return data.map((json) => Mess.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data?['message'] ?? 'Failed to load messes',
      );
    } on DioException catch (e) {
      final backendMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'])
          : null;
      throw backendMessage ?? e.message ?? 'An unknown network error occurred';
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<Mess> getMessById(String messId) async {
    try {
      final response = await _dioClient.get('/mess/$messId');
      if (response.statusCode == 200 && response.data?['data'] is Map) {
        return Mess.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data?['message'] ?? 'Failed to load mess details',
      );
    } on DioException catch (e) {
      final backendMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'])
          : null;
      throw backendMessage ?? e.message ?? 'An unknown network error occurred';
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> joinMess(String messId, String planName) async {
    try {
      final response = await _dioClient
          .post('/membership/join/$messId', data: {'planName': planName});

      if (response.statusCode == 201) {
        // Return the created membership data on success
        return response.data['data'] as Map<String, dynamic>;
      }
      // Throw backend error message if available
      throw response.data?['message'] ??
          'Failed to join mess (Status: ${response.statusCode})';
    } on DioException catch (e) {
      final backendMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'])
          : null;
      throw backendMessage ?? e.message ?? 'An unknown network error occurred';
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }
}
