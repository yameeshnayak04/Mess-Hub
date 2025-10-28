import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/membership.dart';
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

final myMembershipsProvider = FutureProvider<List<Membership>>((ref) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return await repository.getMyMemberships();
});

final membershipProvider =
    StateNotifierProvider<MembershipNotifier, AsyncValue<List<Membership>>>(
        (ref) {
  return MembershipNotifier(ref.watch(membershipRepositoryProvider));
});

class MembershipNotifier extends StateNotifier<AsyncValue<List<Membership>>> {
  final MembershipRepository _repository;
  MembershipNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMemberships();
  }

  Future<void> loadMemberships() async {
    state = const AsyncValue.loading();
    try {
      final memberships = await _repository.getMyMemberships();
      state = AsyncValue.data(memberships);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() => loadMemberships();
}
