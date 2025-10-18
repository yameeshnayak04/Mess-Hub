// lib/features/manager_dashboard/data/repositories/manager_repository_impl.dart
import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/manager_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/today_attendance_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerRemoteDataSource remote;
  ManagerRepositoryImpl(this.remote);

  @override
  Future<DashboardStats> getDashboardStats() => remote.getDashboardStats();

  @override
  Future<List<ManagerMember>> getMessMembers() => remote.getMessMembers();

  @override
  Future<WeeklyMenu> getWeeklyMenu() => remote.getWeeklyMenu();

  @override
  Future<List<Invoice>> getPaymentApprovals() => remote.getPaymentApprovals();

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status,
          {String? reason}) =>
      remote.updateInvoiceStatus(invoiceId, status, reason: reason);

  @override
  Future<MessProfile> getMyMessProfile() => remote.getMyMessProfile();

  @override
  Future<void> updateMyMess(
          {String? name, String? managerContact, String? address}) =>
      remote.updateMyMess(
          name: name, managerContact: managerContact, address: address);

  @override
  Future<List<TodayAttendanceMember>> getTodayAttendance() =>
      remote.getTodayAttendance();

  @override
  Future<void> logMonthlyMealWithPin(
          String customerId, String managerPin, String mealType) =>
      remote.logMonthlyMealWithPin(customerId, managerPin, mealType);

  @override
  Future<void> logDailyMeal(String mealType) => remote.logDailyMeal(mealType);

  @override
  Future<Map<DateTime, bool>> getMemberAttendance(
          String memberId, int year, int month) =>
      remote.getMemberAttendance(memberId, year, month);

  @override
  Future<List<Invoice>> getMemberInvoices(String memberId) =>
      remote.getMemberInvoices(memberId);
}
