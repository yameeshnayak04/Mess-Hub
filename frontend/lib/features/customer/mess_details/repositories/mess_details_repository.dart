// lib/features/customer/mess_details/repositories/mess_details_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';
import '../../../../models/review.dart'; // Assuming you have Review model in models folder

class MessDetailsRepository {
  final DioClient _dioClient;
  MessDetailsRepository(this._dioClient);

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

  Future<List<Review>> getReviews(String messId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await _dioClient.get(
        '/reviews/$messId',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200 && response.data?['data'] is List) {
        final data = response.data['data'] as List;
        return data.map((json) => Review.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data?['message'] ?? 'Failed to load reviews',
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
