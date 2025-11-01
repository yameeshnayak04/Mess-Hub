// lib/features/manager/billing/providers/manager_payments_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/manager_payments_repository.dart';

// Repo
final managerPaymentsRepositoryProvider =
    Provider<ManagerPaymentsRepository>((ref) {
  return ManagerPaymentsRepository(ref.watch(dioClientProvider));
});

// Pending approvals list
final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(managerPaymentsRepositoryProvider).getPendingApprovals();
});

// Payment history filters (unchanged value semantics)
class PaymentsHistoryFilter {
  final String? status;
  final int? month;
  final int? year;
  final String? query;
  final int page;
  final int limit;
  const PaymentsHistoryFilter(
      {this.status,
      this.month,
      this.year,
      this.query,
      this.page = 1,
      this.limit = 20});
  // copyWith, ==, hashCode unchanged
}

// History provider
final paymentsHistoryProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, PaymentsHistoryFilter>(
        (ref, filter) async {
  return ref.watch(managerPaymentsRepositoryProvider).getAllBills(
        status: filter.status,
        month: filter.month,
        year: filter.year,
        memberNameOrPhone: filter.query,
        page: filter.page,
        limit: filter.limit,
      );
});
