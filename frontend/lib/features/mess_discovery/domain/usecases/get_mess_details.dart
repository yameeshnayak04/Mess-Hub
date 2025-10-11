// This file defines a single, specific business action: getting a mess's details.

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

class GetMessDetails {
  final MessRepository repository;

  GetMessDetails(this.repository);

  // The 'call' method takes the mess ID as a parameter.
  Future<Mess> call(String messId) {
    return repository.getMessDetails(messId);
  }
}
