class Leave {
  final String id;
  final dynamic user; // Can be String or Map
  final String mess;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isRebateEligible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Leave({
    required this.id,
    required this.user,
    required this.mess,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isRebateEligible,
    this.createdAt,
    this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'] as String,
      user: json['user'],
      mess: json['mess'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      isRebateEligible: json['isRebateEligible'] as bool,
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
      'mess': mess,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'isRebateEligible': isRebateEligible,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  String? get userName {
    if (user is Map<String, dynamic>) {
      return user['name'] as String?;
    }
    return null;
  }

  String? get userPhone {
    if (user is Map<String, dynamic>) {
      return user['phone'] as String?;
    }
    return null;
  }
}
