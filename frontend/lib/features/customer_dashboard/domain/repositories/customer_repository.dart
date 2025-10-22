// lib/features/customer_dashboard/domain/repositories/customer_repository.dart
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';

abstract class CustomerRepository {
  // Profile
  Future<Map<String, dynamic>> getMyProfile();
  Future<void> updateMyProfile(Map<String, dynamic> body);
  Future<void> updatePin(String pin);

  // Memberships
  Future<List<Membership>> getMyMemberships();
  Future<void> leaveMembership(String membershipId);

  // Menu/Skip/Timings
  Future<Map<String, dynamic>> getTodayMenu(String membershipId);
  Future<void> toggleMealSkip(String membershipId, String mealType);
  Future<Map<String, dynamic>> getMealTimings(String messId);

  // Attendance/Leaves
  Future<List<AttendanceDay>> getAttendance(
      String membershipId, int year, int month);
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate, String reason);

  // Invoices/Payments
  Future<List<Invoice>> getMyInvoices(String membershipId);
  Future<void> notifyPayment(String invoiceId, String screenshotPath);

  // Rating
  Future<void> rateMess(String messId, double rating, String? review);
}
