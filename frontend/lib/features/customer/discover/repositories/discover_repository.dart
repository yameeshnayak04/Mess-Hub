// lib/features/discover/repositories/discover_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';

class DiscoverRepository {
  final DioClient _dioClient;
  DiscoverRepository(this._dioClient);

  String _serverMessage(Response res) {
    final data = res.data;
    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return 'Failed to load messes';
  }

  Future<List<Mess>> discoverMesses({
    String? cuisine,
    String? serviceType,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'page': page,
      'limit': limit,
      if (cuisine != null) 'cuisine': cuisine,
      if (serviceType != null) 'serviceType': serviceType,
      // backend may not support 'search' yet; do client-side filter below
    };

    try {
      final res =
          await _dioClient.get('/mess/discover', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data?['data'] is List) {
        final list =
            (res.data['data'] as List).map((j) => Mess.fromJson(j)).toList();
        if (search == null || search.trim().isEmpty) return list;
        final q = search.toLowerCase();
        return list.where((m) {
          final name = (m.messName).toLowerCase();
          final addr = (m.address).toLowerCase();
          final city = (m.city).toLowerCase();
          final cuisine = (m.cuisine).toLowerCase();
          return name.contains(q) ||
              addr.contains(q) ||
              city.contains(q) ||
              cuisine.contains(q);
        }).toList();
      }
      throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: _serverMessage(res));
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
      final res = await _dioClient.get('/mess/$messId');
      if (res.statusCode == 200 && res.data?['data'] is Map) {
        return Mess.fromJson(res.data['data']);
      }
      throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: _serverMessage(res));
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
      final res = await _dioClient
          .post('/membership/join/$messId', data: {'planName': planName});
      if (res.statusCode == 201 && res.data?['data'] is Map) {
        return res.data['data'] as Map<String, dynamic>;
      }
      throw res.data?['message'] ??
          'Failed to join mess (Status: ${res.statusCode})';
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
