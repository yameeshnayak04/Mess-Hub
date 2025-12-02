// lib/features/customer/membership/repositories/billing_repository.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class BillingRepository {
  final DioClient _dio;
  BillingRepository(this._dio);

  String _msg(Response res) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    return 'Failed to load billing';
  }

  Future<List<dynamic>> getMyBills(String membershipId) async {
    final res = await _dio.get('/billing/my-bills/$membershipId');
    if (res.statusCode != 200) throw _msg(res);
    return (res.data['data'] as List);
  }

  Future<Map<String, dynamic>> submitPaymentProof({
    required String billId,
    required File file,
  }) async {
    final form = FormData.fromMap({
      // IMPORTANT: match Multer field name expected by uploadPaymentProof
      // If your middleware uses a different key (e.g., 'proof' or 'file'),
      // change this name to match exactly.
      'paymentProof': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });
    final res = await _dio.post('/billing/submit-proof/$billId', data: form);
    if (res.statusCode != 200) throw _msg(res);
    return res.data as Map<String, dynamic>;
  }
}
