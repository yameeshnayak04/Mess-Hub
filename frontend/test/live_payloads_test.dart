// Parses REAL backend responses through every model.
//
// `test/fixtures/live_payloads.json` is captured straight off a running server
// by `new_backend/scripts/contractCheck.js`:
//
//     CAPTURE_TO=../new_frontend/test/fixtures/live_payloads.json \
//       node scripts/contractCheck.js
//
// The point is that a hand-written fixture only proves the models agree with
// whatever the person writing them believed. This proves they agree with the
// server. Re-capture and re-run whenever a response shape changes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mess_management_app/models/attendance.dart';
import 'package:mess_management_app/models/bill.dart';
import 'package:mess_management_app/models/dashboard_stats.dart';
import 'package:mess_management_app/models/leave.dart';
import 'package:mess_management_app/models/membership.dart';
import 'package:mess_management_app/models/membership_details.dart';
import 'package:mess_management_app/models/menu.dart';
import 'package:mess_management_app/models/mess.dart';
import 'package:mess_management_app/models/review.dart';
import 'package:mess_management_app/models/user.dart';

void main() {
  final file = File('test/fixtures/live_payloads.json');
  final payloads = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> obj(String label) {
    final value = payloads[label];
    expect(value, isA<Map>(), reason: 'missing captured payload for "$label"');
    return Map<String, dynamic>.from(value as Map);
  }

  List<Map<String, dynamic>> list(String label) {
    final value = payloads[label];
    expect(value, isA<List>(), reason: 'missing captured payload for "$label"');
    return (value as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  group('auth', () {
    test('register and login return a usable user', () {
      for (final label in [
        'POST /auth/register (manager)',
        'POST /auth/register (customer)',
        'POST /auth/login',
      ]) {
        final user = User.fromJson(
            Map<String, dynamic>.from(obj(label)['user'] as Map));
        expect(user.id, isNotEmpty);
        expect(user.phone.length, 10);
        expect(user.role, anyOf('Customer', 'Manager'));
      }
    });

    test('GET /auth/me', () {
      final user = User.fromJson(obj('GET /auth/me'));
      expect(user.id, isNotEmpty);
      expect(user.name, isNotEmpty);
    });

    // Why the app must call /auth/me after signing in, and not just use the
    // auth response: hasMess lives only on the profile. Reading it off the
    // login payload leaves it null, and a null reads as "no mess yet", which
    // sends a manager who already has a mess back to the create-mess wizard.
    test('hasMess comes from the profile, never from login or register', () {
      for (final label in [
        'POST /auth/register (manager)',
        'POST /auth/login',
      ]) {
        final authUser = Map<String, dynamic>.from(obj(label)['user'] as Map);
        expect(authUser.containsKey('hasMess'), isFalse,
            reason: '$label must not be trusted for hasMess');
        expect(User.fromJson(authUser).hasMess, isNull);
      }

      final profile = User.fromJson(obj('GET /auth/me (manager with a mess)'));
      expect(profile.role, 'Manager');
      expect(profile.hasMess, isTrue);
      expect(profile.messId, isNotNull);
    });
  });

  group('mess', () {
    test('my-mess carries flat timings, nested rules and typed plans', () {
      final mess = Mess.fromJson(obj('GET /messes/my-mess'));

      expect(mess.timings.lunchStart, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(mess.timings.dinnerEnd, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(mess.location.latitude, isNot(0));
      expect(mess.rules.minLeaveDaysForRebate, greaterThan(0));
      expect(mess.rules.rebatePerThaliRupees, greaterThanOrEqualTo(0));

      expect(mess.plans, isNotEmpty);
      for (final plan in mess.plans) {
        expect(plan.id, isNotEmpty);
        expect(plan.meals, isNotEmpty);
        // The meals list is real data - nothing here reads the plan's name.
        expect(plan.meals.every((m) => m == 'Lunch' || m == 'Dinner'), isTrue);
      }
    });

    test('discover carries a distance', () {
      final messes =
          list('GET /messes/discover').map(Mess.fromJson).toList();
      expect(messes, isNotEmpty);
      expect(messes.first.distanceMetres, isNotNull);
    });

    test('mess by id carries live status and plans', () {
      final mess = Mess.fromJson(obj('GET /messes/:id'));
      expect(mess.plans, isNotEmpty);
      expect(mess.liveStatus, anyOf('Open', 'Closed'));
    });

    test('plan list and plan update', () {
      final plans =
          list('GET /messes/my-mess/plans').map(MessPlan.fromJson).toList();
      expect(plans, isNotEmpty);

      final updated = MessPlan.fromJson(obj('PATCH /messes/my-mess/plans/:id'));
      expect(updated.rateRupees, greaterThan(0));
      expect(updated.meals, isNotEmpty);
    });

    test('create returns the ids the wizard needs', () {
      final created = obj('POST /messes');
      expect(created['messId'], isNotNull);
      final plans = (created['plans'] as List)
          .map((e) => MessPlan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      expect(plans, isNotEmpty);
      expect(plans.first.id, isNotEmpty);
    });
  });

  group('membership', () {
    test('join, approve, mine and mess listings all parse', () {
      for (final label in [
        'POST /memberships/join/:messId',
        'POST /memberships/:id/approve',
      ]) {
        final membership = Membership.fromJson(obj(label));
        expect(membership.id, isNotEmpty);
        expect(membership.planId, isNotEmpty);
        expect(membership.memberName, isNotNull);
        expect(membership.rateRupees, greaterThan(0));
      }

      for (final label in ['GET /memberships/mine', 'GET /memberships/mess']) {
        for (final row in list(label)) {
          final membership = Membership.fromJson(row);
          expect(membership.id, isNotEmpty);
          expect(membership.messId, isNotEmpty);
        }
      }
    });

    test('details payload', () {
      final details = MembershipDetails.fromJson(obj('GET /memberships/:id'));
      expect(details.membership.id, isNotEmpty);
      expect(details.totalRecorded, greaterThanOrEqualTo(0));
    });

    test('discontinue returns a bill in rupees, not paise', () {
      final payload = obj('POST /memberships/:id/discontinue');
      final bill =
          Bill.fromJson(Map<String, dynamic>.from(payload['bill'] as Map));
      expect(bill.id, isNotEmpty);
      // A raw paise row would land in the tens of thousands here.
      expect(bill.totalRupees, lessThan(100000));
      expect(bill.periodDate, isNotNull);
    });
  });

  group('dashboard', () {
    test('stats and member rows', () {
      final stats = DashboardStats.fromJson(obj('GET /messes/my-mess/dashboard'));
      // The model reads the nested `counts` object but exposes the numbers
      // flat, so screens do not have to reach through two levels.
      expect(stats.eligible, greaterThanOrEqualTo(0));
      expect(stats.remaining, greaterThanOrEqualTo(0));
      expect(stats.meal, anyOf('Lunch', 'Dinner'));

      for (final row in list('GET /messes/my-mess/dashboard/members')) {
        final member = DashboardMember.fromJson(row);
        expect(member.membershipId, isNotEmpty);
        expect(member.name, isNotEmpty);
      }
    });
  });

  group('menu, leave, attendance', () {
    test('menu', () {
      final menu = Menu.fromJson(obj('PUT /menus/my-mess'));
      expect(menu.serviceDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(menu.date, isNotNull);
      expect(menu.lunchItems, isNotEmpty);
    });

    test('leave dates are plain calendar days', () {
      final leave = Leave.fromJson(obj('POST /leave/:membershipId'));
      expect(leave.startDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(leave.endDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(leave.totalDays, greaterThan(0));

      for (final row in list('GET /leave/:membershipId')) {
        expect(Leave.fromJson(row).start, isNotNull);
      }
    });

    // Skipping is time-gated to the meal window, so its payload is only
    // captured when the run happens to fall inside one. The kiosk check-in
    // returns the same AttendanceRecord shape and always is captured, because
    // kioskContractCheck.js builds a window around itself.
    test('kiosk check-in returns a record with a plain date', () {
      final record =
          AttendanceRecord.fromJson(obj('POST /attendance/kiosk/mark'));
      expect(record.serviceDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(record.membershipId, isNotEmpty);
      expect(record.status, 'Present');
      expect(record.meal, anyOf('Lunch', 'Dinner'));
    });

    test('calendar is day-grouped', () {
      final calendar = AttendanceCalendar.fromJson(
          obj('GET /attendance/:membershipId/calendar'));
      expect(calendar.month, inInclusiveRange(1, 12));
      for (final day in calendar.days) {
        expect(day.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(day.dateTime, isNotNull);
        expect(day.meals, isNotEmpty);
      }
    });
  });

  group('reviews', () {
    test('upsert, list and mine all return the same public shape', () {
      for (final label in ['PUT /reviews/:messId', 'GET /reviews/:messId/mine']) {
        final review = Review.fromJson(obj(label));
        expect(review.id, isNotEmpty);
        expect(review.rating, inInclusiveRange(1, 5));
        // The upsert used to answer with a raw row, which had no author name.
        expect(review.authorName, isNotNull);
        expect(review.createdAt, isNotNull);
      }

      for (final row in list('GET /reviews/:messId')) {
        expect(Review.fromJson(row).rating, inInclusiveRange(1, 5));
      }
    });
  });

  group('billing', () {
    test('bills are rupees with a calendar period', () {
      for (final label in ['GET /billing/membership/:id', 'GET /billing/mess']) {
        for (final row in list(label)) {
          final bill = Bill.fromJson(row);
          expect(bill.id, isNotEmpty);
          expect(bill.period, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
          expect(bill.periodDate, isNotNull);
          expect(bill.status, anyOf('Due', 'Pending Approval', 'Paid'));
          expect(bill.totalRupees, greaterThanOrEqualTo(0));
        }
      }
    });

    test('history wraps the bill', () {
      final payload = obj('GET /billing/:id/history');
      final bill =
          Bill.fromJson(Map<String, dynamic>.from(payload['bill'] as Map));
      expect(bill.id, isNotEmpty);
      expect(payload['events'], isA<List>());
    });
  });
}
