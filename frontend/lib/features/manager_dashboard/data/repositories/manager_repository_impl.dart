// lib/features/manager_dashboard/data/repositories/manager_repository_impl.dart
import '../../data/datasources/manager_remote_datasource.dart';
import '../../domain/repositories/manager_repository.dart';

class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerRemoteDataSource remote;
  ManagerRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> getDashboardStats() =>
      remote.getDashboardStats();

  @override
  Future<List<dynamic>> getMembers() => remote.getMembers();

  @override
  Future<List<dynamic>> getPaymentApprovals() => remote.getPaymentApprovals();

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status,
          {String? rejectionReason}) =>
      remote.updateInvoiceStatus(invoiceId, status,
          rejectionReason: rejectionReason);

  @override
  Future<List<dynamic>> getTodayOnLeave() => remote.getTodayOnLeave();

  @override
  Future<List<dynamic>> getTodayAttendance({String mealType = 'All'}) =>
      remote.getTodayAttendance(mealType: mealType);

  @override
  Future<Map<String, dynamic>> getMemberDetail(String membershipId,
          {required int year, required int month}) =>
      remote.getMemberDetail(membershipId, year: year, month: month);

  @override
  Future<void> runBilling({required int year, required int month}) =>
      remote.runBilling(year: year, month: month);

  @override
  Future<Map<String, dynamic>> getMessProfile() => remote.getMessProfile();

  @override
  Future<Map<String, dynamic>> updateMessProfile(Map<String, dynamic> body) =>
      remote.updateMessProfile(body);

  @override
  Future<Map<String, dynamic>?> getDailyMenu(DateTime date) =>
      remote.getDailyMenu(date);

  @override
  Future<Map<String, dynamic>> updateDailyMenu(DateTime date,
          {String? lunch,
          String? dinner,
          String? lunchImage,
          String? dinnerImage}) =>
      remote.updateDailyMenu(date,
          lunch: lunch,
          dinner: dinner,
          lunchImage: lunchImage,
          dinnerImage: dinnerImage);
}
