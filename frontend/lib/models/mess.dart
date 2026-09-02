// lib/models/mess.dart
import 'user.dart';
import '../core/utils/json_parse.dart';

class Mess {
  final String id;
  final String messName;
  final String? messImage;
  final Location location; // { longitude, latitude }
  final String address;
  final String city;
  final String contactPhone;
  final String serviceType; // 'Monthly Only' | 'Both Daily & Monthly'
  final String cuisine; // 'Veg' | 'Non-Veg' | 'Both'
  final int? maxCapacity;
  final bool tiffinService;
  final String basicThaliDetails;
  final MessTimings timings;
  final List<MessPlan> plans; // only on /messes/:id and /messes/my-mess
  final double? dailyThaliRateRupees;
  final MessRules rules;
  final MessRating rating;

  /// Only on /messes/discover.
  final double? distanceMetres;

  /// Only on /messes/:id - whether a meal is being served right now.
  final String? liveStatus; // 'Open' | 'Closed'
  final String? currentMeal; // 'Lunch' | 'Dinner' | null

  Mess({
    required this.id,
    required this.messName,
    this.messImage,
    required this.location,
    required this.address,
    required this.city,
    required this.contactPhone,
    required this.serviceType,
    required this.cuisine,
    this.maxCapacity,
    required this.tiffinService,
    required this.basicThaliDetails,
    required this.timings,
    required this.plans,
    this.dailyThaliRateRupees,
    required this.rules,
    required this.rating,
    this.distanceMetres,
    this.liveStatus,
    this.currentMeal,
  });

  factory Mess.fromJson(Map<String, dynamic> json) {
    return Mess(
      id: asId(json['id']),
      messName: json['messName'] as String? ?? '',
      messImage: json['messImage'] as String?,
      location: json['location'] is Map
          ? Location.fromJson(
              Map<String, dynamic>.from(json['location'] as Map))
          : Location(longitude: 0, latitude: 0),
      address: json['address'] as String? ?? 'N/A',
      city: json['city'] as String? ?? 'N/A',
      contactPhone: json['contactPhone'] as String? ?? 'N/A',
      serviceType: json['serviceType'] as String? ?? 'N/A',
      cuisine: json['cuisine'] as String? ?? 'N/A',
      maxCapacity: asInt(json['maxCapacity']),
      tiffinService: asBool(json['tiffinService']),
      basicThaliDetails: json['basicThaliDetails'] as String? ?? '',
      timings: json['timings'] is Map
          ? MessTimings.fromJson(
              Map<String, dynamic>.from(json['timings'] as Map))
          : MessTimings.empty(),
      plans: (json['plans'] is List)
          ? (json['plans'] as List)
              .whereType<Map>()
              .map((e) => MessPlan.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <MessPlan>[],
      dailyThaliRateRupees: asDouble(json['dailyThaliRateRupees']),
      rules: json['rules'] is Map
          ? MessRules.fromJson(Map<String, dynamic>.from(json['rules'] as Map))
          : MessRules.empty(),
      rating: json['rating'] is Map
          ? MessRating.fromJson(
              Map<String, dynamic>.from(json['rating'] as Map))
          : const MessRating(average: 0, count: 0),
      distanceMetres: asDouble(json['distanceMetres']),
      liveStatus: json['liveStatus'] as String?,
      currentMeal: json['currentMeal'] as String?,
    );
  }

  Mess copyWith({
    String? id,
    String? messName,
    String? messImage,
    Location? location,
    String? address,
    String? city,
    String? contactPhone,
    String? serviceType,
    String? cuisine,
    int? maxCapacity,
    bool? tiffinService,
    String? basicThaliDetails,
    MessTimings? timings,
    List<MessPlan>? plans,
    double? dailyThaliRateRupees,
    MessRules? rules,
    MessRating? rating,
    double? distanceMetres,
    String? liveStatus,
    String? currentMeal,
  }) {
    return Mess(
      id: id ?? this.id,
      messName: messName ?? this.messName,
      messImage: messImage ?? this.messImage,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      contactPhone: contactPhone ?? this.contactPhone,
      serviceType: serviceType ?? this.serviceType,
      cuisine: cuisine ?? this.cuisine,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      tiffinService: tiffinService ?? this.tiffinService,
      basicThaliDetails: basicThaliDetails ?? this.basicThaliDetails,
      timings: timings ?? this.timings,
      plans: plans ?? this.plans,
      dailyThaliRateRupees: dailyThaliRateRupees ?? this.dailyThaliRateRupees,
      rules: rules ?? this.rules,
      rating: rating ?? this.rating,
      distanceMetres: distanceMetres ?? this.distanceMetres,
      liveStatus: liveStatus ?? this.liveStatus,
      currentMeal: currentMeal ?? this.currentMeal,
    );
  }
}

/// Flat HH:MM strings, matching the backend's four TIME columns.
class MessTimings {
  final String lunchStart;
  final String lunchEnd;
  final String dinnerStart;
  final String dinnerEnd;

