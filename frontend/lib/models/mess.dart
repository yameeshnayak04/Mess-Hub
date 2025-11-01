// lib/models/mess.dart
import 'user.dart';

class Mess {
  final String id;
  final String messName;
  final String? messImage;
  final Location location;
  final String address;
  final String city;
  final String contactPhone;
  final String serviceType;
  final String cuisine;
  final int? maxCapacity;
  final bool tiffinService;
  final String basicThaliDetails;
  final MessTimings timings;
  final List<MessPlan> plans; // typed
  final double? dailyThaliRate;
  final MessRules rules;
  final double? averageRating;
  final int? reviewCount;
  final double? distance;

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
    List<T> _parseList<T>(
        dynamic jsonList, T Function(Map<String, dynamic>) fromJson) {
      if (jsonList is List) {
        return jsonList
            .where((e) => e is Map)
            .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return <T>[];
    }

    return Mess(
      id: json['_id'] as String,
      messName: json['messName'] as String,
      messImage: json['messImage'] as String?,
      location: json['location'] != null
          ? Location.fromJson(
              Map<String, dynamic>.from(json['location'] as Map))
          : Location(type: 'Point', coordinates: [0.0, 0.0]),
      address: json['address'] as String? ?? 'N/A',
      city: json['city'] as String? ?? 'N/A',
      contactPhone: json['contactPhone'] as String? ?? 'N/A',
      serviceType: json['serviceType'] as String? ?? 'N/A',
      cuisine: json['cuisine'] as String? ?? 'N/A',
      maxCapacity: json['maxCapacity'] as int?,
      tiffinService: (json['tiffinService'] as bool?) ?? false,
      basicThaliDetails: json['basicThaliDetails'] as String? ?? '',
      timings: json['timings'] != null
          ? MessTimings.fromJson(
              Map<String, dynamic>.from(json['timings'] as Map))
          : MessTimings(
              lunch: MealTiming(start: '00:00', end: '00:00'),
              dinner: MealTiming(start: '00:00', end: '00:00')),
      plans: _parseList<MessPlan>(json['plans'], (m) => MessPlan.fromJson(m)),
      dailyThaliRate: (json['dailyThaliRate'] as num?)?.toDouble(),
      rules: json['rules'] != null
          ? MessRules.fromJson(Map<String, dynamic>.from(json['rules'] as Map))
          : MessRules(
              minLeaveDaysForRebate: 99,
              rebatePerThali: 0,
              skipAllowancePercent: 0),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
  // existing copyWith/toJson stay the same, but plans is List<MessPlan>

  // Add copyWith
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
        // Only include optional fields if they are not null
        if (messImage != null) 'messImage': messImage,
        'location': location.toJson(), // Assumes Location model has toJson()
        'address': address,
        'city': city,
        'contactPhone': contactPhone,
        'serviceType': serviceType,
        'cuisine': cuisine,
        if (maxCapacity != null) 'maxCapacity': maxCapacity,
        'tiffinService': tiffinService,
        'basicThaliDetails': basicThaliDetails,
        'timings': timings.toJson(),
        // Convert list of MessPlan objects to a list of maps
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
    // *** FIX: Add null checks before casting ***
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
      start: json['start'] as String? ?? 'N/A', // Add defaults
      end: json['end'] as String? ?? 'N/A', // Add defaults
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class MessPlan {
  final String name;
  final double rate;
  // Add _id if it exists in your schema
  // final String? id;

  MessPlan({required this.name, required this.rate});

  factory MessPlan.fromJson(Map<String, dynamic> json) {
    return MessPlan(
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'rate': rate};
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
    this.skipAllowancePercent = 0,
    this.securityDeposit,
    this.minMonthlyCharge,
  });

  factory MessRules.fromJson(Map<String, dynamic> json) {
    return MessRules(
      minLeaveDaysForRebate: json['minLeaveDaysForRebate'] as int? ?? 99,
      rebatePerThali: (json['rebatePerThali'] as num?)?.toDouble() ?? 0,
      skipAllowancePercent:
          (json['skipAllowancePercent'] as num?)?.toDouble() ?? 0,
      securityDeposit: (json['securityDeposit'] as num?)?.toDouble(),
      minMonthlyCharge: (json['minMonthlyCharge'] as num?)?.toDouble(),
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
