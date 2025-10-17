// lib/features/customer_dashboard/domain/usecases/get_my_memberships.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class GetMyMemberships {
  final CustomerRepository repository;
  GetMyMemberships(this.repository);
  Future<List<Membership>> call() => repository.getMyMemberships();
}
