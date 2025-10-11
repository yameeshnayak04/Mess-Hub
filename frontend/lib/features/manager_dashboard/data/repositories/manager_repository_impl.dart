// This file implements the ManagerRepository contract from the domain layer.

import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerRemoteDataSource remoteDataSource;

  ManagerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      // The datasource returns a DashboardStatsModel. Since the model extends
      // the entity, we can return it directly.
      return await remoteDataSource.getDashboardStats();
    } catch (e) {
      // Re-throw any errors to be handled by the presentation layer.
      rethrow;
    }
  }
}
