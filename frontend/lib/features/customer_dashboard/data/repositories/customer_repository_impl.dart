// lib/features/customer_dashboard/data/repositories/customer_repository_impl.dart

import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Membership>> getMyMemberships() async {
    try {
      return await remoteDataSource.getMyMemberships();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate) async {
    try {
      return await remoteDataSource.markLeave(membershipId, startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> toggleMealSkip(
      String membershipId, DateTime date, String mealType) async {
    try {
      return await remoteDataSource.toggleMealSkip(
          membershipId, date, mealType);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Invoice>> getMyInvoices() async {
    try {
      return await remoteDataSource.getMyInvoices();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> notifyPayment(String invoiceId, String? proofUrl) async {
    try {
      return await remoteDataSource.notifyPayment(invoiceId, proofUrl);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Invoice>> getBillingHistory(String membershipId) {
    try {
      return remoteDataSource.getMyInvoices();
    } catch (e) {
      rethrow;
    }
  }
}
