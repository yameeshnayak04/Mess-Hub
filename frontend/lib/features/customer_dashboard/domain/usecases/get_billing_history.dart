// This file defines the use case for getting billing history.

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class GetBillingHistory {
  final CustomerRepository repository;

  GetBillingHistory(this.repository);

  Future<List<Invoice>> call(String membershipId) {
    return repository.getBillingHistory(membershipId);
  }
}
