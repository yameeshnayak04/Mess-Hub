// lib/features/manager_dashboard/data/datasources/manager_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/dashboard_stats_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/member_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/member_detail_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/payment_approval_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/mess_profile_model.dart';

class ManagerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<DashboardStatsModel> getDashboardStats(String messId) async {
    try {
      final response = await _dio.get('/manager/messes/$messId/dashboard');
      return DashboardStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch dashboard stats');
    }
  }

  Future<MessProfileModel> getMyMess() async {
    try {
      print('DEBUG: Calling GET /manager/my-mess');
      final response = await _dio.get('/manager/my-mess');
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      final profile = MessProfileModel.fromJson(response.data);
      print('DEBUG: Parsed messId: ${profile.messId}');
      print('DEBUG: Parsed mess name: ${profile.name}');

      return profile;
    } on DioException catch (e) {
      print('DEBUG: DioException occurred');
      print('DEBUG: Status code: ${e.response?.statusCode}');
      print('DEBUG: Error message: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch your mess');
    } catch (e) {
      print('DEBUG: Other exception: $e');
      throw Exception('Failed to parse mess data: $e');
    }
  }

  Future<List<MemberModel>> getMembers(String messId) async {
    try {
      final response = await _dio.get('/manager/messes/$messId/memberships');
      final List membershipsJson = response.data;
      return membershipsJson.map((json) => MemberModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch members');
    }
  }

  Future<MemberDetailModel> getMemberDetail(String membershipId) async {
    try {
      final response =
          await _dio.get('/manager/memberships/$membershipId/detail');
      return MemberDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch member details');
    }
  }

  Future<List<PaymentApprovalModel>> getPaymentApprovals(String messId) async {
    try {
      final response =
          await _dio.get('/manager/messes/$messId/invoices', queryParameters: {
        'status': 'pending',
      });
      final List invoicesJson = response.data;
      return invoicesJson
          .map((json) => PaymentApprovalModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch payment approvals');
    }
  }

  Future<void> approvePayment(String invoiceId) async {
    try {
      await _dio.patch('/manager/invoices/$invoiceId/approve');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to approve payment');
    }
  }

  Future<void> rejectPayment(String invoiceId) async {
    try {
      await _dio.patch('/manager/invoices/$invoiceId/reject');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to reject payment');
    }
  }

  Future<MessProfileModel> getMessProfile(String messId) async {
    try {
      final response = await _dio.get('/manager/messes/$messId');
      return MessProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch mess profile');
    }
  }

  Future<void> uploadTodayMenu(
      String messId, Map<String, dynamic> menuData) async {
    try {
      await _dio.post('/manager/messes/$messId/menu/today', data: menuData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload menu');
    }
  }

  Future<String> downloadInvoice(String invoiceId) async {
    try {
      final response = await _dio.get('/manager/invoices/$invoiceId/pdf',
          options: Options(responseType: ResponseType.bytes));
      // In production, save to device and return file path
      // For now, return success message
      return 'Invoice downloaded successfully';
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to download invoice');
    }
  }
}
