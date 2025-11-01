// lib/features/manager/kiosk/providers/kiosk_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/kiosk_repository.dart';

final kioskRepositoryProvider = Provider<KioskRepository>((ref) {
  return KioskRepository(ref.watch(dioClientProvider));
});

final kioskMessProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  return ref.watch(kioskRepositoryProvider).getMyMess();
});

final kioskActiveMembersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(kioskRepositoryProvider).getActiveMembers();
});

final kioskMembersEatingProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(kioskRepositoryProvider).getMembersEatingNow();
});

final kioskMembersOnLeaveProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(kioskRepositoryProvider).getMembersOnLeave();
});

final kioskMembersSkippedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(kioskRepositoryProvider).getMembersSkipped();
});
