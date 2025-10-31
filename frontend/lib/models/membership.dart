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
    // Check if messData is a Map (populated) and not null
    if (messData is Map<String, dynamic>) {
      messData = Mess.fromJson(messData);
    }
    // if it's not a map, it remains as a String ID (or null if backend sent null)

    return Membership(
      id: json['_id'] as String,
      user: json['user'] as String,
      mess: messData, // messData is now a Mess object, String, or null
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

  // Safely get the Mess object if it's populated
  Mess? get messObject => mess is Mess ? mess as Mess : null;
  // Safely get the messId regardless of population
  String? get messId {
    if (mess is Mess) return (mess as Mess).id;
    if (mess is String) return mess as String;
    return null;
  }

  // *** ADD THIS METHOD ***
  Membership copyWith({
    String? id,
    String? user,
    dynamic mess,
    String? planName,
    double? billingRate,
    String? status,
    DateTime? joinedDate,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Membership(
      id: id ?? this.id,
      user: user ?? this.user,
      mess: mess ?? this.mess,
      planName: planName ?? this.planName,
      billingRate: billingRate ?? this.billingRate,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
