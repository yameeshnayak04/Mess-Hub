// This file defines the contract for the customer repository.

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

abstract class CustomerRepository {
  // Contract for fetching all active memberships for the logged-in user.
  Future<List<Membership>> getMyMemberships();

  // Contract for marking a leave for a specific membership.
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate);

  // Contract for fetching the billing history for a specific membership.
  Future<List<Invoice>> getBillingHistory(String membershipId);
}
