// This file defines the use case for getting a customer's memberships.

import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class GetMyMemberships {
  final CustomerRepository repository;

  GetMyMemberships(this.repository);

  // The 'call' method makes the class callable like a function.
  Future<List<Membership>> call() {
    return repository.getMyMemberships();
  }
}
