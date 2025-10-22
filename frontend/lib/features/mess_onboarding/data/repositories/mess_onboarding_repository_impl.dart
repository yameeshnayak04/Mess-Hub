// lib/features/mess_onboarding/data/repositories/mess_onboarding_repository_impl.dart
import 'package:mess_management_system/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';

class MessOnboardingRepositoryImpl implements MessOnboardingRepository {
  final MessOnboardingRemoteDataSource remoteDataSource;
  MessOnboardingRepositoryImpl({required this.remoteDataSource});

  @override
  Future createMess(Map messData) async {
    try {
      await remoteDataSource.createMess(messData);
    } catch (_) {
      rethrow;
    }
  }
}
