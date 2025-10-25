class Review {
  final String id;
  final dynamic user; // Can be String or Map
  final String mess;
  final int rating;
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
    return Review(
      id: json['_id'] as String,
      user: json['user'],
      mess: json['mess'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
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
      'rating': rating,
      if (comment != null) 'comment': comment,
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
}
