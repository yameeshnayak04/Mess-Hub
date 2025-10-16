// This file defines the use case for marking a leave.

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class MarkLeave {
  final CustomerRepository repository;

  MarkLeave(this.repository);

  Future<void> call({
    required String membershipId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Use cases are a great place for business rule validation.
    if (startDate.isAfter(endDate)) {
      throw Exception('Start date cannot be after the end date.');
    }
    return repository.markLeave(membershipId, startDate, endDate);
  }
}
