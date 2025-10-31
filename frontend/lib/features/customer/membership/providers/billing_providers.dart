// lib/features/billing/providers/billing_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/billing_repository.dart';

final billingRepositoryProvider = Provider((ref) {
  return BillingRepository(ref.watch(dioClientProvider));
});

final myBillsProvider = FutureProvider.family
    .autoDispose<List<dynamic>, String>((ref, membershipId) async {
  return ref.watch(billingRepositoryProvider).getMyBills(membershipId);
});
