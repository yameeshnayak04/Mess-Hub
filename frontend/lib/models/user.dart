// lib/models/user.dart
class Location {
  final String type; // 'Point'
  final List<double> coordinates; // [lng, lat]

  Location({required this.type, required this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

class User {
  final String id;
  final String name;
  final String phone;
  final String role; // 'Customer' | 'Manager'
  final Location? location; // present for customers
  final bool? hasMess;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.location,
    this.hasMess,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final locJson = json['location'];
    Location? loc;
    if (locJson is Map<String, dynamic> &&
        locJson['type'] is String &&
        locJson['coordinates'] is List) {
      loc = Location.fromJson(locJson);
    }
    return User(
      id: json['_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      location: loc,
      hasMess: json['hasMess'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'phone': phone,
        'role': role,
        if (location != null) 'location': location!.toJson(),
        if (hasMess != null) 'hasMess': hasMess,
      };

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    Location? location,
    bool? hasMess,
    bool clearLocation = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      location: clearLocation ? null : (location ?? this.location),
      hasMess: hasMess ?? this.hasMess,
    );
  }
}
