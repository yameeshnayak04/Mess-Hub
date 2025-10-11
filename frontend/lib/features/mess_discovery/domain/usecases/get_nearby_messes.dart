// This file defines a single, specific business action: getting nearby messes.

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

class GetNearbyMesses {
  final MessRepository repository;

  // The use case depends on the repository contract, not the implementation.
  GetNearbyMesses(this.repository);

  // The 'call' method makes the class callable like a function.
  // This is a common convention for use cases in Dart.
  Future<List<Mess>> call(double lat, double lng, {double radius = 10.0}) {
    // It simply calls the repository method. The use case can also contain
    // more complex business logic if needed (e.g., sorting, filtering).
    return repository.getNearbyMesses(lat, lng, radius);
  }
}
