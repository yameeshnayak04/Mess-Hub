// lib/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart

// This abstract class defines the contract for the mess onboarding feature.
abstract class MessOnboardingRepository {
  // Create a new mess with a strictly typed payload.
  Future<void> createMess(Map<String, dynamic> messData);
}
