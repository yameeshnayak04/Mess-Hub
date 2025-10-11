// This file implements the CustomerRepository contract from the domain layer.

import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  // This repository depends on the remote data source to fetch the data.
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Membership>> getMyMemberships() async {
    try {
      // The datasource returns a list of MembershipModels. Since MembershipModel
      // extends Membership, we can return it directly.
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
  Future<List<Invoice>> getBillingHistory(String membershipId) async {
    try {
      // This will connect to the real datasource method once implemented.
      return await remoteDataSource.getBillingHistory(membershipId);
    } catch (e) {
      rethrow;
    }
  }
}
