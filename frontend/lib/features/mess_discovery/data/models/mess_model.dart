// This file defines the MessModel, which represents the data coming from the API.
// It includes logic to parse JSON, which the pure 'Mess' entity does not.

import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

// The MessModel extends the Mess entity. This is a common pattern that allows us
// to easily convert from the data layer model to the domain layer entity.
class MessModel extends Mess {
  const MessModel({
    required super.id,
    required super.name,
    required super.address,
    required super.managerContact,
    required super.serviceType,
    super.dailyThaliRate,
    required super.mealPlans,
    required super.timings,
  });

  // The factory constructor that creates a MessModel instance from a JSON map.
  factory MessModel.fromJson(Map<String, dynamic> json) {
    return MessModel(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      managerContact: json['managerContact'],
      serviceType: json['serviceType'],
      dailyThaliRate:
          json['dailyThaliRate']?.toDouble(), // Safely convert to double
      // We need to parse the list of meal plans from the JSON array.
      mealPlans: (json['mealPlans'] as List)
          .map((planJson) => MealPlanModel.fromJson(planJson))
          .toList(),
      // We parse the timings from the JSON object.
      timings: TimingsModel.fromJson(json['timings']),
    );
  }
}

// A model for the MealPlan sub-document.
class MealPlanModel extends MealPlan {
  const MealPlanModel({
    required super.id,
    required super.name,
    required super.currentPrice,
    required super.perDayRebateRate,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    // Logic to get the most recent price from the priceHistory array.
    final latestPrice = json['priceHistory'].isNotEmpty
        ? json['priceHistory'].last['price']?.toDouble()
        : 0.0;

    return MealPlanModel(
      id: json['_id'],
      name: json['name'],
      currentPrice: latestPrice,
      perDayRebateRate: json['perDayRebateRate']?.toDouble() ?? 0.0,
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
    return TimingsModel(
      lunchStart: json['lunch']['start'],
      lunchEnd: json['lunch']['end'],
      dinnerStart: json['dinner']['start'],
      dinnerEnd: json['dinner']['end'],
    );
  }
}
