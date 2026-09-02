// lib/models/membership_details.dart
import '../core/utils/json_parse.dart';
import 'bill.dart';
import 'membership.dart';
import 'menu.dart';

/// Everything the membership dashboard needs, in the single payload the
/// backend returns from GET /memberships/:id.
class MembershipDetails {
  final Membership membership;
  final int present;
  final int skipped;
  final int leave;
  final int absent;
  final List<Bill> recentBills;
  final Menu? todaysMenu;

  MembershipDetails({
    required this.membership,
    required this.present,
    required this.skipped,
    required this.leave,
    required this.absent,
    required this.recentBills,
    this.todaysMenu,
  });

  factory MembershipDetails.fromJson(Map<String, dynamic> json) {
    final summary = (json['monthToDate'] is Map)
        ? Map<String, dynamic>.from(json['monthToDate'] as Map)
        : const <String, dynamic>{};

    return MembershipDetails(
      membership: Membership.fromJson(
          Map<String, dynamic>.from(json['membership'] as Map)),
      present: asInt(summary['present']) ?? 0,
      skipped: asInt(summary['skipped']) ?? 0,
      leave: asInt(summary['leave']) ?? 0,
      absent: asInt(summary['absent']) ?? 0,
      recentBills: (json['recentBills'] is List)
          ? (json['recentBills'] as List)
              .whereType<Map>()
              .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <Bill>[],
      todaysMenu: json['todaysMenu'] is Map
          ? Menu.fromJson(Map<String, dynamic>.from(json['todaysMenu'] as Map))
          : null,
    );
  }

  int get totalRecorded => present + skipped + leave + absent;
}
