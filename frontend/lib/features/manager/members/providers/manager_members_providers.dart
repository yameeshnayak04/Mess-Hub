// lib/features/manager/members/providers/manager_members_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/attendance.dart';
import '../../../../models/bill.dart';
import '../../../../models/leave.dart';
import '../../../../models/membership.dart';
import '../../../../models/membership_details.dart';
import '../repositories/manager_members_repository.dart';

final managerMembersRepositoryProvider =
    Provider<ManagerMembersRepository>((ref) {
  return ManagerMembersRepository(ref.watch(dioClientProvider));
});

// Lists
final membersByStatusProvider = FutureProvider.family
    .autoDispose<List<Membership>, String?>((ref, status) async {
  return ref
      .watch(managerMembersRepositoryProvider)
      .getMessMembers(status: status);
});

final pendingMembersProvider =
    FutureProvider.autoDispose<List<Membership>>((ref) async {
  return ref
      .watch(managerMembersRepositoryProvider)
      .getMessMembers(status: 'Pending');
});

// Details
final memberDetailsProvider = FutureProvider.family
    .autoDispose<MembershipDetails, String>((ref, id) async {
  return ref.watch(managerMembersRepositoryProvider).getMemberDetails(id);
});

// Attendance (month/year keyed)
class MemberCalendarParams {
  final String membershipId;
  final int month;
  final int year;
  const MemberCalendarParams(this.membershipId, this.month, this.year);

  @override
  bool operator ==(Object other) =>
      other is MemberCalendarParams &&
      membershipId == other.membershipId &&
      month == other.month &&
      year == other.year;

  @override
  int get hashCode => membershipId.hashCode ^ month.hashCode ^ year.hashCode;
}

final memberAttendanceProvider = FutureProvider.family
    .autoDispose<AttendanceCalendar, MemberCalendarParams>(
        (ref, p) async {
  return ref.watch(managerMembersRepositoryProvider).getMemberAttendance(
        membershipId: p.membershipId,
        month: p.month,
        year: p.year,
      );
});

// Leaves
final memberLeavesProvider = FutureProvider.family
    .autoDispose<List<Leave>, String>((ref, id) async {
  return ref.watch(managerMembersRepositoryProvider).getMemberLeaves(id);
});

// Bills
final memberBillsProvider = FutureProvider.family
    .autoDispose<List<Bill>, String>((ref, id) async {
  return ref.watch(managerMembersRepositoryProvider).getMemberBills(id);
});
