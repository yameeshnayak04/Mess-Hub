// lib/features/mess_discovery/data/repositories/mess_repository_impl.dart

import 'package:mess_management_system/features/mess_discovery/data/datasources/mess_remote_datasource.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

class MessRepositoryImpl implements MessRepository {
  // This repository depends on the remote data source to fetch data.
  final MessRemoteDataSource remoteDataSource;

  MessRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Mess>> getNearbyMesses(
      {required double lat,
      required double lng,
      double radius = 10.0,
      String? filter}) async {
    try {
      // Call the datasource to get a list of MessModels.
      final messModels = await remoteDataSource.getNearbyMesses(
          lat: lat, lng: lng, radius: radius, filter: filter);
      // Since MessModel extends Mess, the list is already of the correct type (List<Mess>).
      // This is a major benefit of using this inheritance pattern.
      return messModels;
    } catch (e) {
      // Re-throw the exception to be handled by the presentation layer.
      rethrow;
    }
  }

  @override
  Future<Mess> getMessDetails(String messId) async {
    try {
      // Call the datasource to get a single MessModel.
      final messModel = await remoteDataSource.getMessDetails(messId);
      // The messModel is already a valid Mess entity.
      return messModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> joinMess(String messId, String mealPlanId) async {
    try {
      return await remoteDataSource.joinMess(messId, mealPlanId);
    } catch (e) {
      rethrow;
    }
  }
}
