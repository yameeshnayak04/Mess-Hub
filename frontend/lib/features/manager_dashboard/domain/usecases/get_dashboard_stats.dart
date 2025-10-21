// lib/features/manager_dashboard/domain/usecases/get_dashboard_stats.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetDashboardStats {
  final ManagerRepository repository;

  GetDashboardStats(this.repository);

  Future<DashboardStats> call() {
    return repository.getDashboardStats();
  }
}
