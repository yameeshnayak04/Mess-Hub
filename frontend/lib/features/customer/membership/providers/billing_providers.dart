import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.watch(dioClientProvider));
});

final myBillsProvider = FutureProvider.family
    .autoDispose<List<dynamic>, String>((ref, membershipId) async {
  return ref.watch(billingRepositoryProvider).getMyBills(membershipId);
});

final pendingPaymentApprovalsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(billingRepositoryProvider).getPendingApprovals();
});
