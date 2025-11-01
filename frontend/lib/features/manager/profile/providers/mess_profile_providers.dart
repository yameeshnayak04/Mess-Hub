// lib/features/manager/profile/providers/mess_profile_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/mess_profile_repository.dart';
import '../../../auth/providers/auth_provider.dart';

final messProfileRepositoryProvider = Provider((ref) {
  return MessProfileRepository(ref.watch(dioClientProvider));
});

final messProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(messProfileRepositoryProvider).getMyMess();
}); // reads current + auto-applied scheduled changes [attached_file:2]

final messProfileUpdaterProvider = Provider((ref) {
  return (Map<String, dynamic> fields, {MultipartFile? image}) async {
    final repo = ref.read(messProfileRepositoryProvider);
    final result = await repo.scheduleUpdate(fields: fields, imageFile: image);
    ref.invalidate(messProfileProvider);
    return result;
  };
});

// Simple logout action that clears auth and lets router redirect to login
final managerLogoutProvider = Provider((ref) {
  return () => ref.read(authProvider.notifier).logout();
}); // app_router watches authProvider for redirects [attached_file:54]
