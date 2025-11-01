// lib/features/customer/mess_details/repositories/mess_details_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';
import '../../../../models/review.dart';

class MessDetailsRepository {
  final DioClient _dioClient;
  MessDetailsRepository(this._dioClient);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'];
    return fallback;
  }

  Future<Mess> getMessById(String messId) async {
    try {
      final response = await _dioClient.get('/mess/$messId');
      if (response.statusCode == 200 && response.data?['data'] is Map) {
        return Mess.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _msg(response, 'Failed to load mess details'),
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

  Future<List<Review>> getReviews(String messId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await _dioClient.get('/reviews/$messId',
          queryParameters: {'page': page, 'limit': limit});
      if (response.statusCode == 200 && response.data?['data'] is List) {
        final data = response.data['data'] as List;
        return data
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _msg(response, 'Failed to load reviews'),
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

  // NEW: Menu fetch for a mess with optional date range (aligned to backend)
  Future<List<Map<String, dynamic>>> getMenu({
    required String messId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate.toIso8601String();
      if (endDate != null) query['endDate'] = endDate.toIso8601String();
      final response =
          await _dioClient.get('/menu/$messId', queryParameters: query);
      if (response.statusCode == 200 && response.data?['data'] is List) {
        return (response.data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _msg(response, 'Failed to load menu'),
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
}
