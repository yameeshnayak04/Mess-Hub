// lib/features/mess_discovery/domain/usecases/join_mess.dart

import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

class JoinMess {
  final MessRepository repository;

  JoinMess(this.repository);

  Future<void> call({required String messId, required String mealPlanId}) {
    if (messId.isEmpty || mealPlanId.isEmpty) {
      throw Exception('Mess ID and Meal Plan ID cannot be empty.');
    }
    return repository.joinMess(messId, mealPlanId);
  }
}
