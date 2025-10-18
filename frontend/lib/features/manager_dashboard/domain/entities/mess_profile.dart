// lib/features/manager_dashboard/domain/entities/mess_profile.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_rating.dart';

class MessProfile {
  final String id;
  final String name;
  final String managerContact;
  final String address;
  final MessRating rating;
  final String? lunchStart;
  final String? lunchEnd;
  final String? dinnerStart;
  final String? dinnerEnd;

  const MessProfile({
    required this.id,
    required this.name,
    required this.managerContact,
    required this.address,
    required this.rating,
    this.lunchStart,
    this.lunchEnd,
    this.dinnerStart,
    this.dinnerEnd,
  });
}
