// lib/models/review.dart
class Review {
  final String id;
  final dynamic user; // String or populated { _id, name }
  final String mess;
  final int rating; // 1..5
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.user,
    required this.mess,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return Review(
      id: json['_id'] as String,
      user: json['user'],
      mess: json['mess'] as String,
      rating: _toInt(json['rating']),
      comment: json['comment'] as String?,
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
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  String? get userName =>
      user is Map<String, dynamic> ? user['name'] as String? : null;
}
