class User {
  final String id;
  final String name;
  final String phone;
  final String role;
  final Location? location;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'role': role,
      if (location != null) 'location': location!.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    Location? location,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      location: location ?? this.location,
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List).cast<double>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  Location copyWith({
    String? type,
    List<double>? coordinates,
  }) {
    return Location(
      type: type ?? this.type,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}
