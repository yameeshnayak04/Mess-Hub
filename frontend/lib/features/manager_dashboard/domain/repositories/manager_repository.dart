// This file defines the contract for the manager repository.

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';

abstract class ManagerRepository {
  // Contract for fetching the live dashboard statistics for the manager's mess.
  Future<DashboardStats> getDashboardStats();

  // We can add more contracts here later, like fetching members list.
  // Future<List<Member>> getMessMembers();
}
