// lib/models/bill.dart
class Bill {
  final String id;
  final String user;
  final String mess;
  final int month;
  final int year;
  final double baseAmount;
  final double rebateAmount;
  final double totalAmount;
  final String status; // 'Due' | 'Pending Approval' | 'Paid'
  final String? paymentProofUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bill({
    required this.id,
    required this.user,
    required this.mess,
    required this.month,
    required this.year,
    required this.baseAmount,
    required this.rebateAmount,
    required this.totalAmount,
    required this.status,
    this.paymentProofUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] as String,
      user: json['user'] as String,
      mess: json['mess'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      baseAmount: (json['baseAmount'] as num).toDouble(),
      rebateAmount: (json['rebateAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user': user,
        'mess': mess,
        'month': month,
        'year': year,
        'baseAmount': baseAmount,
        'rebateAmount': rebateAmount,
        'totalAmount': totalAmount,
        'status': status,
        if (paymentProofUrl != null) 'paymentProofUrl': paymentProofUrl,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
