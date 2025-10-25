import 'mess.dart';

class Membership {
  final String id;
  final String user;
  final dynamic mess; // Can be String or Mess object
  final String planName;
  final double billingRate;
  final String status;
  final DateTime? joinedDate;
  final String? paymentStatus;
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
          ? DateTime.parse(json['joinedDate'] as String)
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }

  Mess? get messObject => mess is Mess ? mess as Mess : null;
  String get messId => mess is String ? mess as String : (mess as Mess).id;

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
