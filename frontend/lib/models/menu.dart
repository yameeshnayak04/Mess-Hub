class Menu {
  final String id;
  final String mess;
  final DateTime date;
  final List<String> lunchItems;
  final List<String> dinnerItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menu({
    required this.id,
    required this.mess,
    required this.date,
    required this.lunchItems,
    required this.dinnerItems,
    this.createdAt,
    this.updatedAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['_id'] as String,
      mess: json['mess'] as String,
      date: DateTime.parse(json['date'] as String),
      lunchItems: (json['lunchItems'] as List).cast<String>(),
      dinnerItems: (json['dinnerItems'] as List).cast<String>(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'mess': mess,
      'date': date.toIso8601String(),
      'lunchItems': lunchItems,
      'dinnerItems': dinnerItems,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
