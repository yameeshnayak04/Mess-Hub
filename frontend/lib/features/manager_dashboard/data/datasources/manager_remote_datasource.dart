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

  // ✅ FIXED: Changed from /manager/messes/:id/dashboard to /manager/my-mess/dashboard-stats
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _dio.get('/manager/my-mess/dashboard-stats');
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

  // ✅ FIXED: Changed from /manager/messes/:id/memberships to /manager/my-mess/members
  Future<List<MemberModel>> getMembers() async {
    try {
      final response = await _dio.get('/manager/my-mess/members');
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

  // ✅ FIXED: Changed from /manager/messes/:id/invoices to /manager/my-mess/payment-approvals
  Future<List<PaymentApprovalModel>> getPaymentApprovals() async {
    try {
      final response = await _dio.get('/manager/my-mess/payment-approvals');
      final List invoicesJson = response.data;
      return invoicesJson
          .map((json) => PaymentApprovalModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch payment approvals');
    }
  }

  // ✅ FIXED: Changed from PATCH to PUT and updated path
  Future<void> approvePayment(String invoiceId) async {
    try {
      await _dio.put('/manager/my-mess/invoices/$invoiceId/status', data: {
        'status': 'approved',
      });
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to approve payment');
    }
  }

  // ✅ FIXED: Changed from PATCH to PUT and updated path
  Future<void> rejectPayment(String invoiceId) async {
    try {
      await _dio.put('/manager/my-mess/invoices/$invoiceId/status', data: {
        'status': 'rejected',
      });
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to reject payment');
    }
  }

  // Note: getMessProfile is redundant with getMyMess - consider removing
  Future<MessProfileModel> getMessProfile() async {
    return getMyMess();
  }

  // ✅ FIXED: Changed path to match backend
  Future<void> uploadTodayMenu(Map<String, dynamic> menuData) async {
    try {
      await _dio.put('/manager/my-mess/menu', data: menuData);
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
