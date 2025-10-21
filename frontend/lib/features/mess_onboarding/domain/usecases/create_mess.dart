// lib/features/mess_onboarding/domain/usecases/create_mess.dart

import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';

class CreateMess {
  final MessOnboardingRepository repository;

  CreateMess(this.repository);

  Future<void> call(Map<String, dynamic> rawMessData) async {
    // Make a fully typed, sanitized clone so nested maps become Map<String, dynamic>
    final Map<String, dynamic> messData =
        Map<String, dynamic>.from(rawMessData);

    // --- CORE REQUIRED FIELDS ---
    _validateRequiredField(messData, 'name', 'Mess name');
    _validateRequiredField(messData, 'address', 'Address');
    _validateRequiredField(messData, 'city', 'City');
    _validateRequiredField(messData, 'managerContact', 'Manager contact');
    _validateRequiredField(messData, 'serviceType', 'Service type');
    _validateRequiredField(messData, 'cuisine', 'Cuisine type');

    // --- ENUM VALIDATION ---
    final serviceType = messData['serviceType'];
    final cuisine = messData['cuisine'];
    const allowedServiceTypes = ['Daily Only', 'Monthly Only', 'Both'];
    const allowedCuisine = ['Veg', 'Non-Veg', 'Both'];

    if (!allowedServiceTypes.contains(serviceType)) {
      throw Exception(
          'Invalid service type. Allowed: Daily Only, Monthly Only, Both.');
    }
    if (!allowedCuisine.contains(cuisine)) {
      throw Exception('Invalid cuisine. Allowed: Veg, Non-Veg, Both.');
    }

    // --- LOCATION: GeoJSON Point with [lng, lat] ---
    final loc = messData['location'];
    if (loc == null ||
        loc is! Map ||
        loc['type'] != 'Point' ||
        loc['coordinates'] is! List ||
        (loc['coordinates'] as List).length != 2) {
      throw Exception(
          'A valid location must be provided as GeoJSON Point [lng, lat].');
    }
    final coords = (loc['coordinates'] as List);
    if (coords[0] is! num || coords[1] is! num) {
      throw Exception('Location coordinates must be numeric [lng, lat].');
    }
    final double lng = (coords[0] as num).toDouble();
    final double lat = (coords[1] as num).toDouble();
    if (lng < -180 || lng > 180) {
      throw Exception('Longitude must be between -180 and 180.');
    }
    if (lat < -90 || lat > 90) {
      throw Exception('Latitude must be between -90 and 90.');
    }
    // Write back normalized doubles to ensure consistent typing
    messData['location'] = {
      'type': 'Point',
      'coordinates': [lng, lat],
    };

    // --- CONDITIONAL DAILY PRICING ---
    final includesDaily = serviceType == 'Daily Only' || serviceType == 'Both';
    if (includesDaily) {
      _validatePositiveNumber(
          messData, 'dailyThaliRate', 'Per-thali rate (dailyThaliRate)');
    }

    // --- MONTHLY PLANS (REQUIRED IF MONTHLY SERVICE) ---
    final includesMonthly =
        serviceType == 'Monthly Only' || serviceType == 'Both';
    if (includesMonthly) {
      if (messData['mealPlans'] == null ||
          messData['mealPlans'] is! List ||
          (messData['mealPlans'] as List).isEmpty) {
        throw Exception('At least one monthly meal plan is required.');
      }

      // Sanitize mealPlans => List<Map<String, dynamic>> with typed priceHistory
      final List<Map<String, dynamic>> plans =
          (messData['mealPlans'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map((plan) {
        // Validate plan name and perThaliRebateRate first
        _validateRequiredField(plan, 'name', 'Plan name');
        const allowedPlanNames = ['Lunch', 'Dinner', 'Full Day'];
        if (!allowedPlanNames.contains(plan['name'])) {
          throw Exception(
              'Invalid plan name. Allowed: Lunch, Dinner, Full Day.');
        }

        _validateNonNegativeNumber(plan, 'perThaliRebateRate',
            'Per-thali rebate rate (perThaliRebateRate)');

        // priceHistory must have at least one entry with positive price
        if (plan['priceHistory'] == null ||
            plan['priceHistory'] is! List ||
            (plan['priceHistory'] as List).isEmpty) {
          throw Exception(
              'Each meal plan must have an initial price in priceHistory.');
        }

        final List<Map<String, dynamic>> priceHistory =
            (plan['priceHistory'] as List<dynamic>)
                .map((p) => Map<String, dynamic>.from(p as Map))
                .toList();

        final first = priceHistory.first;
        if (first['price'] == null ||
            first['price'] is! num ||
            (first['price'] as num) <= 0) {
          throw Exception(
              'Each meal plan must have a valid initial positive price.');
        }

        return {
          ...plan,
          'priceHistory': priceHistory,
        };
      }).toList();

      messData['mealPlans'] = plans;
    } else {
      // Ensure mealPlans is absent or empty if monthly not offered (optional)
      if (messData['mealPlans'] != null &&
          (messData['mealPlans'] as List).isNotEmpty) {
        // It’s okay to keep it, but can also clear to avoid confusion
      }
    }

    // --- OPTIONAL POLICY FIELDS ---
    _validateOptionalNonNegativeNumber(
        messData, 'securityDeposit', 'Security deposit');
    _validateOptionalPositiveInt(messData, 'maxMembers', 'Maximum members');
    _validateOptionalNonNegativeInt(
        messData, 'rebateMinDays', 'Minimum consecutive leave days for rebate');
    _validateOptionalPercent(messData, 'toggleSkipRebatePercentage',
        'Toggle skip rebate percentage (0-100)');
    _validateOptionalNonNegativeNumber(
        messData, 'minMonthlyCharge', 'Minimum monthly charge');

    // --- TIMINGS (optional) ---
    // timings.lunch/dinner: start/end in HH:MM; if present, both required, and start < end
    _validateTimings(messData['timings']);

    // --- LEAVE DEADLINE (optional) ---
    _validateOptionalTimeString(messData, 'leaveApplicationDeadlineTime',
        'Leave application deadline time');

    // Submit strictly typed payload
    await repository.createMess(messData);
  }

  // ---------- Helpers ----------

  void _validateRequiredField(
      Map<String, dynamic> data, String key, String fieldName) {
    final v = data[key];
    if (v == null || (v is String && v.trim().isEmpty)) {
      throw Exception('$fieldName cannot be empty.');
    }
  }

  void _validatePositiveNumber(
      Map<String, dynamic> data, String key, String fieldName) {
    final v = data[key];
    if (v == null || v is! num || v <= 0) {
      throw Exception('$fieldName must be a positive number.');
    }
  }

  void _validateNonNegativeNumber(
      Map<String, dynamic> data, String key, String fieldName) {
    final v = data[key];
    if (v == null || v is! num || v < 0) {
      throw Exception('$fieldName must be a non-negative number.');
    }
  }

  void _validateOptionalNonNegativeNumber(
      Map<String, dynamic> data, String key, String fieldName) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! num || v < 0) {
      throw Exception('$fieldName must be a non-negative number.');
    }
  }

