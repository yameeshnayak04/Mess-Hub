// lib/models/leave.dart
class Leave {
  final String id;
  final dynamic user; // String or populated { _id, name, phone }
  final String mess;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Leave({
    required this.id,
    required this.user,
    required this.mess,
    required this.startDate,
    required this.endDate,
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
        'startDate': startDate.toIso8601String(), // <-- Corrected
        'endDate': endDate.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  String? get userName =>
      user is Map<String, dynamic> ? user['name'] as String? : null;
  String? get userPhone =>
      user is Map<String, dynamic> ? user['phone'] as String? : null;
}
