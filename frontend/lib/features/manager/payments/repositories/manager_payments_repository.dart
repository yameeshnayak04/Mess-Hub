// lib/features/manager/billing/repositories/manager_payments_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ManagerPaymentsRepository {
  final DioClient _dio;
  ManagerPaymentsRepository(this._dio);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'];
    return fallback;
  }

  // Extract origin from baseUrl (strip trailing /api if present)
  String get _origin {
    final base =
        _dio.baseUrl; // expose baseUrl from DioClient (ensure getter exists)
    final uri = Uri.parse(base);
    final origin =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return base.endsWith('/api')
        ? origin
        : (uri.path.startsWith('/api') ? origin : base);
  }

  String? resolveFileUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://'))
      return pathOrUrl;
    // Server serves static uploads at /uploads
    if (pathOrUrl.startsWith('/uploads/')) return '$_origin$pathOrUrl';
    return '$_origin/$pathOrUrl';
  }

  // Pending approvals (bills awaiting manager decision)
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final res = await _dio.get('/billing/pending-approvals');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load pending approvals');
  }

  Future<List> getDueBills() async {
    final res = await _dio.get('/billing/due-bills');
    return (res.data['data'] as List);
  }

  // Approve a payment
  Future<Map<String, dynamic>> approvePayment(String billId) async {
    final res = await _dio.put('/billing/approve-payment/$billId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to approve payment');
  }

  // Reject a payment
  Future<Map<String, dynamic>> rejectPayment(String billId) async {
    final res = await _dio.put('/billing/reject-payment/$billId');
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(res.data as Map);
    throw _msg(res, 'Failed to reject payment');
  }

  // All bills (filter by status/month/year/member; supports automated billing cycles)
  Future<List<Map<String, dynamic>>> getAllBills({
    String? status, // 'Paid' | 'Pending Approval' | 'Due'
    int? month,
    int? year,
    String? memberNameOrPhone,
    int page = 1,
    int limit = 20,
  }) async {
    final qp = {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (memberNameOrPhone != null && memberNameOrPhone.isNotEmpty)
        'q': memberNameOrPhone,
    };
    final res = await _dio.get('/billing/all-bills', queryParameters: qp);
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load bills');
  }

  // Payment detail for proof (if not embedded on the bill)
  Future<Map<String, dynamic>> getPaymentByBillId(String billId) async {
    final res = await _dio.get('/billing/payment/$billId');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
      return Map<String, dynamic>.from(res.data['data'] as Map);
    }
    throw _msg(res, 'Failed to load payment detail');
  }

  // Helper to resolve payment proof URL from bill or detail
  Future<String?> getPaymentProofUrl(Map<String, dynamic> bill) async {
    final direct = resolveFileUrl((bill['proofUrl'] ??
        bill['paymentProofUrl'] ??
        bill['screenshotUrl']) as String?);
    if (direct != null) return direct;
    final id = (bill['_id'] as String?) ?? (bill['id'] as String?);
    if (id == null) return null;
    final detail = await getPaymentByBillId(id);
    final fromDetail = resolveFileUrl(
      (detail['proofUrl'] ??
          detail['paymentProofUrl'] ??
          detail['screenshotUrl']) as String?,
    );
    return fromDetail;
  }
}