  void _validateOptionalPositiveInt(
      Map<String, dynamic> data, String key, String fieldName) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! int || v <= 0) {
      throw Exception('$fieldName must be a positive integer.');
    }
  }

  void _validateOptionalNonNegativeInt(
      Map<String, dynamic> data, String key, String fieldName) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! int || v < 0) {
      throw Exception('$fieldName must be a non-negative integer.');
    }
  }

  void _validateOptionalPercent(
      Map<String, dynamic> data, String key, String fieldName) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! num || v < 0 || v > 100) {
      throw Exception('$fieldName must be between 0 and 100.');
    }
  }

  void _validateOptionalTimeString(
      Map<String, dynamic> data, String key, String fieldName) {
    if (!data.containsKey(key) || data[key] == null) return;
    final v = data[key];
    if (v is! String || !_isValidTime(v)) {
      throw Exception('$fieldName must be in HH:MM format.');
    }
  }

  void _validateTimings(dynamic timings) {
    if (timings == null) return;
    if (timings is! Map) throw Exception('Timings must be an object.');

    Map<String, dynamic>? blockOf(String mealKey) {
      final b = timings[mealKey];
      if (b == null) return null;
      if (b is! Map)
        throw Exception(
            '$mealKey timings must be an object with start and end.');
      return Map<String, dynamic>.from(b);
    }

    void validateMealBlock(String mealKey) {
      final block = blockOf(mealKey);
      if (block == null) return;
      final start = block['start'];
      final end = block['end'];
      final bothPresent = start != null && end != null;
      if (!bothPresent) {
        throw Exception(
            '$mealKey timings must include both start and end in HH:MM.');
      }
      if (start is! String || !_isValidTime(start)) {
        throw Exception('$mealKey start must be in HH:MM.');
      }
      if (end is! String || !_isValidTime(end)) {
        throw Exception('$mealKey end must be in HH:MM.');
      }
      if (!_isStartBeforeEnd(start, end)) {
        throw Exception('$mealKey start must be before end.');
      }
    }

    validateMealBlock('lunch');
    validateMealBlock('dinner');
  }

  bool _isValidTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  bool _isStartBeforeEnd(String start, String end) {
    return _toMinutes(start) < _toMinutes(end);
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }
}
