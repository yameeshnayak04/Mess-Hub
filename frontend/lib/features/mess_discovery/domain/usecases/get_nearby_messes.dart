// lib/features/mess_discovery/domain/usecases/get_nearby_messes.dart

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

// This use case represents the single business action of fetching nearby messes.
class GetNearbyMesses {
  final MessRepository repository;

  // The use case depends on the abstract repository, not a concrete implementation.
  GetNearbyMesses(this.repository);

  // The 'call' method makes the class callable like a function.
  Future<List<Mess>> call({
    required double lat,
    required double lng,
    double radius = 10.0,
    String? filter,
  }) {
    // It simply delegates the call to the repository, passing all arguments.
    return repository.getNearbyMesses(
      lat: lat,
      lng: lng,
      radius: radius,
      filter: filter,
    );
  }
}
