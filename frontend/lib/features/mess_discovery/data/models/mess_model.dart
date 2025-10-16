// lib/features/mess_discovery/data/models/mess_model.dart

// We import the entity from the domain layer to extend it.
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

// The MessModel extends the Mess entity. This is a common and powerful pattern that allows us
// to easily convert from the data layer model (which has parsing logic) to the domain layer entity.
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
  });

  // The factory constructor is the heart of this file. It creates a MessModel instance from a JSON map.
  factory MessModel.fromJson(Map<String, dynamic> json) {
    return MessModel(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      managerContact: json['managerContact'],
      serviceType: json['serviceType'],
      cuisine: json['cuisine'],
      dailyThaliRate: (json['dailyThaliRate'] as num?)
          ?.toDouble(), // Safely parse nullable double

      // We need to parse the list of meal plans from the JSON array by mapping over it.
      mealPlans: (json['mealPlans'] as List)
          .map((planJson) => MealPlanModel.fromJson(planJson))
          .toList(),

      // We parse the timings from the nested JSON object.
      timings: TimingsModel.fromJson(json['timings']),

      averageRating: (json['averageRating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      galleryUrls: List<String>.from(
          json['galleryUrls'] ?? []), // Safely parse list of strings
    );
  }
}

// A model for the MealPlan sub-document.
class MealPlanModel extends MealPlan {
  const MealPlanModel({
    required super.id,
    required super.name,
    required super.currentPrice,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    // Logic to get the most recent price from the priceHistory array.
    // This is a business rule implemented during data parsing.
    final latestPrice = json['priceHistory'].isNotEmpty
        ? (json['priceHistory'].last['price'] as num).toDouble()
        : 0.0;

    return MealPlanModel(
      id: json['_id'],
      name: json['name'],
      currentPrice: latestPrice,
    );
  }
}

// A model for the Timings sub-document.
class TimingsModel extends Timings {
  const TimingsModel({
    required super.lunchStart,
    required super.lunchEnd,
    required super.dinnerStart,
    required super.dinnerEnd,
  });

  factory TimingsModel.fromJson(Map<String, dynamic> json) {
    // Safely access nested fields.
    return TimingsModel(
      lunchStart: json['lunch']?['start'] ?? 'N/A',
      lunchEnd: json['lunch']?['end'] ?? 'N/A',
      dinnerStart: json['dinner']?['start'] ?? 'N/A',
      dinnerEnd: json['dinner']?['end'] ?? 'N/A',
    );
  }
}
