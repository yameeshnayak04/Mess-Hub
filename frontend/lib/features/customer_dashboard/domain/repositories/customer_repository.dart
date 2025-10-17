// lib/features/customer_dashboard/domain/repositories/customer_repository.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

abstract class CustomerRepository {
  // Contract for fetching all active memberships for the logged-in user.
  Future<List<Membership>> getMyMemberships();

  // Contract for marking a formal leave for a specific membership.
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate);

  // Contract for toggling the "Not Eating" status for a single meal.
  Future<void> toggleMealSkip(
      String membershipId, DateTime date, String mealType);

  // Contract for fetching all invoices for the logged-in user.
  Future<List<Invoice>> getMyInvoices();

  // Contract for notifying the manager that a payment has been made.
  Future<void> notifyPayment(String invoiceId, String? proofUrl);
}
