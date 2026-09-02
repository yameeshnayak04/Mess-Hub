// lib/models/review.dart
import '../core/utils/json_parse.dart';

class Review {
  final String id;
  final int rating; // 1..5
  final String? comment;

  /// The backend flattens the author's name onto the review, so there is no
  /// nested user object to dig into any more.
  final String? authorName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: asId(json['id']),
        rating: asInt(json['rating']) ?? 0,
        comment: json['comment'] as String?,
        authorName: json['authorName'] as String?,
        createdAt: parseTimestamp(json['createdAt']),
        updatedAt: parseTimestamp(json['updatedAt']),
      );
}
