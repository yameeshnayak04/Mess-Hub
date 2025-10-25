import '../../../../core/api/dio_client.dart';
import '../../../../models/dashboard_stats.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  Future<DashboardStats> getDashboardStats() async {
    final response = await _dioClient.get('/mess/my-mess/dashboard');
    return DashboardStats.fromJson(response.data['data']);
  }

  Future<List<dynamic>> getMembersEating() async {
    final response = await _dioClient.get('/mess/dashboard/members-eating');
    return response.data['data'] as List;
  }

  Future<List<dynamic>> getMembersOnLeave() async {
    final response = await _dioClient.get('/mess/dashboard/members-on-leave');
    return response.data['data'] as List;
  }

  Future<List<dynamic>> getMembersSkipped() async {
    final response = await _dioClient.get('/mess/dashboard/members-skipped');
    return response.data['data'] as List;
  }
}
