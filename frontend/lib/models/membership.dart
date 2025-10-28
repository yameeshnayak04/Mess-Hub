// lib/models/membership.dart
import 'mess.dart';

class Membership {
  final String id;
  final String user;
  final dynamic mess; // String or Mess
  final String planName;
  final double billingRate;
  final String status; // 'Pending' | 'Active' | 'Inactive'
  final DateTime? joinedDate;
  final String? paymentStatus; // added by manager list enrichment
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Membership({
    required this.id,
    required this.user,
    required this.mess,
    required this.planName,
    required this.billingRate,
    required this.status,
    this.joinedDate,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    dynamic messData = json['mess'];
    if (messData is Map<String, dynamic>) {
      messData = Mess.fromJson(messData);
    }
    return Membership(
      id: json['_id'] as String,
      user: json['user'] as String,
      mess: messData,
      planName: json['planName'] as String,
      billingRate: (json['billingRate'] as num).toDouble(),
      status: json['status'] as String,
      joinedDate: json['joinedDate'] != null
          ? DateTime.parse(json['joinedDate'])
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user': user,
        'mess': mess is Mess ? (mess as Mess).toJson() : mess,
        'planName': planName,
        'billingRate': billingRate,
        'status': status,
        if (joinedDate != null) 'joinedDate': joinedDate!.toIso8601String(),
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  Mess? get messObject => mess is Mess ? mess as Mess : null;
  String get messId => mess is String ? mess as String : (mess as Mess).id;
}
