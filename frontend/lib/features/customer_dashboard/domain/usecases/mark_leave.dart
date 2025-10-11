// This file defines the use case for marking a leave.

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class MarkLeave {
  final CustomerRepository repository;

  MarkLeave(this.repository);

  Future<void> call(String membershipId, DateTime startDate, DateTime endDate) {
    // We could add business logic here, e.g., checking if startDate is before endDate.
    if (startDate.isAfter(endDate)) {
      throw Exception('Start date cannot be after end date.');
    }
    return repository.markLeave(membershipId, startDate, endDate);
  }
}
