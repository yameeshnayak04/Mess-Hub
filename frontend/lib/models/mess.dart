// lib/models/mess.dart
import 'user.dart';

class Mess {
  final String id;
  final String messName;
  final String? messImage;
  final Location
      location; // GeoJSON: { type: 'Point', coordinates: [lng, lat] }
  final String address;
  final String city;
  final String contactPhone;
  final String serviceType; // 'Monthly Only' | 'Both Daily & Monthly'
  final String cuisine; // 'Veg' | 'Non-Veg' | 'Both'
  final int? maxCapacity;
  final bool tiffinService;
  final String basicThaliDetails;
  final MessTimings timings; // strings "HH:mm"
  final List<MessPlan> plans; // typed
  final double?
      dailyThaliRate; // required if serviceType == 'Both Daily & Monthly'
  final MessRules rules;
  final double? averageRating; // computed/populated
  final int? reviewCount; // computed/populated
  final double? distance; // meters from /mess/discover

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
    this.dailyThaliRate,
    required this.rules,
    this.averageRating,
    this.reviewCount,
    this.distance,
  });

  factory Mess.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      return double.tryParse(s);
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      final s = v.toString().trim();
      return int.tryParse(s);
    }

    List<MessPlan> _parsePlans(dynamic jsonList) {
      if (jsonList is List) {
        return jsonList
            .where((e) => e is Map)
            .map((e) => MessPlan.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <MessPlan>[];
    }

    return Mess(
      id: json['_id'] as String,
      messName: json['messName'] as String,
      messImage: json['messImage'] as String?,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : Location(type: 'Point', coordinates: const [0.0, 0.0]),
      address: json['address'] as String? ?? 'N/A',
      city: json['city'] as String? ?? 'N/A',
      contactPhone: json['contactPhone'] as String? ?? 'N/A',
      serviceType: json['serviceType'] as String? ?? 'N/A',
      cuisine: json['cuisine'] as String? ?? 'N/A',
      maxCapacity: _toInt(json['maxCapacity']),
      tiffinService: (json['tiffinService'] as bool?) ?? false,
      basicThaliDetails: json['basicThaliDetails'] as String? ?? '',
      timings: json['timings'] != null
          ? MessTimings.fromJson(json['timings'] as Map<String, dynamic>)
          : MessTimings(
              lunch: MealTiming(start: '00:00', end: '00:00'),
              dinner: MealTiming(start: '00:00', end: '00:00'),
            ),
      plans: _parsePlans(json['plans']),
      dailyThaliRate: _toDouble(json['dailyThaliRate']),
      rules: json['rules'] != null
          ? MessRules.fromJson(json['rules'] as Map<String, dynamic>)
          : MessRules(
              minLeaveDaysForRebate: 99,
              rebatePerThali: 0,
              skipAllowancePercent: 0,
            ),
      averageRating: _toDouble(json['averageRating']), // accepts "0.0" or 0
      reviewCount: _toInt(json['reviewCount']),
      distance: _toDouble(json['distance']),
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
    double? dailyThaliRate,
    MessRules? rules,
    double? averageRating,
    int? reviewCount,
    double? distance,
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
      dailyThaliRate: dailyThaliRate ?? this.dailyThaliRate,
      rules: rules ?? this.rules,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'messName': messName,
        if (messImage != null) 'messImage': messImage,
        'location': location.toJson(),
        'address': address,
        'city': city,
        'contactPhone': contactPhone,
        'serviceType': serviceType,
        'cuisine': cuisine,
        if (maxCapacity != null) 'maxCapacity': maxCapacity,
        'tiffinService': tiffinService,
        'basicThaliDetails': basicThaliDetails,
        'timings': timings.toJson(),
        'plans': plans.map((e) => e.toJson()).toList(),
        if (dailyThaliRate != null) 'dailyThaliRate': dailyThaliRate,
        'rules': rules.toJson(),
        if (averageRating != null) 'averageRating': averageRating,
        if (reviewCount != null) 'reviewCount': reviewCount,
        if (distance != null) 'distance': distance,
      };
}

class MessTimings {
  final MealTiming lunch;
  final MealTiming dinner;

  MessTimings({required this.lunch, required this.dinner});

  factory MessTimings.fromJson(Map<String, dynamic> json) {
    final defaultTiming = MealTiming(start: '00:00', end: '00:00');
    return MessTimings(
      lunch: json['lunch'] != null
          ? MealTiming.fromJson(json['lunch'] as Map<String, dynamic>)
          : defaultTiming,
      dinner: json['dinner'] != null
          ? MealTiming.fromJson(json['dinner'] as Map<String, dynamic>)
          : defaultTiming,
    );
  }

  Map<String, dynamic> toJson() => {
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
      };
}

class MealTiming {
  final String start; // "HH:mm"
  final String end; // "HH:mm"

  MealTiming({required this.start, required this.end});

  factory MealTiming.fromJson(Map<String, dynamic> json) {
    return MealTiming(
      start: json['start'] as String? ?? 'N/A',
      end: json['end'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class MessPlan {
  final String name;
  final double rate;

  MessPlan({required this.name, required this.rate});

  factory MessPlan.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return MessPlan(
      name: json['name'] as String,
      rate: _toDouble(json['rate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'rate': rate,
      };
}

class MessRules {
  final int minLeaveDaysForRebate;
  final double rebatePerThali;
  final double skipAllowancePercent;
  final double? securityDeposit;
  final double? minMonthlyCharge;

  MessRules({
    required this.minLeaveDaysForRebate,
    required this.rebatePerThali,
    required this.skipAllowancePercent,
    this.securityDeposit,
    this.minMonthlyCharge,
  });

  factory MessRules.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int _toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v.toString()) ?? 99;

    return MessRules(
      minLeaveDaysForRebate: _toInt(json['minLeaveDaysForRebate']),
      rebatePerThali: _toDouble(json['rebatePerThali']) ?? 0,
      skipAllowancePercent: _toDouble(json['skipAllowancePercent']) ?? 0,
      securityDeposit: _toDouble(json['securityDeposit']),
      minMonthlyCharge: _toDouble(json['minMonthlyCharge']),
    );
  }

  Map<String, dynamic> toJson() => {
        'minLeaveDaysForRebate': minLeaveDaysForRebate,
        'rebatePerThali': rebatePerThali,
        'skipAllowancePercent': skipAllowancePercent,
        if (securityDeposit != null) 'securityDeposit': securityDeposit,
        if (minMonthlyCharge != null) 'minMonthlyCharge': minMonthlyCharge,
      };
}
