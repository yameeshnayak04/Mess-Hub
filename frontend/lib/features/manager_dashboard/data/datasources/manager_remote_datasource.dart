// lib/features/manager_dashboard/data/datasources/manager_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';

abstract class ManagerRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<dynamic>> getMembers();
  Future<List<dynamic>> getPaymentApprovals();
  Future<void> updateInvoiceStatus(String invoiceId, String status,
      {String? rejectionReason});
  Future<List<dynamic>> getTodayOnLeave();
  Future<List<dynamic>> getTodayAttendance({String mealType = 'All'});
  Future<Map<String, dynamic>> getMemberDetail(String membershipId,
      {required int year, required int month});
  Future<void> runBilling({required int year, required int month});
  Future<Map<String, dynamic>> getMessProfile();
  Future<Map<String, dynamic>> updateMessProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>?> getDailyMenu(DateTime date);
  Future<Map<String, dynamic>> updateDailyMenu(DateTime date,
      {String? lunch, String? dinner, String? lunchImage, String? dinnerImage});
}

class ManagerRemoteDataSourceImpl implements ManagerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/manager/my-mess/dashboard-stats');
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getMembers() async {
    final res = await _dio.get('/manager/my-mess/members');
    return res.data as List<dynamic>;
  }

  @override
  Future<List<dynamic>> getPaymentApprovals() async {
    final res = await _dio.get('/manager/my-mess/payment-approvals');
    return res.data as List<dynamic>;
  }

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status,
      {String? rejectionReason}) async {
    await _dio.put('/manager/my-mess/invoices/$invoiceId/status', data: {
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  @override
  Future<List<dynamic>> getTodayOnLeave() async {
    final res = await _dio.get('/manager/my-mess/leaves/today');
    return res.data as List<dynamic>;
  }

  @override
  Future<List<dynamic>> getTodayAttendance({String mealType = 'All'}) async {
    final res =
        await _dio.get('/manager/my-mess/attendance/today', queryParameters: {
      if (mealType != 'All') 'mealType': mealType,
    });
    return res.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getMemberDetail(String membershipId,
      {required int year, required int month}) async {
    final res = await _dio
        .get('/manager/my-mess/members/$membershipId/detail', queryParameters: {
      'year': year,
      'month': month,
    });
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<void> runBilling({required int year, required int month}) async {
    await _dio.post('/manager/my-mess/billing/run',
        data: {'year': year, 'month': month});
  }

  @override
  Future<Map<String, dynamic>> getMessProfile() async {
    final res = await _dio.get('/manager/my-mess');
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateMessProfile(
      Map<String, dynamic> body) async {
    final res = await _dio.put('/manager/my-mess', data: body);
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> getDailyMenu(DateTime date) async {
    final yyyyMmDd =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final mess = await getMessProfile();
    final id = mess['_id'];
    final res =
        await _dio.get('/messes/$id/menu', queryParameters: {'date': yyyyMmDd});
    return res.data as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>> updateDailyMenu(DateTime date,
      {String? lunch,
      String? dinner,
      String? lunchImage,
      String? dinnerImage}) async {
    final yyyyMmDd =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final mess = await getMessProfile();
    final id = mess['_id'];
    final res = await _dio.put('/messes/$id/menu', data: {
      'date': yyyyMmDd,
      if (lunch != null) 'lunch': lunch,
      if (dinner != null) 'dinner': dinner,
      if (lunchImage != null) 'lunchImage': lunchImage,
      if (dinnerImage != null) 'dinnerImage': dinnerImage,
    });
    return res.data as Map<String, dynamic>;
  }
}
