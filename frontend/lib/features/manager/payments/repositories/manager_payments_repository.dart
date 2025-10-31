// lib/features/manager/billing/repositories/manager_payments_repository.dart
import '../../../../core/api/dio_client.dart';

class ManagerPaymentsRepository {
  final DioClient _dio;
  ManagerPaymentsRepository(this._dio);

  // Pending approvals (bills awaiting manager decision)
  Future<List<dynamic>> getPendingApprovals() async {
    final res = await _dio.get('/billing/pending-approvals');
    return (res.data['data'] as List);
  }

  // Approve a payment
  Future<Map<String, dynamic>> approvePayment(String billId) async {
    final res = await _dio.put('/billing/approve-payment/$billId');
    return res.data as Map<String, dynamic>;
  }

  // Reject a payment
  Future<Map<String, dynamic>> rejectPayment(String billId) async {
    final res = await _dio.put('/billing/reject-payment/$billId');
    return res.data as Map<String, dynamic>;
  }

  // Optional: all bills (filter by status/month/year/member)
  Future<List<dynamic>> getAllBills({
    String? status, // 'Paid' | 'Pending Approval' | 'Due'
    int? month,
    int? year,
    String? memberNameOrPhone,
    int page = 1,
    int limit = 20,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (memberNameOrPhone != null && memberNameOrPhone.isNotEmpty)
        'q': memberNameOrPhone,
    };
    final res = await _dio.get('/billing/all-bills', queryParameters: qp);
    return (res.data['data'] as List);
  }

  // Optional: fetch proof details for a bill if not embedded on the bill
  Future<Map<String, dynamic>> getPaymentByBillId(String billId) async {
    final res = await _dio.get('/billing/payment/$billId');
    return res.data['data'] as Map<String, dynamic>;
  }
}
