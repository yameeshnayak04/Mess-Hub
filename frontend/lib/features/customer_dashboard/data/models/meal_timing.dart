// lib/features/customer_dashboard/domain/entities/meal_timing.dart

class MealTiming {
  final String type; // 'Lunch' or 'Dinner'
  final String? startTime; // "12:00"
  final String? endTime; // "14:00"

  MealTiming({
    required this.type,
    this.startTime,
    this.endTime,
  });

  bool get isLunch => type == 'Lunch';
  bool get isDinner => type == 'Dinner';

  // Check if current time is within meal time
  bool get isCurrentlyActive {
    if (startTime == null || endTime == null) return false;

    final now = DateTime.now();
    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);

    final currentMinutes = now.hour * 60 + now.minute;

    return currentMinutes >= start && currentMinutes <= end;
  }

  // Check if meal time has passed
  bool get hasPassed {
    if (endTime == null) return false;

    final now = DateTime.now();
    final end = _parseTime(endTime!);
    final currentMinutes = now.hour * 60 + now.minute;

    return currentMinutes > end;
  }

  // Check if meal time is upcoming (within next hour)
  bool get isUpcoming {
    if (startTime == null) return false;

    final now = DateTime.now();
    final start = _parseTime(startTime!);
    final currentMinutes = now.hour * 60 + now.minute;

    return start > currentMinutes && (start - currentMinutes) <= 60;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String get formattedTimeRange {
    if (startTime == null || endTime == null) return 'Not set';
    return '$startTime - $endTime';
  }
}
