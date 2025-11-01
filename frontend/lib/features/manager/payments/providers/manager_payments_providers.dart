// lib/features/manager/billing/providers/manager_payments_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/manager_payments_repository.dart';

// Repository
final managerPaymentsRepositoryProvider =
    Provider<ManagerPaymentsRepository>((ref) {
  return ManagerPaymentsRepository(ref.watch(dioClientProvider));
});

// Pending approvals
final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  return ref.watch(managerPaymentsRepositoryProvider).getPendingApprovals();
});

// Dues
final dueBillsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  return ref.watch(managerPaymentsRepositoryProvider).getDueBills();
});

// Filter model with copyWith
class PaymentsHistoryFilter {
  final String? status; // 'Paid' | 'Pending Approval' | 'Due'
  final int? month; // 1-12
  final int? year; // yyyy
  final String? query; // name/phone
  final int page; // default 1
  final int limit; // default 20

  const PaymentsHistoryFilter({
    this.status,
    this.month,
    this.year,
    this.query,
    this.page = 1,
    this.limit = 20,
  });

  PaymentsHistoryFilter copyWith({
    String? status,
    int? month,
    int? year,
    String? query,
    int? page,
    int? limit,
  }) {
    return PaymentsHistoryFilter(
      status: status ?? this.status,
      month: month ?? this.month,
      year: year ?? this.year,
      query: query ?? this.query,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentsHistoryFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          month == other.month &&
          year == other.year &&
          query == other.query &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      (status ?? '').hashCode ^
      (month ?? 0).hashCode ^
      (year ?? 0).hashCode ^
      (query ?? '').hashCode ^
      page.hashCode ^
      limit.hashCode;
}

// Payment history (stable family provider)
final paymentsHistoryProvider = FutureProvider.family
    .autoDispose<List<dynamic>, PaymentsHistoryFilter>((ref, filter) async {
  ref.keepAlive();
  return ref.watch(managerPaymentsRepositoryProvider).getAllBills(
        status: filter.status,
        month: filter.month,
        year: filter.year,
        memberNameOrPhone: filter.query,
        page: filter.page,
        limit: filter.limit,
      );
});
