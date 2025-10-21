// lib/features/customer_dashboard/data/repositories/customer_repository_impl.dart

import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Membership>> getMyMemberships() =>
      remoteDataSource.getMyMemberships();

  @override
  Future<Map<String, dynamic>> getTodayMenu(String membershipId) =>
      remoteDataSource.getTodayMenu(membershipId);

  @override
  Future<void> toggleMealSkip(String membershipId, String mealType) =>
      remoteDataSource.toggleMealSkip(membershipId, mealType);

  @override
  Future<List<AttendanceDay>> getAttendance(
          String membershipId, int year, int month) =>
      remoteDataSource.getAttendance(membershipId, year, month);

  @override
  Future<void> markLeave(String membershipId, DateTime startDate,
          DateTime endDate, String reason) =>
      remoteDataSource.markLeave(membershipId, startDate, endDate, reason);

  @override
  Future<List<Invoice>> getMyInvoices(String membershipId) =>
      remoteDataSource.getMyInvoices(membershipId);

  @override
  Future<void> notifyPayment(String invoiceId, String screenshotPath) =>
      remoteDataSource.notifyPayment(invoiceId, screenshotPath);

  @override
  Future<void> rateMess(String messId, double rating, String? review) =>
      remoteDataSource.rateMesss(messId, rating, review);

  @override
  Future<void> leaveMembership(String membershipId) =>
      remoteDataSource.leaveMembership(membershipId);

  @override
  Future<Map<String, dynamic>> getMealTimings(String messId) =>
      remoteDataSource.getMealTimings(messId);
}
