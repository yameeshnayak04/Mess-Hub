import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../repositories/mess_details_repository.dart';

final messDetailsRepositoryProvider = Provider<MessDetailsRepository>((ref) {
  return MessDetailsRepository(ref.watch(dioClientProvider));
});

final messDetailsProvider =
    FutureProvider.family<Mess, String>((ref, messId) async {
  final repository = ref.watch(messDetailsRepositoryProvider);
  return await repository.getMessDetails(messId);
});
