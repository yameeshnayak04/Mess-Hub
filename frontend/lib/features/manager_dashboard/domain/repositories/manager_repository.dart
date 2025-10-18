// lib/features/manager_dashboard/domain/repositories/manager_repository.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/manager_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/today_attendance_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

abstract class ManagerRepository {
  Future<DashboardStats> getDashboardStats();
  Future<List<ManagerMember>> getMessMembers();
  Future<WeeklyMenu> getWeeklyMenu();

  // New
  Future<List<Invoice>> getPaymentApprovals();
  Future<void> updateInvoiceStatus(String invoiceId, String status,
      {String? reason});

  Future<MessProfile> getMyMessProfile();
  Future<void> updateMyMess(
      {String? name, String? managerContact, String? address});

  Future<List<TodayAttendanceMember>> getTodayAttendance();
  Future<void> logMonthlyMealWithPin(
      String customerId, String managerPin, String mealType);
  Future<void> logDailyMeal(String mealType);

  // Optional (per-member detail)
  Future<Map<DateTime, bool>> getMemberAttendance(
      String memberId, int year, int month);
  Future<List<Invoice>> getMemberInvoices(String memberId);
}
