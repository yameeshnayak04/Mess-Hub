// This file defines the use case for getting the manager's dashboard stats.

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetDashboardStats {
  final ManagerRepository repository;

  GetDashboardStats(this.repository);

  // The 'call' method makes the class callable like a function.
  Future<DashboardStats> call() {
    return repository.getDashboardStats();
  }
}
