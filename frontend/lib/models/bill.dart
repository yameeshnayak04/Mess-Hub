// lib/models/bill.dart
import '../core/utils/json_parse.dart';

class Bill {
  final String id;
  final String membershipId;
  final String messId;

  /// First day of the billed month, 'YYYY-MM-DD'. Replaces the old separate
  /// month/year integers.
  final String period;

  final double baseRupees;
  final double rebateRupees;
  final double totalRupees;
  final String status; // 'Due' | 'Pending Approval' | 'Paid'

  /// The proof image is private on Cloudinary, so the bill only says whether
  /// one exists. A manager fetches a short-lived signed link separately via
  /// GET /billing/:billId/proof.
  final bool hasPaymentProof;

  final String? memberName;
  final String? memberPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bill({
    required this.id,
    required this.membershipId,
    required this.messId,
    required this.period,
    required this.baseRupees,
    required this.rebateRupees,
    required this.totalRupees,
    required this.status,
    this.hasPaymentProof = false,
    this.memberName,
    this.memberPhone,
    this.createdAt,
    this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: asId(json['id']),
        membershipId: asId(json['membershipId']),
        messId: asId(json['messId']),
        period: asCalendarDate(json['period']) ?? '',
        baseRupees: asDouble(json['baseRupees']) ?? 0,
        rebateRupees: asDouble(json['rebateRupees']) ?? 0,
        totalRupees: asDouble(json['totalRupees']) ?? 0,
        status: json['status'] as String? ?? 'Due',
        hasPaymentProof: asBool(json['hasPaymentProof']),
        memberName: json['memberName'] as String?,
        memberPhone: json['memberPhone'] as String?,
        createdAt: parseTimestamp(json['createdAt']),
        updatedAt: parseTimestamp(json['updatedAt']),
      );

  DateTime? get periodDate => parseCalendarDate(period);
  int get month => periodDate?.month ?? 0;
  int get year => periodDate?.year ?? 0;

  bool get isPaid => status == 'Paid';
  bool get isAwaitingApproval => status == 'Pending Approval';
  bool get isDue => status == 'Due';
}
