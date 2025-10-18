// lib/features/kiosk/data/models/kiosk_member_model.dart
class KioskMember {
  final String userId;
  final String name;
  final String? phone;
  final String? photoUrl;
  final bool eaten;

  const KioskMember({
    required this.userId,
    required this.name,
    this.phone,
    this.photoUrl,
    this.eaten = false,
  });

  // Safely coerce values from multiple shapes:
  // { userId, name, phone, photoUrl, eaten } OR { user: {_id, name, phone, photoUrl}, hasEaten }
  factory KioskMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? id = json['userId']?.toString() ??
        json['_id']?.toString() ??
        (user is Map ? user['_id']?.toString() : null);
    String? nm = json['name']?.toString() ??
        (user is Map ? user['name']?.toString() : null) ??
        (user is Map
            ? [user['firstName'], user['lastName']]
                .where((e) => (e ?? '').toString().isNotEmpty)
                .join(' ')
            : null);
    final ph = json['phone']?.toString() ??
        (user is Map ? user['phone']?.toString() : null);
    final avatar = json['photoUrl']?.toString() ??
        json['avatar']?.toString() ??
        (user is Map ? (user['photoUrl'] ?? user['avatar'])?.toString() : null);
    final eatenFlag = (json['eaten'] == true) ||
        (json['hasEaten'] == true) ||
        (json['status']?.toString().toLowerCase() == 'eaten');

    // Final fallbacks to avoid runtime type errors
    id ??= '';
    nm ??= '';

    return KioskMember(
      userId: id,
      name: nm,
      phone: ph,
      photoUrl: avatar,
      eaten: eatenFlag,
    );
  }
}
