// This file is responsible for making the actual API calls for the mess discovery feature.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/mess_discovery/data/models/mess_model.dart';

abstract class MessRemoteDataSource {
  Future<List<MessModel>> getNearbyMesses(
      double lat, double lng, double radius);
  Future<MessModel> getMessDetails(String messId);
}

class MessRemoteDataSourceImpl implements MessRemoteDataSource {
  // Get the singleton instance of our Dio client from the core folder.
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<MessModel>> getNearbyMesses(
      double lat, double lng, double radius) async {
    try {
      // Make the GET request to the '/messes/nearby' endpoint with query parameters.
      final response = await _dio.get(
        '/messes/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      );

      // The response data will be a list of JSON objects.
      // We map over this list and convert each JSON object into a MessModel.
      final List<MessModel> messes = (response.data as List)
          .map((messJson) => MessModel.fromJson(messJson))
          .toList();

      return messes;
    } on DioException catch (e) {
      // Handle Dio-specific errors and throw a more user-friendly exception.
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch nearby messes');
    }
  }

  @override
  Future<MessModel> getMessDetails(String messId) async {
    try {
      // Make the GET request to the '/messes/:messId' endpoint.
      final response = await _dio.get('/messes/$messId');

      // The response data is a single JSON object, which we convert to a MessModel.
      return MessModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch mess details');
    }
  }
}
