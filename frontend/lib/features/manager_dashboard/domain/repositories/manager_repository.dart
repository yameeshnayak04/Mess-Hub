// lib/features/manager_dashboard/domain/repositories/manager_repository.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';

// This abstract class defines the contract that the data layer must implement.
// It acts as a bridge between the domain and data layers.
abstract class ManagerRepository {
  // Contract for fetching the live dashboard statistics for the manager's own mess.
  // This is the primary action for the main dashboard screen.
  Future<DashboardStats> getDashboardStats();

  // In a full implementation, as we build out the other screens of the manager dashboard
  // (like the members list), we will add more contracts here. For example:
  //
  // Future<List<Member>> getMessMembers();
  // Future<void> updateMessRules(Map<String, dynamic> rules);
}
