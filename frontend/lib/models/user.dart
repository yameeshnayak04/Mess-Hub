// lib/models/user.dart
import '../core/utils/json_parse.dart';

/// The backend sends and accepts a plain `{ longitude, latitude }` object.
/// (The old API used GeoJSON `{ type: 'Point', coordinates: [lng, lat] }`;
/// nothing on the wire uses that shape any more.)
class Location {
  final double longitude;
  final double latitude;

  Location({required this.longitude, required this.latitude});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        longitude: asDouble(json['longitude']) ?? 0.0,
        latitude: asDouble(json['latitude']) ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
      };
}

class User {
  final String id;
  final String name;
  final String phone;
  final String role; // 'Customer' | 'Manager'

  /// Only present on GET /auth/me, and only for managers.
  final bool? hasMess;
  final String? messId;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.hasMess,
    this.messId,
  });

  /// Note: the backend never returns the user's location. It is write-only -
  /// sent at registration, used server-side for "messes near me".
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asId(json['id']),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String? ?? 'Customer',
        hasMess: json['hasMess'] as bool?,
        messId: asNullableId(json['messId']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        if (hasMess != null) 'hasMess': hasMess,
        if (messId != null) 'messId': messId,
      };

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    bool? hasMess,
    String? messId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hasMess: hasMess ?? this.hasMess,
      messId: messId ?? this.messId,
    );
  }
}
