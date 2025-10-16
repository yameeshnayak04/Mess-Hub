// lib/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart

// This abstract class defines the contract for the mess onboarding feature.
abstract class MessOnboardingRepository {
  // The contract for creating a new mess.
  // It takes a map of all the form data and sends it to the backend.
  // It returns void upon success or throws an error on failure.
  Future<void> createMess(Map<String, dynamic> messData);
}
