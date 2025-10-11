// This file defines the LeaveModel for parsing API data.

import 'package:mess_management_system/features/customer_dashboard/domain/entities/leave.dart';

class LeaveModel extends Leave {
  const LeaveModel({
    required super.id,
    required super.startDate,
    required super.endDate,
    required super.isRebateEligible,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['_id'],
      // We need to parse the date string from the JSON into a DateTime object.
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isRebateEligible: json['isRebateEligible'],
    );
  }
}
