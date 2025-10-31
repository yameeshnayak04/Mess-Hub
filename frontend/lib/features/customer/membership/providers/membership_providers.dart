// lib/features/customer/membership/providers/membership_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

final membershipDetailsProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, membershipId) async {
  return ref
      .watch(membershipRepositoryProvider)
      .getMembershipDetails(membershipId);
});
