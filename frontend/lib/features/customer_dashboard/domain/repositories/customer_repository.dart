// lib/features/customer_dashboard/domain/repositories/customer_repository.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';

abstract class CustomerRepository {
  Future<List<Membership>> getMyMemberships();
  Future<Map<String, dynamic>> getTodayMenu(String membershipId);
  Future<void> toggleMealSkip(String membershipId, String mealType);
  Future<List<AttendanceDay>> getAttendance(
      String membershipId, int year, int month);
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate, String reason);
  Future<List<Invoice>> getMyInvoices(String membershipId);
  Future<void> notifyPayment(String invoiceId, String screenshotPath);
  Future<void> rateMess(String messId, double rating, String? review);
  Future<void> leaveMembership(String membershipId);
  Future<Map<String, dynamic>> getMealTimings(String messId);
}
