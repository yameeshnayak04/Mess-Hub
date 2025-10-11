// This file implements the MessRepository contract from the domain layer.

import 'package:mess_management_system/features/mess_discovery/data/datasources/mess_remote_datasource.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';

class MessRepositoryImpl implements MessRepository {
  // This repository depends on the remote data source to fetch data.
  final MessRemoteDataSource remoteDataSource;

  MessRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Mess>> getNearbyMesses(
      double lat, double lng, double radius) async {
    try {
      // Call the datasource to get a list of MessModels.
      final messModels =
          await remoteDataSource.getNearbyMesses(lat, lng, radius);
      // Since MessModel extends Mess, the list is already of the correct type.
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
}
