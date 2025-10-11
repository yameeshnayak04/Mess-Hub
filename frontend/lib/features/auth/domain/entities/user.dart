// This file defines the User entity, a pure Dart object.
// In Clean Architecture, entities represent the core business objects.

class User {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String token;

  // The constructor for creating a User instance.
  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.token,
  });
}
