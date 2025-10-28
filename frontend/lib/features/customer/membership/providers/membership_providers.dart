import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/membership_repository.dart';

// Repo
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

// My memberships
final myMembershipsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(membershipRepositoryProvider).getMyMemberships();
});

// Manager members by status: 'Pending' | 'Active' | 'Inactive'
final messMembersProvider = FutureProvider.family
    .autoDispose<List<dynamic>, String?>((ref, status) async {
  return ref.watch(membershipRepositoryProvider).getMessMembers(status: status);
});
