// lib/features/customer/home/providers/membership_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/membership.dart';
import '../../../../models/mess.dart';
import '../../discover/repositories/discover_repository.dart';
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

final _messLookupRepositoryProvider = Provider((ref) {
  return DiscoverRepository(ref.watch(dioClientProvider));
});

/// A membership plus the mess it belongs to.
///
/// The membership payload carries only `messId`/`messName` now - it does not
/// embed the whole mess - but the home card needs the mess's meal timings and
/// rating, so we fetch them alongside.
class MembershipWithMess {
  final Membership membership;
  final Mess? mess;

  const MembershipWithMess({required this.membership, this.mess});

  /// The plan's CURRENT price, straight from the last fetch. Deliberately not
  /// cached anywhere: a manager can change a plan's rate and it applies to
  /// existing members from their next bill.
  double get rateRupees => membership.rateRupees;
}

// Auto-dispose to prevent stale data when customer shell is not visible
final membershipProvider = StateNotifierProvider.autoDispose<MembershipNotifier,
    AsyncValue<List<MembershipWithMess>>>((ref) {
  return MembershipNotifier(
    ref.watch(membershipRepositoryProvider),
    ref.watch(_messLookupRepositoryProvider),
  );
});

class MembershipNotifier
    extends StateNotifier<AsyncValue<List<MembershipWithMess>>> {
  final MembershipRepository _repository;
  final DiscoverRepository _messRepository;

  MembershipNotifier(this._repository, this._messRepository)
      : super(const AsyncValue.loading()) {
    loadMemberships();
  }

  Future<void> loadMemberships() async {
    state = const AsyncValue.loading();
    try {
      final memberships = await _repository.getMyMemberships();

      // Fetch each mess in parallel. A failure here is not fatal - the card
      // still renders from the membership alone, just without timings.
      final loaded = await Future.wait(memberships.map((membership) async {
        try {
          final mess = await _messRepository.getMessById(membership.messId);
          return MembershipWithMess(membership: membership, mess: mess);
        } catch (_) {
          return MembershipWithMess(membership: membership);
        }
      }));

      state = AsyncValue.data(loaded);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadMemberships();

  Future<void> leave(String membershipId) async {
    await _repository.leaveMembership(membershipId);
    await loadMemberships();
  }
}
