// This file defines the contract for the mess repository.

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

abstract class MessRepository {
  // Contract for fetching messes near a given location.
  // It takes latitude, longitude, and a search radius in kilometers.
  // It returns a list of Mess entities.
  Future<List<Mess>> getNearbyMesses(double lat, double lng, double radius);

  // Contract for fetching the detailed profile of a single mess by its ID.
  Future<Mess> getMessDetails(String messId);
}
