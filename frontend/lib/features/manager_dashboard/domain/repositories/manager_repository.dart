// lib/features/manager_dashboard/domain/repositories/manager_repository.dart
abstract class ManagerRepository {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<dynamic>> getMembers();
  Future<List<dynamic>> getPaymentApprovals();
  Future<void> updateInvoiceStatus(String invoiceId, String status,
      {String? rejectionReason});
  Future<List<dynamic>> getTodayOnLeave();
  Future<List<dynamic>> getTodayAttendance({String mealType = 'All'});
  Future<Map<String, dynamic>> getMemberDetail(String membershipId,
      {required int year, required int month});
  Future<void> runBilling({required int year, required int month});
  Future<Map<String, dynamic>> getMessProfile();
  Future<Map<String, dynamic>> updateMessProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>?> getDailyMenu(DateTime date);
  Future<Map<String, dynamic>> updateDailyMenu(DateTime date,
      {String? lunch, String? dinner, String? lunchImage, String? dinnerImage});
}
