// lib/features/customer_dashboard/data/datasources/customer_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/invoice_model.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/membership_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<MembershipModel>> getMyMemberships();
  Future<void> markLeave(
      String membershipId, DateTime startDate, DateTime endDate);
  Future<void> toggleMealSkip(
      String membershipId, DateTime date, String mealType);
  Future<List<InvoiceModel>> getMyInvoices();
  Future<void> notifyPayment(String invoiceId, String? proofUrl);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<MembershipModel>> getMyMemberships() async {
    try {
      final response = await _dio.get('/customers/me/memberships');
      return (response.data as List)
          .map((json) => MembershipModel.fromJson(json))
          .toList();
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
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark leave');
    }
  }

  @override
  Future<void> toggleMealSkip(
      String membershipId, DateTime date, String mealType) async {
    try {
      await _dio.post(
        '/customers/memberships/$membershipId/toggle-meal',
        data: {
          'date': date.toIso8601String(),
          'mealType': mealType,
        },
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to toggle meal status');
    }
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() async {
    try {
      final response = await _dio.get('/customers/me/invoices');
      return (response.data as List)
          .map((json) => InvoiceModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch invoices');
    }
  }

  @override
  Future<void> notifyPayment(String invoiceId, String? proofUrl) async {
    try {
      await _dio.post(
        '/customers/invoices/$invoiceId/notify-payment',
        data: {'proofUrl': proofUrl},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to notify payment');
    }
  }
}
