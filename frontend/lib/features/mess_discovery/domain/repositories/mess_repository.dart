// lib/features/mess_discovery/domain/repositories/mess_repository.dart

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

// This abstract class defines the contract for the mess discovery repository.
abstract class MessRepository {
  // Contract for fetching messes near a given location, with an optional filter.
  // It takes latitude, longitude, and a search radius in kilometers.
  // It returns a list of Mess entities.
  Future<List<Mess>> getNearbyMesses({
    required double lat,
    required double lng,
    double radius = 10.0,
    String? filter,
  });

  // Contract for fetching the detailed public profile of a single mess by its ID.
  Future<Mess> getMessDetails(String messId);
}
