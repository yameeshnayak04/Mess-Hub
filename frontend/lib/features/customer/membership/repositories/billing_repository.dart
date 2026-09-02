// lib/features/customer/membership/repositories/billing_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/bill.dart';

class BillingRepository {
  final DioClient _dio;
  BillingRepository(this._dio);

  /// A membership's bills, newest period first.
  Future<List<Bill>> getMyBills(
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/billing/membership/$membershipId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Uploads the payment screenshot and moves the bill to 'Pending Approval'.
  /// The multipart field name is `paymentProof`; the image is stored privately
  /// on Cloudinary, so it is never readable from a plain URL afterwards.
  Future<Bill> submitPaymentProof({
    required String billId,
    required String filePath,
    String? fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'paymentProof': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });
      final res = await _dio.post('/billing/$billId/proof', data: form);
      return Bill.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
