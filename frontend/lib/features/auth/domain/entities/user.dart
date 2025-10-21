// lib/features/auth/domain/entities/user.dart

class User {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String token;
  final bool hasPin; // Track if customer has set their PIN

  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.token,
    this.hasPin = false,
  });
}
