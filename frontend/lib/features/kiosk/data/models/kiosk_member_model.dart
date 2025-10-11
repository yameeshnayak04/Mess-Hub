// This file defines the data structure for a member displayed on the Kiosk.

class KioskMember {
  final String userId;
  final String name;
  final String? photoUrl; // Photo URL is optional

  const KioskMember({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  // Factory constructor to create an instance from a JSON map.
  factory KioskMember.fromJson(Map<String, dynamic> json) {
    return KioskMember(
      userId: json['userId'],
      name: json['name'],
      photoUrl: json['photoUrl'],
    );
  }
}
