// lib/features/manager_dashboard/data/models/mess_profile_model.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';

class MealPlanModel extends MealPlan {
  const MealPlanModel({
    required super.name,
    required super.price,
    required super.perThaliRebateRate,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    // Handle priceHistory if it exists, otherwise use direct price
    double price = 0.0;
    if (json['priceHistory'] != null &&
        (json['priceHistory'] as List).isNotEmpty) {
      final priceHistory = json['priceHistory'] as List;
      price = (priceHistory.last['price'] as num).toDouble();
    } else if (json['price'] != null) {
      price = (json['price'] as num).toDouble();
    }

    return MealPlanModel(
      name: json['name'] ?? 'Unknown Plan',
      price: price,
      perThaliRebateRate: json['perDayRebateRate'] != null
          ? (json['perDayRebateRate'] as num).toDouble()
          : 0.0,
    );
  }
}

class MessProfileModel extends MessProfile {
  const MessProfileModel({
    required super.messId,
    required super.name,
    required super.address,
    required super.city,
    required super.cuisine,
    required super.serviceType,
    super.dailyThaliRate,
    required super.totalMembers,
    required super.averageRating,
    required super.totalRatings,
    required super.mealPlans,
  });

  factory MessProfileModel.fromJson(Map<String, dynamic> json) {
    final plansList = (json['mealPlans'] as List?)
            ?.map((p) => MealPlanModel.fromJson(p))
            .toList() ??
        [];

    return MessProfileModel(
      messId: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Mess',
      address: json['address'] ?? 'No address provided',
      city: json['city'] ?? 'Unknown', // FIXED: Handle null
      cuisine: json['cuisine'] ?? 'Mixed', // FIXED: Handle null
      serviceType: json['serviceType'] ?? 'Both',
      dailyThaliRate: json['dailyThaliRate'] != null
          ? (json['dailyThaliRate'] as num).toDouble()
          : null,
      totalMembers: json['totalMembers'] ?? 0,
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      mealPlans: plansList,
    );
  }
}
