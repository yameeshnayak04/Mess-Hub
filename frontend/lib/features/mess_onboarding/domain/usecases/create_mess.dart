// lib/features/mess_onboarding/domain/usecases/create_mess.dart
import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';

class CreateMess {
  final MessOnboardingRepository repository;
  CreateMess(this.repository);

  Future call(Map rawMessData) async {
    final Map messData = Map.from(rawMessData);

    // Required fields
    _req(messData, 'name', 'Mess name');
    _req(messData, 'address', 'Address');
    _req(messData, 'city', 'City');
    _req(messData, 'managerContact', 'Manager contact');
    _req(messData, 'serviceType', 'Service type');
    _req(messData, 'cuisine', 'Cuisine type');

    // Enums
    final serviceType = messData['serviceType'];
    final cuisine = messData['cuisine'];
    const allowedServiceTypes = ['Monthly Only', 'Both'];
    const allowedCuisine = ['Veg', 'Non-Veg', 'Both'];
    if (!allowedServiceTypes.contains(serviceType)) {
      throw Exception('Invalid service type. Allowed: Monthly Only, Both.');
    }
    if (!allowedCuisine.contains(cuisine)) {
      throw Exception('Invalid cuisine. Allowed: Veg, Non-Veg, Both.');
    }

    // Contact: 10-digit
    final contact = '${messData['managerContact']}'.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(contact)) {
      throw Exception('Manager contact must be a valid 10-digit number.');
    }
    messData['managerContact'] = contact;

    // Location: GeoJSON Point [lng, lat]
    final loc = messData['location'];
    if (loc == null ||
        loc is! Map ||
        loc['type'] != 'Point' ||
        loc['coordinates'] is! List ||
        (loc['coordinates'] as List).length != 2) {
      throw Exception('Location must be a GeoJSON Point with [lng, lat].');
    }
    final coords = (loc['coordinates'] as List);
    if (coords[0] is! num || coords[1] is! num) {
      throw Exception('Location coordinates must be numeric [lng, lat].');
    }
    final double lng = (coords[0] as num).toDouble();
    final double lat = (coords[1] as num).toDouble();
    if (lng < -180 || lng > 180)
      throw Exception('Longitude must be -180..180.');
    if (lat < -90 || lat > 90) throw Exception('Latitude must be -90..90.');
    messData['location'] = {
      'type': 'Point',
      'coordinates': [lng, lat]
    };

    // Pricing: daily only when Both
    final includesDaily = serviceType == 'Both';
    if (includesDaily) {
      _posNum(messData, 'dailyThaliRate', 'Per-thali rate (dailyThaliRate)');
    }

    // Monthly plans: required for Monthly Only and Both
    if (messData['mealPlans'] == null ||
        messData['mealPlans'] is! List ||
        (messData['mealPlans'] as List).isEmpty) {
      throw Exception('At least one monthly meal plan is required.');
    }
    final List<Map<String, dynamic>> plans = (messData['mealPlans'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((plan) {
      _req(plan, 'name', 'Plan name');
      const allowedPlanNames = ['Lunch', 'Dinner', 'Full Day'];
      if (!allowedPlanNames.contains(plan['name'])) {
        throw Exception('Invalid plan name. Allowed: Lunch, Dinner, Full Day.');
      }
      _nonNegNum(plan, 'perThaliRebateRate',
          'Per-thali rebate rate (perThaliRebateRate)');
      if (plan['priceHistory'] == null ||
          plan['priceHistory'] is! List ||
          (plan['priceHistory'] as List).isEmpty) {
        throw Exception('Each plan must have an initial price entry.');
      }
      final List<Map<String, dynamic>> priceHistory =
          (plan['priceHistory'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
      final first = priceHistory.first;
      if (first['price'] == null ||
          first['price'] is! num ||
          (first['price'] as num) <= 0) {
        throw Exception('Initial price must be a positive number.');
      }
      return {...plan, 'priceHistory': priceHistory};
    }).toList();
    messData['mealPlans'] = plans;

    // Optional policy fields
    _optNonNegNum(messData, 'securityDeposit', 'Security deposit');
    _optPosInt(messData, 'maxMembers', 'Maximum members');
    _optNonNegInt(
        messData, 'rebateMinDays', 'Minimum consecutive leave days for rebate');
    _optPercent(messData, 'toggleSkipRebatePercentage',
        'Toggle skip rebate percentage (0-100)');
    _optNonNegNum(messData, 'minMonthlyCharge', 'Minimum monthly charge');

    // Timings
    _optTimings(messData['timings']);

    // Leave deadline
    _optTime(messData, 'leaveApplicationDeadlineTime',
        'Leave application deadline time');

    await repository.createMess(Map<String, dynamic>.from(messData));
  }

  void _req(Map data, String key, String field) {
    final v = data[key];
    if (v == null || (v is String && v.trim().isEmpty))
      throw Exception('$field cannot be empty.');
  }

  void _posNum(Map data, String key, String field) {
    final v = data[key];
    if (v == null || v is! num || v <= 0)
      throw Exception('$field must be a positive number.');
  }

  void _nonNegNum(Map data, String key, String field) {
    final v = data[key];
    if (v == null || v is! num || v < 0)
      throw Exception('$field must be non-negative.');
  }

  void _optNonNegNum(Map data, String key, String field) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! num || v < 0) throw Exception('$field must be non-negative.');
  }

  void _optPosInt(Map data, String key, String field) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! int || v <= 0)
      throw Exception('$field must be a positive integer.');
  }

  void _optNonNegInt(Map data, String key, String field) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! int || v < 0)
      throw Exception('$field must be a non-negative integer.');
  }

  void _optPercent(Map data, String key, String field) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! num || v < 0 || v > 100)
      throw Exception('$field must be between 0 and 100.');
  }

  void _optTime(Map data, String key, String field) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! String || !_isHHmm(v))
      throw Exception('$field must be in HH:MM format.');
  }

  void _optTimings(dynamic timings) {
    if (timings == null) return;
    if (timings is! Map) throw Exception('Timings must be an object.');
    Map<String, dynamic>? blockOf(String meal) {
      final b = timings[meal];
      if (b == null) return null;
      if (b is! Map)
        throw Exception('$meal timings must be an object with start and end.');
      return Map<String, dynamic>.from(b);
    }

    void validate(String meal) {
      final b = blockOf(meal);
      if (b == null) return;
      final start = b['start'], end = b['end'];
      if (start == null || end == null)
        throw Exception('$meal timings must include start and end.');
      if (start is! String || !_isHHmm(start))
        throw Exception('$meal start must be HH:MM.');
      if (end is! String || !_isHHmm(end))
        throw Exception('$meal end must be HH:MM.');
      if (!_lt(start, end)) throw Exception('$meal start must be before end.');
    }

    validate('lunch');
    validate('dinner');
  }

  bool _isHHmm(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    return h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  bool _lt(String a, String b) => _mins(a) < _mins(b);
  int _mins(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}
