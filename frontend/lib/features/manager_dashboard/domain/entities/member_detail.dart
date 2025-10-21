// lib/features/manager_dashboard/domain/entities/member_detail.dart

class AttendanceRecord {
  final DateTime date;
  final String mealType;
  final bool isOverride;

  const AttendanceRecord({
    required this.date,
    required this.mealType,
    required this.isOverride,
  });
}

class PaymentHistory {
  final String invoiceId;
  final int month;
  final int year;
  final double amount;
  final String status;
  final DateTime? paidAt;

  const PaymentHistory({
    required this.invoiceId,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    this.paidAt,
  });
}

class MemberDetail {
  final String membershipId;
  final String customerName;
  final String customerPhone;
  final String? customerPhoto;
  final String planName;
  final double planPrice;
  final DateTime startedAt;
  final String status;
  final List<AttendanceRecord> attendance;
  final List<PaymentHistory> payments;

  const MemberDetail({
    required this.membershipId,
    required this.customerName,
    required this.customerPhone,
    this.customerPhoto,
    required this.planName,
    required this.planPrice,
    required this.startedAt,
    required this.status,
    required this.attendance,
    required this.payments,
  });
}
