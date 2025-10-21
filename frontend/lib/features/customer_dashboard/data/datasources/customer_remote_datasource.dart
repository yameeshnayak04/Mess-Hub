// lib/features/customer_dashboard/data/datasources/customer_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/membership_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/invoice_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/attendance_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<MembershipModel>> getMyMemberships();
  Future<Map<String, dynamic>> getTodayMenu(String membershipId);
  Future<void> toggleMealSkip(String membershipId, String mealType);
  Future<List<AttendanceModel>> getAttendance(
      String membershipId, int year, int month);
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate, String reason);
  Future<List<InvoiceModel>> getMyInvoices(String membershipId);
  Future<void> notifyPayment(String invoiceId, String screenshotPath);
  Future<void> rateMesss(String messId, double rating, String? review);
  Future<void> leaveMembership(String membershipId);
  Future<Map<String, dynamic>> getMealTimings(String messId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<MembershipModel>> getMyMemberships() async {
    try {
      print('🔍 DEBUG: Calling GET /customer/my-memberships');
      final response = await _dio.get('/customer/my-memberships');
      print('✅ DEBUG: Got response: ${response.statusCode}');

      final List memberships = response.data as List;
      return memberships
          .map((json) => MembershipModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ DEBUG: DioException occurred');
      print('❌ DEBUG: Status code: ${e.response?.statusCode}');
      print('❌ DEBUG: Error message: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch memberships');
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayMenu(String membershipId) async {
    try {
      final response =
          await _dio.get('/customer/memberships/$membershipId/today-menu');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch today\'s menu');
    }
  }

  @override
  Future<void> toggleMealSkip(String membershipId, String mealType) async {
    try {
      print('🔍 DEBUG: Toggling meal skip for $mealType');
      await _dio.post('/customer/memberships/$membershipId/toggle-skip', data: {
        'mealType': mealType,
      });
      print('✅ DEBUG: Meal skip toggled successfully');
    } on DioException catch (e) {
      print('❌ DEBUG: Error toggling meal skip: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to toggle meal skip');
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendance(
      String membershipId, int year, int month) async {
    try {
      print('🔍 DEBUG: Fetching attendance for $year-$month');
      final response = await _dio.get(
        '/customer/memberships/$membershipId/attendance',
        queryParameters: {'year': year, 'month': month},
      );

      // Get membership details to know the meal plan
      final membershipResponse = await _dio.get('/customer/my-memberships');
      final memberships = membershipResponse.data as List;
      final membership = memberships.firstWhere(
        (m) => m['_id'] == membershipId,
        orElse: () => {'mealPlan': 'Lunch'},
      );
      final mealPlan = membership['mealPlan'] as String;

      final List attendanceData = response.data as List;
      return attendanceData
          .map((json) =>
              AttendanceModel.fromJson(json as Map<String, dynamic>, mealPlan))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch attendance');
    }
  }

  @override
  Future<void> markLeave(String membershipId, DateTime startDate,
      DateTime endDate, String reason) async {
    try {
      print('🔍 DEBUG: Marking leave from $startDate to $endDate');
      await _dio.post('/customer/memberships/$membershipId/leave', data: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      });
      print('✅ DEBUG: Leave marked successfully');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark leave');
    }
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices(String membershipId) async {
    try {
      final response =
          await _dio.get('/customer/memberships/$membershipId/invoices');
      final List invoices = response.data as List;
      return invoices
          .map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch invoices');
    }
  }

  @override
  Future<void> notifyPayment(String invoiceId, String screenshotPath) async {
    try {
      print('🔍 DEBUG: Notifying payment for invoice $invoiceId');

      // Upload screenshot
      final fileName = screenshotPath.split('/').last;
      final formData = FormData.fromMap({
        'paymentScreenshot': await MultipartFile.fromFile(
          screenshotPath,
          filename: fileName,
        ),
      });

      await _dio.post('/customer/invoices/$invoiceId/notify-payment',
          data: formData);
      print('✅ DEBUG: Payment notified successfully');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to notify payment');
    }
  }

  @override
  Future<void> rateMesss(String messId, double rating, String? review) async {
    try {
      print('🔍 DEBUG: Rating mess with $rating stars');
      await _dio.post('/customer/messes/$messId/rate', data: {
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      });
      print('✅ DEBUG: Mess rated successfully');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to rate mess');
    }
  }

  @override
  Future<void> leaveMembership(String membershipId) async {
    try {
      print('🔍 DEBUG: Leaving membership $membershipId');
      await _dio.delete('/customer/memberships/$membershipId');
      print('✅ DEBUG: Membership left successfully');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to leave membership');
    }
  }

  @override
  Future<Map<String, dynamic>> getMealTimings(String messId) async {
    try {
      final response = await _dio.get('/messes/$messId');
      final mess = response.data as Map<String, dynamic>;
      return mess['timings'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch meal timings');
    }
  }
}
