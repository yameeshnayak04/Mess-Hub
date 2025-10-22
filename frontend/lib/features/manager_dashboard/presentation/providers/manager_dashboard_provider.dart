// lib/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/manager_remote_datasource.dart';
import '../../data/repositories/manager_repository_impl.dart';
import '../../domain/repositories/manager_repository.dart';

// Repository provider
final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  return ManagerRepositoryImpl(ManagerRemoteDataSourceImpl());
});

// Dashboard stats
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.getDashboardStats();
});

// Contributors on card taps
final dashboardContributorsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, type) async {
  final repo = ref.read(managerRepositoryProvider);
  switch (type) {
    case 'onLeave':
      return await repo.getTodayOnLeave();
    case 'attendance:Lunch':
      return await repo.getTodayAttendance(mealType: 'Lunch');
    case 'attendance:Dinner':
      return await repo.getTodayAttendance(mealType: 'Dinner');
    case 'approvals':
      return await repo.getPaymentApprovals();
    default:
      return [];
  }
});

// Members list
final membersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.getMembers();
});

// Member detail for selected month/year
final memberDetailProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, args) async {
  final repo = ref.read(managerRepositoryProvider);
  final membershipId = args['membershipId'] as String;
  final year = args['year'] as int;
  final month = args['month'] as int;
  return await repo.getMemberDetail(membershipId, year: year, month: month);
});

// Billing run
final runBillingProvider =
    FutureProvider.family<void, Map<String, int>>((ref, ym) async {
  final repo = ref.read(managerRepositoryProvider);
  await repo.runBilling(year: ym['year']!, month: ym['month']!);
});

// Invoice status update (approve/reject)
final updateInvoiceStatusProvider =
    FutureProvider.family<void, Map<String, String?>>((ref, args) async {
  final repo = ref.read(managerRepositoryProvider);
  await repo.updateInvoiceStatus(args['invoiceId']!, args['status']!,
      rejectionReason: args['rejectionReason']);
});

// Mess profile
final messProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.getMessProfile();
});

final updateMessProfileProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, body) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.updateMessProfile(body);
});

// Daily menu (per date)
final dailyMenuProvider =
    FutureProvider.family<Map<String, dynamic>?, DateTime>((ref, date) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.getDailyMenu(date);
});

final updateDailyMenuProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, args) async {
  final repo = ref.read(managerRepositoryProvider);
  return await repo.updateDailyMenu(
    args['date'] as DateTime,
    lunch: args['lunch'] as String?,
    dinner: args['dinner'] as String?,
    lunchImage: args['lunchImage'] as String?,
    dinnerImage: args['dinnerImage'] as String?,
  );
});
