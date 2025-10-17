// lib/features/customer_dashboard/domain/usecases/toggle_meal_skip.dart

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class ToggleMealSkip {
  final CustomerRepository repository;

  ToggleMealSkip(this.repository);

  // The 'call' method makes the class callable like a function.
  // It takes all the necessary parameters for the action.
  Future<void> call({
    required String membershipId,
    required DateTime date,
    required String mealType,
  }) {
    // A simple validation to ensure mealType is one of the expected values.
    if (mealType != 'Lunch' && mealType != 'Dinner') {
      throw Exception('Invalid meal type provided.');
    }
    return repository.toggleMealSkip(membershipId, date, mealType);
  }
}
