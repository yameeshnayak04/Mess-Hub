// lib/features/mess_onboarding/domain/usecases/create_mess.dart

import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';

// This use case represents the single business action of creating a mess.
// It is now updated with comprehensive validation logic.
class CreateMess {
  final MessOnboardingRepository repository;

  CreateMess(this.repository);

  // The 'call' method makes the class callable like a function.
  // It validates the data map thoroughly before delegating the creation task to the repository.
  Future<void> call(Map<String, dynamic> messData) {
    // --- VALIDATION LOGIC ---
    // This is the "gatekeeper" that protects your API from bad data.

    // 1. Check for presence of core required fields.
    _validateRequiredField(messData, 'name', 'Mess name');
    _validateRequiredField(messData, 'address', 'Address');
    _validateRequiredField(messData, 'managerContact', 'Manager contact');
    _validateRequiredField(messData, 'serviceType', 'Service type');
    _validateRequiredField(messData, 'cuisine', 'Cuisine type');

    // 2. Validate the location structure.
    if (messData['location'] == null ||
        messData['location']['type'] != 'Point' ||
        messData['location']['coordinates'] is! List ||
        (messData['location']['coordinates'] as List).length != 2) {
      throw Exception('A valid location on the map must be set.');
    }

    final serviceType = messData['serviceType'];

    // 3. Conditional Validation based on Service Type.
    if (serviceType == 'Daily Only' || serviceType == 'Both') {
      if (messData['dailyThaliRate'] == null ||
          (messData['dailyThaliRate'] as num) <= 0) {
        throw Exception(
            'A valid Per-Thali Rate is required for daily service.');
      }
    }

    if (serviceType == 'Monthly Only' || serviceType == 'Both') {
      if (messData['mealPlans'] == null ||
          (messData['mealPlans'] as List).isEmpty) {
        throw Exception(
            'At least one Monthly Plan is required for monthly service.');
      }
      // Validate each meal plan.
      for (var plan in (messData['mealPlans'] as List)) {
        _validateRequiredField(plan, 'name', 'Plan name');
        _validateRequiredField(
            plan, 'perDayRebateRate', 'Per-Day Rebate Rate for the plan');

        if (plan['priceHistory'] == null ||
            (plan['priceHistory'] as List).isEmpty) {
          throw Exception('Each meal plan must have an initial price.');
        }
        if ((plan['priceHistory'] as List).first['price'] == null ||
            ((plan['priceHistory'] as List).first['price'] as num) <= 0) {
          throw Exception('Each meal plan must have a valid price.');
        }
      }
    }

    // If all validations pass, proceed to call the repository.
    return repository.createMess(messData);
  }

  // A private helper function to reduce boilerplate code for checking required fields.
  void _validateRequiredField(
      Map<String, dynamic> data, String key, String fieldName) {
    if (data[key] == null ||
        (data[key] is String && (data[key] as String).trim().isEmpty)) {
      throw Exception('$fieldName cannot be empty.');
    }
  }
}
