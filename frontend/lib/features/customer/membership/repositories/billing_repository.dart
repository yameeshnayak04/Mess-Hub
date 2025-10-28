import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class BillingRepository {
  final DioClient _dio;
  BillingRepository(this._dio);

  // Customer: my bills for a membership
  Future<List<dynamic>> getMyBills(String membershipId) async {
    final res = await _dio.get('/billing/my-bills/$membershipId');
    return (res.data['data'] as List);
  }

  // Customer: submit payment proof (multipart)
  Future<Map<String, dynamic>> submitPaymentProof({
    required String billId,
    required File file,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post('/billing/submit-proof/$billId', data: form);
    return res.data;
  }

  // Manager: pending approvals
  Future<List<dynamic>> getPendingApprovals() async {
    final res = await _dio.get('/billing/pending-approvals');
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> approvePayment(String billId) async {
    final res = await _dio.put('/billing/approve-payment/$billId');
    return res.data;
  }

  Future<Map<String, dynamic>> rejectPayment(String billId) async {
    final res = await _dio.put('/billing/reject-payment/$billId');
    return res.data;
  }

  // Manager: generate monthly bills
  Future<Map<String, dynamic>> generateMonthlyBills(
      {int? month, int? year}) async {
    final res = await _dio.post('/billing/generate-bills', data: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return res.data;
  }
}
