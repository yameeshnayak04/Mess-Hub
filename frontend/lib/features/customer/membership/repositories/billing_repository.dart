// lib/features/customer/membership/repositories/billing_repository.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class BillingRepository {
  final DioClient _dio;
  BillingRepository(this._dio);

  Future<List<dynamic>> getMyBills(String membershipId) async {
    final res = await _dio.get('/billing/my-bills/$membershipId');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> submitPaymentProof({
    required String billId,
    required File file,
  }) async {
    final form = FormData.fromMap({
      'proof': await MultipartFile.fromFile(
          file.path), // Changed from 'file' to 'proof'
    });
    final res = await _dio.post('/billing/submit-proof/$billId', data: form);
    return res.data;
  }
}
