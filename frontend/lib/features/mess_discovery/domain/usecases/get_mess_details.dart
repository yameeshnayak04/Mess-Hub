// lib/features/mess_discovery/domain/usecases/get_mess_details.dart

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

// This use case represents the single business action of fetching a mess's details.
class GetMessDetails {
  final MessRepository repository;

  GetMessDetails(this.repository);

  // The 'call' method takes the mess ID as a parameter.
  Future<Mess> call(String messId) {
    // Use cases are a great place for high-level validation.
    if (messId.isEmpty) {
      throw Exception('Mess ID cannot be empty.');
    }
    return repository.getMessDetails(messId);
  }
}
