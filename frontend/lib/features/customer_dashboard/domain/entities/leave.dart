// This file defines the Leave entity.

class Leave {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRebateEligible;

  const Leave({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.isRebateEligible,
  });
}
