// lib/features/manager_dashboard/data/datasources/manager_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/dashboard_stats_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/manager_member_model.dart';
import 'package:mess_management_system/features/manager_dashboard/data/models/weekly_menu_model.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_rating.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/today_attendance_member.dart';
import 'package:mess_management_system/features/customer_dashboard/data/models/invoice_model.dart';
import 'package:intl/intl.dart';

abstract class ManagerRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
  Future<List<ManagerMemberModel>> getMessMembers();
  Future<WeeklyMenuModel> getWeeklyMenu();

  Future<List<InvoiceModel>> getPaymentApprovals();
  Future<void> updateInvoiceStatus(String id, String status, {String? reason});

  Future<MessProfile> getMyMessProfile();
  Future<void> updateMyMess(
      {String? name, String? managerContact, String? address});

  Future<List<TodayAttendanceMember>> getTodayAttendance();
  Future<void> logMonthlyMealWithPin(
      String customerId, String managerPin, String mealType);
  Future<void> logDailyMeal(String mealType);

  Future<Map<DateTime, bool>> getMemberAttendance(
      String memberId, int year, int month);
  Future<List<InvoiceModel>> getMemberInvoices(String memberId);
}

class ManagerRemoteDataSourceImpl implements ManagerRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  // lib/features/manager_dashboard/data/datasources/manager_remote_datasource.dart
  @override
  Future<WeeklyMenuModel> getWeeklyMenu() async {
    // First get the manager’s mess to obtain messId
    final profile =
        await getMyMessProfile(); // already implemented in the same data source
    // Then call the public GET for weekly menu
    final res = await _dio.get('/messes/${profile.id}/menu');
    return WeeklyMenuModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    final res = await _dio.get('/managers/my-mess/dashboard-stats');
    return DashboardStatsModel.fromJson(res.data);
  }

  @override
  Future<List<ManagerMemberModel>> getMessMembers() async {
    final res = await _dio.get('/managers/my-mess/members');
    final list = (res.data as List?) ?? [];
    return list
        .map((e) => ManagerMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InvoiceModel>> getPaymentApprovals() async {
    final res = await _dio.get('/managers/my-mess/payment-approvals');
    final list = (res.data as List?) ?? [];
    return list
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateInvoiceStatus(String id, String status,
      {String? reason}) async {
    await _dio.put('/managers/invoices/$id/status', data: {
      'status': status,
      if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
    });
  }

  @override
  Future<MessProfile> getMyMessProfile() async {
    final res = await _dio.get('/managers/my-mess');
    final m = res.data as Map<String, dynamic>;
    final rating = MessRating(
      average: (m['averageRating'] as num?)?.toDouble(),
      count: m['reviewCount'] ?? 0,
    );
    final timings = m['timings'] as Map<String, dynamic>?;

    return MessProfile(
      id: m['_id'] ?? '',
      name: m['name'] ?? '',
      managerContact: m['managerContact'] ?? '',
      address: m['address'] ?? '',
      rating: rating,
      lunchStart: timings?['lunch']?['start'],
      lunchEnd: timings?['lunch']?['end'],
      dinnerStart: timings?['dinner']?['start'],
      dinnerEnd: timings?['dinner']?['end'],
    );
  }

  @override
  Future<void> updateMyMess(
      {String? name, String? managerContact, String? address}) async {
    await _dio.put('/managers/my-mess', data: {
      if (name != null) 'name': name,
      if (managerContact != null) 'managerContact': managerContact,
      if (address != null) 'address': address,
    });
  }

  // Helper to resolve current meal type using timings when present
  String _resolveMealType(MessProfile p) {
    final now = DateTime.now();
    bool _inRange(String? start, String? end) {
      if (start == null || end == null) return false;
      final fmt = DateFormat('HH:mm');
      try {
        final s = fmt.parse(start);
        final e = fmt.parse(end);
        final cur = DateTime(0, 1, 1, now.hour, now.minute);
        final ss = DateTime(0, 1, 1, s.hour, s.minute);
        final ee = DateTime(0, 1, 1, e.hour, e.minute);
        return cur.isAfter(ss) && cur.isBefore(ee);
      } catch (_) {
        return false;
      }
    }

    if (_inRange(p.lunchStart, p.lunchEnd)) return 'Lunch';
    if (_inRange(p.dinnerStart, p.dinnerEnd)) return 'Dinner';
    return now.hour < 16 ? 'Lunch' : 'Dinner';
  }

  @override
  Future<List<TodayAttendanceMember>> getTodayAttendance() async {
    final profile = await getMyMessProfile();
    final members = await getMessMembers();
    final res = await _dio.get('/kiosk/messes/${profile.id}/active-members');
    final notEaten = ((res.data as List?) ?? [])
        .map((e) => (e as Map)['userId'] as String)
        .toSet();

    return members.map((m) {
      final eaten = !notEaten.contains(m.id);
      return TodayAttendanceMember(
          userId: m.id, name: m.name, phone: m.phone, eaten: eaten);
    }).toList();
  }

  @override
  Future<void> logMonthlyMealWithPin(
      String customerId, String managerPin, String mealType) async {
    final profile = await getMyMessProfile();
    await _dio.post('/kiosk/messes/${profile.id}/manager-override', data: {
      'customerId': customerId,
      'managerPin': managerPin,
      'mealType': mealType,
    });
  }

  @override
  Future<void> logDailyMeal(String mealType) async {
    final profile = await getMyMessProfile();
    await _dio.post('/kiosk/messes/${profile.id}/log-daily', data: {
      'mealType': mealType,
    });
  }

  @override
  Future<Map<DateTime, bool>> getMemberAttendance(
      String memberId, int year, int month) async {
    final res = await _dio
        .get('/managers/members/$memberId/attendance', queryParameters: {
      'year': year,
      'month': month,
    });
    final list = (res.data as List?) ?? [];
    final map = <DateTime, bool>{};
    for (final e in list) {
      final d = DateTime.parse((e as Map)['date'] as String);
      final eaten = (e as Map)['eaten'] == true;
      map[DateTime(d.year, d.month, d.day)] = eaten;
    }
    return map;
  }

  @override
  Future<List<InvoiceModel>> getMemberInvoices(String memberId) async {
    final res = await _dio.get('/managers/members/$memberId/invoices');
    final list = (res.data as List?) ?? [];
    return list
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
