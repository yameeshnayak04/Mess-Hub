// lib/features/customer_dashboard/data/datasources/customer_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/membership_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/invoice_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/attendance_model.dart';

abstract class CustomerRemoteDataSource {
  // Profile
  Future<Map<String, dynamic>> getMyProfile();
  Future<void> updateMyProfile(Map<String, dynamic> body);
  Future<void> updatePin(String newPin);

  // Memberships
  Future<List<Membership>> getMyMemberships();
  Future<void> leaveMembership(String membershipId);

  // Menu, skip, timings
  Future<Map<String, dynamic>> getTodayMenu(String membershipId);
  Future<void> toggleMealSkip(String membershipId, String mealType);
  Future<Map<String, dynamic>> getMealTimings(String messId);

  // Attendance + leaves
  Future<List<AttendanceDay>> getAttendance(
      String membershipId, int year, int month);
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate, String reason);

  // Invoices + payment
  Future<List<Invoice>> getAllMyInvoices();
  Future<void> notifyPayment(String invoiceId, String screenshotPath);

  // Ratings
  Future<void> rateMess(String messId, double rating, String? review);

  // Discovery helpers
  Future<Map<String, dynamic>?> getMenuByMessOnDate(
      String messId, DateTime day);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  // PROFILE
  @override
  Future<Map<String, dynamic>> getMyProfile() async {
    final res = await _dio.get('/customers/me/profile');
    return (res.data as Map).cast<String, dynamic>();
  }

  @override
  Future<void> updateMyProfile(Map<String, dynamic> body) async {
    await _dio.put('/customers/me/profile', data: body);
  }

  @override
  Future<void> updatePin(String newPin) async {
    await _dio.put('/auth/me/pin', data: {'pin': newPin});
  }

  // MEMBERSHIPS
  @override
  Future<List<Membership>> getMyMemberships() async {
    final res = await _dio.get('/customers/me/memberships');
    final list = (res.data as List? ?? []);
    return list
        .map((j) => MembershipModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> leaveMembership(String membershipId) async {
    await _dio.delete('/customers/memberships/$membershipId');
  }

  // MENU/SKIP/TIMINGS
  @override
  Future<Map<String, dynamic>> getTodayMenu(String membershipId) async {
    // Resolve messId from membership, then fetch menu for today
    final mems = await getMyMemberships();
    final mem = mems.firstWhere((m) => m.id == membershipId);
    final data = await getMenuByMessOnDate(mem.messId, DateTime.now());
    return data ?? <String, dynamic>{};
  }

  @override
  Future<void> toggleMealSkip(String membershipId, String mealType) async {
    await _dio.post('/customers/memberships/$membershipId/toggle-meal',
        data: {'mealType': mealType});
  }

  @override
  Future<Map<String, dynamic>> getMealTimings(String messId) async {
    final res = await _dio.get('/messes/$messId');
    final data = (res.data as Map).cast<String, dynamic>();
    return (data['timings'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  // ATTENDANCE/LEAVES
  @override
  Future<List<AttendanceDay>> getAttendance(
      String membershipId, int year, int month) async {
    // Expected route: GET /customers/memberships/:membershipId/attendance?year&month
    final res = await _dio.get(
      '/customers/memberships/$membershipId/attendance',
      queryParameters: {'year': year, 'month': month},
    );
    final mems = await getMyMemberships();
    final plan = mems.firstWhere((m) => m.id == membershipId).mealPlan;
    final list = (res.data as List? ?? []);
    return list
        .map((j) => AttendanceModel.fromJson(j as Map<String, dynamic>, plan))
        .toList();
  }

  @override
  Future<void> markLeave(String membershipId, DateTime startDate,
      DateTime endDate, String reason) async {
    await _dio.post('/customers/memberships/$membershipId/leaves', data: {
      'startDate': DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String(),
      'endDate':
          DateTime(endDate.year, endDate.month, endDate.day).toIso8601String(),
      'reason': reason,
    });
  }

  // INVOICES/PAYMENTS
  @override
  Future<List<Invoice>> getAllMyInvoices() async {
    final res = await _dio.get('/customers/me/invoices');
    final list = (res.data as List? ?? []);
    return list
        .map((j) => InvoiceModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> notifyPayment(String invoiceId, String screenshotPath) async {
    final form = FormData.fromMap({
      'paymentScreenshot': await MultipartFile.fromFile(
        screenshotPath,
        filename: screenshotPath.split('/').last,
      ),
    });
    await _dio.post('/customers/invoices/$invoiceId/notify-payment',
        data: form);
  }

  // RATINGS
  @override
  Future<void> rateMess(String messId, double rating, String? review) async {
    await _dio.post('/customers/messes/$messId/rate', data: {
      'rating': rating,
      if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
    });
  }

  // DISCOVERY HELPERS
  @override
  Future<Map<String, dynamic>?> getMenuByMessOnDate(
      String messId, DateTime day) async {
    final date = DateTime(day.year, day.month, day.day).toIso8601String();
    final res =
        await _dio.get('/messes/$messId/menu', queryParameters: {'date': date});
    return (res.data as Map?)?.cast<String, dynamic>();
  }
}