  MessTimings({
    required this.lunchStart,
    required this.lunchEnd,
    required this.dinnerStart,
    required this.dinnerEnd,
  });

  factory MessTimings.empty() => MessTimings(
        lunchStart: '00:00',
        lunchEnd: '00:00',
        dinnerStart: '00:00',
        dinnerEnd: '00:00',
      );

  factory MessTimings.fromJson(Map<String, dynamic> json) => MessTimings(
        lunchStart: json['lunchStart'] as String? ?? '00:00',
        lunchEnd: json['lunchEnd'] as String? ?? '00:00',
        dinnerStart: json['dinnerStart'] as String? ?? '00:00',
        dinnerEnd: json['dinnerEnd'] as String? ?? '00:00',
      );

  Map<String, dynamic> toJson() => {
        'lunchStart': lunchStart,
        'lunchEnd': lunchEnd,
        'dinnerStart': dinnerStart,
        'dinnerEnd': dinnerEnd,
      };
}

/// A plan now has a real id and an explicit list of meals it covers, instead
/// of the meals being inferred from its name.
class MessPlan {
  final String id;
  final String messId;
  final String name;
  final double rateRupees;
  final List<String> meals; // 'Lunch' and/or 'Dinner'
  final bool isActive;

  MessPlan({
    required this.id,
    required this.messId,
    required this.name,
    required this.rateRupees,
    required this.meals,
    this.isActive = true,
  });

  factory MessPlan.fromJson(Map<String, dynamic> json) => MessPlan(
        id: asId(json['id']),
        messId: asId(json['messId']),
        name: json['name'] as String? ?? '',
        rateRupees: asDouble(json['rateRupees']) ?? 0,
        meals: asStringList(json['meals']),
        isActive: json['isActive'] == null ? true : asBool(json['isActive']),
      );

  /// The request shape for creating/updating a plan.
  Map<String, dynamic> toRequestJson() => {
        'name': name,
        'rateRupees': rateRupees,
        'meals': meals,
      };

  bool get includesLunch => meals.contains('Lunch');
  bool get includesDinner => meals.contains('Dinner');

  String get mealsLabel {
    if (includesLunch && includesDinner) return 'Lunch + Dinner';
    if (includesLunch) return 'Lunch only';
    if (includesDinner) return 'Dinner only';
    return 'No meals';
  }
}

class MessRules {
  final int minLeaveDaysForRebate;
  final double rebatePerThaliRupees;
  final double skipAllowancePercent;
  final bool allowAbsentRebate;
  final double? minMonthlyChargeRupees;

  /// Advertised caution money. The app only displays it - the backend does not
  /// collect, track or bill it.
  final double? securityDepositRupees;

  MessRules({
    required this.minLeaveDaysForRebate,
    required this.rebatePerThaliRupees,
    required this.skipAllowancePercent,
    this.allowAbsentRebate = false,
    this.minMonthlyChargeRupees,
    this.securityDepositRupees,
  });

  factory MessRules.empty() => MessRules(
        minLeaveDaysForRebate: 1,
        rebatePerThaliRupees: 0,
        skipAllowancePercent: 0,
      );

  factory MessRules.fromJson(Map<String, dynamic> json) => MessRules(
        minLeaveDaysForRebate: asInt(json['minLeaveDaysForRebate']) ?? 1,
        rebatePerThaliRupees: asDouble(json['rebatePerThaliRupees']) ?? 0,
        skipAllowancePercent: asDouble(json['skipAllowancePercent']) ?? 0,
        allowAbsentRebate: asBool(json['allowAbsentRebate']),
        minMonthlyChargeRupees: asDouble(json['minMonthlyChargeRupees']),
        securityDepositRupees: asDouble(json['securityDepositRupees']),
      );

  Map<String, dynamic> toJson() => {
        'minLeaveDaysForRebate': minLeaveDaysForRebate,
        'rebatePerThaliRupees': rebatePerThaliRupees,
        'skipAllowancePercent': skipAllowancePercent,
        'allowAbsentRebate': allowAbsentRebate,
        if (minMonthlyChargeRupees != null)
          'minMonthlyChargeRupees': minMonthlyChargeRupees,
        if (securityDepositRupees != null)
          'securityDepositRupees': securityDepositRupees,
      };
}

class MessRating {
  final double average;
  final int count;

  const MessRating({required this.average, required this.count});

  factory MessRating.fromJson(Map<String, dynamic> json) => MessRating(
        average: asDouble(json['average']) ?? 0,
        count: asInt(json['count']) ?? 0,
      );
}
