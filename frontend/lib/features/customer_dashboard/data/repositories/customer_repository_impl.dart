// lib/features/customer_dashboard/data/repositories/customer_repository_impl.dart

import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  // This repository depends on the remote data source to fetch the data.
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Membership>> getMyMemberships() async {
    try {
      // The datasource returns a list of MembershipModels. Since MembershipModel
      // extends Membership, we can return the list directly. Dart's type system
      // understands that a List<MembershipModel> is also a List<Membership>.
      return await remoteDataSource.getMyMemberships();
    } catch (e) {
      // Re-throw the exception to be handled by the presentation layer.
      rethrow;
    }
  }

  @override
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate) async {
    try {
      // This method doesn't return data, so we just await its completion.
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
}
