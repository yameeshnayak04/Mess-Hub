// lib/features/customer/membership/providers/membership_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/membership_details.dart';
import '../../../../models/mess.dart';
import '../../discover/repositories/discover_repository.dart';
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

final membershipDetailsProvider = FutureProvider.family
    .autoDispose<MembershipDetails, String>((ref, membershipId) async {
  return ref
      .watch(membershipRepositoryProvider)
      .getMembershipDetails(membershipId);
});

/// The membership detail payload no longer embeds the whole mess, so screens
/// that need the mess's name, timings or contact number fetch it by id.
final messByIdProvider =
    FutureProvider.family.autoDispose<Mess, String>((ref, messId) async {
  return DiscoverRepository(ref.watch(dioClientProvider)).getMessById(messId);
});
