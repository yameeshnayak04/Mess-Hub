// lib/features/mess_onboarding/data/repositories/mess_onboarding_repository_impl.dart

import 'package:mess_management_system/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';

class MessOnboardingRepositoryImpl implements MessOnboardingRepository {
  final MessOnboardingRemoteDataSource remoteDataSource;

  MessOnboardingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> createMess(Map<String, dynamic> messData) async {
    try {
      // Delegate the call directly to the remote data source.
      return await remoteDataSource.createMess(messData);
    } catch (e) {
      // Re-throw any errors to be handled by the presentation layer.
      rethrow;
    }
  }
}
