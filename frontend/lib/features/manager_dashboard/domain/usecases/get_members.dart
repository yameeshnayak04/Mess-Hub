// lib/features/manager_dashboard/domain/usecases/get_members.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetMembers {
  final ManagerRepository repository;

  GetMembers(this.repository);

  Future<List<Member>> call(String messId) {
    return repository.getMembers(messId);
  }
}
