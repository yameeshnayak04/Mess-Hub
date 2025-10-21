// lib/features/customer_dashboard/domain/entities/invoice.dart

class Invoice {
  final String id;
  final String membershipId;
  final String messName;
  final int month;
  final int year;
  final double baseAmount;
  final int daysPresent;
  final int totalDays;
  final double rebateAmount;
  final double finalAmount;
  final String status; // 'pending', 'paid', 'approved', 'rejected'
  final DateTime generatedDate;
  final DateTime? paidDate;
  final String? paymentScreenshotUrl;
  final String? rejectionReason;

  Invoice({
    required this.id,
    required this.membershipId,
    required this.messName,
    required this.month,
    required this.year,
    required this.baseAmount,
    required this.daysPresent,
    required this.totalDays,
    required this.rebateAmount,
    required this.finalAmount,
    required this.status,
    required this.generatedDate,
    this.paidDate,
    this.paymentScreenshotUrl,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String get periodDisplay => '$monthName $year';

  double get attendancePercentage => (daysPresent / totalDays * 100);
}
