// lib/features/manager_dashboard/domain/usecases/get_member_detail.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetMemberDetail {
  final ManagerRepository repository;

  GetMemberDetail(this.repository);

  Future<MemberDetail> call(String membershipId) {
    return repository.getMemberDetail(membershipId);
  }
}
