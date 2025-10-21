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

  @override
  Future<DashboardStats> getDashboardStats(String messId) =>
      remoteDataSource.getDashboardStats(messId);

  @override
  Future<List<Member>> getMembers(String messId) =>
      remoteDataSource.getMembers(messId);

  @override
  Future<MemberDetail> getMemberDetail(String membershipId) =>
      remoteDataSource.getMemberDetail(membershipId);

  @override
  Future<List<PaymentApproval>> getPaymentApprovals(String messId) =>
      remoteDataSource.getPaymentApprovals(messId);

  @override
  Future<void> approvePayment(String invoiceId) =>
      remoteDataSource.approvePayment(invoiceId);

  @override
  Future<void> rejectPayment(String invoiceId) =>
      remoteDataSource.rejectPayment(invoiceId);

  @override
  Future<MessProfile> getMessProfile(String messId) =>
      remoteDataSource.getMessProfile(messId);

  @override
  Future<void> uploadTodayMenu(String messId, Map<String, dynamic> menuData) =>
      remoteDataSource.uploadTodayMenu(messId, menuData);

  // lib/features/manager_dashboard/data/repositories/manager_repository_impl.dart

  @override
  Future<MessProfile> getMyMess() => remoteDataSource.getMyMess();

  @override
  Future<String> downloadInvoice(String invoiceId) =>
      remoteDataSource.downloadInvoice(invoiceId);
}
