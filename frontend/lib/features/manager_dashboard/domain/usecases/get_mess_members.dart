// In frontend/lib/features/manager_dashboard/domain/usecases/get_mess_members.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/manager_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetMessMembers {
  final ManagerRepository repository;
  GetMessMembers(this.repository);
  Future<List<ManagerMember>> call() => repository.getMessMembers();
}
