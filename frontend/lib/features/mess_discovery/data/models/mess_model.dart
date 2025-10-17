// lib/features/mess_discovery/data/models/mess_model.dart

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

// The MessModel extends the Mess entity and handles JSON parsing.
class MessModel extends Mess {
  const MessModel({
    required super.id,
    required super.name,
    required super.address,
    required super.managerContact,
    required super.serviceType,
    required super.cuisine,
    super.dailyThaliRate,
    required super.mealPlans,
    required super.timings,
    required super.averageRating,
    required super.reviewCount,
    required super.galleryUrls,
    required super.location,
    required super.rules,
  });

  // The factory constructor is now more robust with null checks and default values.
  factory MessModel.fromJson(Map<String, dynamic> json) {
    return MessModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed Mess',
      address: json['address'] ?? 'No address provided',
      managerContact: json['managerContact'] ?? 'N/A',
      serviceType: json['serviceType'] ?? 'N/A',
      cuisine: json['cuisine'] ?? 'Veg',
      dailyThaliRate: (json['dailyThaliRate'] as num?)?.toDouble(),

      mealPlans: (json['mealPlans'] as List?)
              ?.map((planJson) => MealPlanModel.fromJson(planJson))
              .toList() ??
          [], // Default to an empty list

      timings: json['timings'] != null
          ? TimingsModel.fromJson(json['timings'])
          : const Timings(),

      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      galleryUrls: List<String>.from(json['galleryUrls'] ?? []),

      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : const Location(
              coordinates: [0.0, 0.0]), // Default to a safe coordinate

      rules: MessRulesModel.fromJson(json),
    );
  }
}

// --- Sub-Models ---

// A new model specifically for parsing the Location GeoJSON object.
class LocationModel extends Location {
  const LocationModel({required super.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // The backend sends coordinates as [longitude, latitude].
    // We convert the list of numbers to a list of doubles.
    final coords = List<double>.from((json['coordinates'] as List? ?? [])
        .map((coord) => (coord as num).toDouble()));
    return LocationModel(coordinates: coords.length == 2 ? coords : [0.0, 0.0]);
  }
}

// A model for the MealPlan sub-document.
class MealPlanModel extends MealPlan {
  const MealPlanModel(
      {required super.id, required super.name, required super.currentPrice});

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    final latestPrice = json['priceHistory']?.isNotEmpty == true
        ? (json['priceHistory'].last['price'] as num).toDouble()
        : 0.0;
    return MealPlanModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? 'Unnamed Plan',
        currentPrice: latestPrice);
  }
}

// A model for the Timings sub-document.
class TimingsModel extends Timings {
  const TimingsModel(
      {super.lunchStart, super.lunchEnd, super.dinnerStart, super.dinnerEnd});

  factory TimingsModel.fromJson(Map<String, dynamic> json) {
    return TimingsModel(
      lunchStart: json['lunch']?['start'],
      lunchEnd: json['lunch']?['end'],
      dinnerStart: json['dinner']?['start'],
      dinnerEnd: json['dinner']?['end'],
    );
  }
}

// A new model for parsing all the mess rules.
class MessRulesModel extends MessRules {
  const MessRulesModel({
    required super.rebateMinDays,
    required super.leaveCutoffDay,
    required super.leaveApplicationDeadlineTime,
    required super.notEatingRebatePolicy,
    super.partialRebatePercentage,
  });

  factory MessRulesModel.fromJson(Map<String, dynamic> json) {
    return MessRulesModel(
      rebateMinDays: json['rebateMinDays'] ?? 3,
      leaveCutoffDay: json['leaveCutoffDay'] ?? 26,
      leaveApplicationDeadlineTime:
          json['leaveApplicationDeadlineTime'] ?? '22:00',
      notEatingRebatePolicy: json['notEatingRebatePolicy'] ?? 'None',
      partialRebatePercentage:
          (json['partialRebatePercentage'] as num?)?.toInt(),
    );
  }
}
