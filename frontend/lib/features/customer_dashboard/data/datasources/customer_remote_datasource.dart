// This file is responsible for making the actual API calls for the customer dashboard.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/invoice_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/membership_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<MembershipModel>> getMyMemberships();
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate);
  Future<List<InvoiceModel>> getBillingHistory(String membershipId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  // Get the singleton instance of our Dio client.
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<MembershipModel>> getMyMemberships() async {
    try {
      // Make a GET request to the protected route. The Dio interceptor
      // will automatically add the required JWT token to the headers.
      final response = await _dio.get('/customers/me/memberships');

      // Map the list of JSON objects from the response to a list of MembershipModel.
      final List<MembershipModel> memberships = (response.data as List)
          .map((membershipJson) => MembershipModel.fromJson(membershipJson))
          .toList();

      return memberships;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch memberships');
    }
  }

  @override
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate) async {
    try {
      await _dio.post(
        '/customers/memberships/$membershipId/leaves',
        data: {
          // Convert DateTime objects to ISO 8601 string format, which is standard for JSON.
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark leave');
    }
  }

  @override
  Future<List<InvoiceModel>> getBillingHistory(String membershipId) async {
    // This is a placeholder for a future API endpoint.
    // The implementation would be very similar to getMyMemberships.
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    print('Fetching billing history for $membershipId');
    return []; // Return an empty list for now.
  }
}
