// lib/features/manager_dashboard/domain/repositories/manager_repository.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/payment_approval.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';

abstract class ManagerRepository {
  Future<DashboardStats> getDashboardStats();
  Future<List<Member>> getMembers();
  Future<MemberDetail> getMemberDetail(String membershipId);
  Future<List<PaymentApproval>> getPaymentApprovals();
  Future<void> approvePayment(String invoiceId);
  Future<void> rejectPayment(String invoiceId);
  Future<MessProfile> getMessProfile();
  Future<MessProfile> getMyMess();
  Future<void> uploadTodayMenu(Map<String, dynamic> menuData);
  Future<String> downloadInvoice(String invoiceId);
}
