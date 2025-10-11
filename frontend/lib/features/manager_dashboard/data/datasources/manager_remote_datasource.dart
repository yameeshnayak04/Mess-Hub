// This file is responsible for making the actual API calls for the manager dashboard.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/dashboard_stats_model.dart';

abstract class ManagerRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
}

class ManagerRemoteDataSourceImpl implements ManagerRemoteDataSource {
  // Get the singleton instance of our Dio client.
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      // Make the GET request to the protected manager route.
      // The Dio interceptor will automatically add the manager's JWT token.
      final response = await _dio.get('/managers/my-mess/dashboard-stats');

      // The response data is a single JSON object, which we convert to our model.
      return DashboardStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      // Handle Dio-specific errors and throw a more user-friendly exception.
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch dashboard stats');
    }
  }
}
