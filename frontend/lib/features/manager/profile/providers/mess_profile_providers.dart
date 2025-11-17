// lib/features/manager/profile/providers/mess_profile_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/mess_profile_repository.dart';

final messProfileRepositoryProvider = Provider((ref) {
  return MessProfileRepository(ref.watch(dioClientProvider));
});

final messProfileProvider = FutureProvider((ref) async {
  final repo = ref.watch(messProfileRepositoryProvider);
  return repo.getMyMess();
});

// Command provider: immediate update (no scheduling)
final messProfileUpdaterProvider = Provider<
    Future<Map<String, dynamic>> Function(Map<String, dynamic>,
        {MultipartFile? image})>((ref) {
  final repo = ref.read(messProfileRepositoryProvider);
  return (fields, {image}) =>
      repo.updateMyMess(fields: fields, imageFile: image);
});
