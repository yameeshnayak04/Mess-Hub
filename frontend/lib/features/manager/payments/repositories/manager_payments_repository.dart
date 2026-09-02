// lib/features/manager/payments/repositories/manager_payments_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/bill.dart';

class ManagerPaymentsRepository {
  final DioClient _dio;
  ManagerPaymentsRepository(this._dio);

  /// One filtered route replaces the old separate pending/due/all endpoints.
  Future<List<Bill>> getBills({
    String? status,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/billing/mess', queryParameters: {
        if (status != null) 'status': status,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        'page': page,
        'limit': limit,
      });
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Bill>> getPendingApprovals() =>
      getBills(status: 'Pending Approval');

  Future<List<Bill>> getDueBills() => getBills(status: 'Due');

  Future<List<Bill>> getAllBills({
    String? status,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) =>
      getBills(
          status: status, month: month, year: year, page: page, limit: limit);

  /// A bill only moves to Paid from 'Pending Approval' - the backend refuses a
  /// straight Due -> Paid jump, since nobody submitted proof for it.
  Future<Bill> approvePayment(String billId) async {
    try {
      final res = await _dio.post('/billing/$billId/approve');
      return Bill.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Sends the bill back to Due. The rejected proof is kept in the bill's
  /// event history rather than being erased.
  Future<Bill> rejectPayment(String billId, {String? note}) async {
    try {
      final res = await _dio.post(
        '/billing/$billId/reject',
        data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      );
      return Bill.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Payment proofs are private on Cloudinary, so there is no permanent URL on
  /// the bill any more. This asks for a freshly signed link that expires in a
  /// few minutes.
  Future<String?> getPaymentProofUrl(String billId) async {
    try {
      final res = await _dio.get('/billing/$billId/proof');
      final data = Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
      return data['viewUrl'] as String?;
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Who submitted, approved or rejected a payment, and when.
  Future<Map<String, dynamic>> getBillHistory(String billId) async {
    try {
      final res = await _dio.get('/billing/$billId/history');
      return Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
