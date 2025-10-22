// lib/features/customer_dashboard/data/repositories/customer_repository_impl.dart
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remote;
  CustomerRepositoryImpl({required this.remote});

  // Profile
  @override
  Future<Map<String, dynamic>> getMyProfile() => remote.getMyProfile();
  @override
  Future<void> updateMyProfile(Map<String, dynamic> body) =>
      remote.updateMyProfile(body);
  @override
  Future<void> updatePin(String pin) => remote.updatePin(pin);

  // Memberships
  @override
  Future<List<Membership>> getMyMemberships() => remote.getMyMemberships();
  @override
  Future<void> leaveMembership(String membershipId) =>
      remote.leaveMembership(membershipId);

  // Menu/Skip/Timings
  @override
  Future<Map<String, dynamic>> getTodayMenu(String membershipId) =>
      remote.getTodayMenu(membershipId);
  @override
  Future<void> toggleMealSkip(String membershipId, String mealType) =>
      remote.toggleMealSkip(membershipId, mealType);
  @override
  Future<Map<String, dynamic>> getMealTimings(String messId) =>
      remote.getMealTimings(messId);

  // Attendance/Leaves
  @override
  Future<List<AttendanceDay>> getAttendance(
          String membershipId, int year, int month) =>
      remote.getAttendance(membershipId, year, month);
  @override
  Future<void> markLeave(String membershipId, DateTime startDate,
          DateTime endDate, String reason) =>
      remote.markLeave(membershipId, startDate, endDate, reason);

  // Invoices/Payments
  @override
  Future<List<Invoice>> getMyInvoices(String membershipId) async {
    final all = await remote.getAllMyInvoices();
    return all.where((i) => i.membershipId == membershipId).toList();
  }

  @override
  Future<void> notifyPayment(String invoiceId, String screenshotPath) =>
      remote.notifyPayment(invoiceId, screenshotPath);

  // Rating
  @override
  Future<void> rateMess(String messId, double rating, String? review) =>
      remote.rateMess(messId, rating, review);
}
