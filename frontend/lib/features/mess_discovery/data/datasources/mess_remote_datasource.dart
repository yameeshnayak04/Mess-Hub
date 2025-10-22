// lib/features/mess_discovery/data/datasources/mess_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/mess_discovery/data/models/mess_model.dart';

abstract class MessRemoteDataSource {
  Future<List<MessModel>> getNearbyMesses(
      {required double lat,
      required double lng,
      double radius = 10.0,
      String? filter});
  Future<MessModel> getMessDetails(String messId);
  Future<void> joinMess(String messId, String mealPlanId);
}

class MessRemoteDataSourceImpl implements MessRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<MessModel>> getNearbyMesses(
      {required double lat,
      required double lng,
      double radius = 10.0,
      String? filter}) async {
    try {
      final q = {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (filter != null && filter.trim().isNotEmpty) 'filter': filter.trim(),
      };
      final res = await _dio.get('/messes/nearby', queryParameters: q);
      final list = (res.data as List? ?? []);
      return list
          .map((j) => MessModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch nearby messes');
    }
  }

  @override
  Future<MessModel> getMessDetails(String messId) async {
    try {
      final res = await _dio.get('/messes/$messId');
      return MessModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch mess details');
    }
  }

  @override
  Future<void> joinMess(String messId, String mealPlanId) async {
    try {
      await _dio.post('/customers/memberships',
          data: {'messId': messId, 'mealPlanId': mealPlanId});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to join mess');
    }
  }
}
