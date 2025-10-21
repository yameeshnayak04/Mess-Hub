// lib/features/manager_dashboard/data/repositories/manager_repository_impl.dart

import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/payment_approval.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerRemoteDataSource remoteDataSource;

  ManagerRepositoryImpl({required this.remoteDataSource});

  // ✅ FIXED: Removed messId parameter - backend uses JWT to identify manager's mess
  @override
  Future<DashboardStats> getDashboardStats() =>
      remoteDataSource.getDashboardStats();

  // ✅ FIXED: Removed messId parameter
  @override
  Future<List<Member>> getMembers() => remoteDataSource.getMembers();

  // ✅ This one is correct - member detail needs membershipId
  @override
  Future<MemberDetail> getMemberDetail(String membershipId) =>
      remoteDataSource.getMemberDetail(membershipId);

  // ✅ FIXED: Removed messId parameter
  @override
  Future<List<PaymentApproval>> getPaymentApprovals() =>
      remoteDataSource.getPaymentApprovals();

  // ✅ These are correct - they need invoiceId
  @override
  Future<void> approvePayment(String invoiceId) =>
      remoteDataSource.approvePayment(invoiceId);

  @override
  Future<void> rejectPayment(String invoiceId) =>
      remoteDataSource.rejectPayment(invoiceId);

  // ✅ FIXED: Removed messId parameter - use getMyMess() instead
  @override
  Future<MessProfile> getMessProfile() => remoteDataSource.getMyMess();

  // ✅ FIXED: Removed messId parameter
  @override
  Future<void> uploadTodayMenu(Map<String, dynamic> menuData) =>
      remoteDataSource.uploadTodayMenu(menuData);

  // ✅ This is the primary method to get manager's mess profile
  @override
  Future<MessProfile> getMyMess() => remoteDataSource.getMyMess();

  // ✅ This is correct - needs invoiceId
  @override
  Future<String> downloadInvoice(String invoiceId) =>
      remoteDataSource.downloadInvoice(invoiceId);
}
