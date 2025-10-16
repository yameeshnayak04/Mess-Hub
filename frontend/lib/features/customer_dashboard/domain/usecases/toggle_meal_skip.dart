// lib/features/customer_dashboard/domain/usecases/toggle_meal_skip.dart

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class ToggleMealSkip {
  final CustomerRepository repository;

  ToggleMealSkip(this.repository);

  // Use case for toggling the "Not Eating" status for a single meal.
  Future<void> call({
    required String membershipId,
    required DateTime date,
    required String mealType,
  }) {
    return repository.toggleMealSkip(membershipId, date, mealType);
  }
}
