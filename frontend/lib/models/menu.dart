// lib/models/menu.dart
import '../core/utils/json_parse.dart';

class Menu {
  final String id;

  /// Plain calendar date 'YYYY-MM-DD'.
  final String serviceDate;
  final List<String> lunchItems;
  final List<String> dinnerItems;

  Menu({
    required this.id,
    required this.serviceDate,
    required this.lunchItems,
    required this.dinnerItems,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        id: asId(json['id']),
        serviceDate: asCalendarDate(json['serviceDate']) ?? '',
        lunchItems: asStringList(json['lunchItems']),
        dinnerItems: asStringList(json['dinnerItems']),
      );

  DateTime? get date => parseCalendarDate(serviceDate);
  bool get isEmpty => lunchItems.isEmpty && dinnerItems.isEmpty;
}
