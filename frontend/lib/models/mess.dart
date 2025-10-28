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
  final bool tiffinService; // NEW: required in backend
  final String basicThaliDetails; // NEW: required in backend
  final MessTimings timings; // strings "HH:mm"
  final List<MessPlan> plans; // strong type
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
    return Mess(
      id: json['_id'] as String,
      messName: json['messName'] as String,
      messImage: json['messImage'] as String?,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      address: json['address'] as String,
      city: json['city'] as String,
      contactPhone: json['contactPhone'] as String,
      serviceType: json['serviceType'] as String,
      cuisine: json['cuisine'] as String,
      maxCapacity: json['maxCapacity'] as int?,
      tiffinService: (json['tiffinService'] as bool?) ?? false,
      basicThaliDetails: json['basicThaliDetails'] as String? ?? '',
      timings: MessTimings.fromJson(json['timings'] as Map<String, dynamic>),
      plans: (json['plans'] as List)
          .map((e) => MessPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyThaliRate: (json['dailyThaliRate'] as num?)?.toDouble(),
      rules: MessRules.fromJson(json['rules'] as Map<String, dynamic>),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'plans': plans.map((p) => p.toJson()).toList(),
      if (dailyThaliRate != null) 'dailyThaliRate': dailyThaliRate,
      'rules': rules.toJson(),
      if (averageRating != null) 'averageRating': averageRating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (distance != null) 'distance': distance,
    };
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
}

class MessTimings {
  final MealTiming lunch;
  final MealTiming dinner;

  MessTimings({required this.lunch, required this.dinner});

  factory MessTimings.fromJson(Map<String, dynamic> json) {
    return MessTimings(
      lunch: MealTiming.fromJson(json['lunch'] as Map<String, dynamic>),
      dinner: MealTiming.fromJson(json['dinner'] as Map<String, dynamic>),
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
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class MessPlan {
  final String name;
  final double rate;

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
      minLeaveDaysForRebate: json['minLeaveDaysForRebate'] as int,
      rebatePerThali: (json['rebatePerThali'] as num).toDouble(),
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
