// lib/features/customer_dashboard/presentation/widgets/meal_skip_toggle.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/meal_timing.dart';

class MealSkipToggle extends StatelessWidget {
  final Membership membership;
  final Map<String, MealTiming> mealTimings;
  final Function(String mealType) onToggle;

  const MealSkipToggle({
    super.key,
    required this.membership,
    required this.mealTimings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.toggle_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Skip Meal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lunch toggle (if user has lunch plan)
            if (membership.hasLunch)
              _buildMealToggle(
                context,
                'Lunch',
                mealTimings['Lunch'],
              ),

            if (membership.hasLunch && membership.hasDinner)
              const Divider(height: 24),

            // Dinner toggle (if user has dinner plan)
            if (membership.hasDinner)
              _buildMealToggle(
                context,
                'Dinner',
                mealTimings['Dinner'],
              ),

            const SizedBox(height: 12),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toggle works only once for current/next upcoming meal',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealToggle(
    BuildContext context,
    String mealType,
    MealTiming? timing,
  ) {
    // Determine if toggle is enabled based on timing
    final canToggle = _canToggleMeal(timing);
    final status = _getMealStatus(timing);

    return Opacity(
      opacity: canToggle ? 1.0 : 0.5,
      child: InkWell(
        onTap: canToggle
            ? () {
                _showConfirmationDialog(context, mealType);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: canToggle
                  ? Theme.of(context).colorScheme.outline
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Meal icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canToggle
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  mealType == 'Lunch' ? Icons.wb_sunny : Icons.nights_stay,
                  color: canToggle
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timing?.formattedTimeRange ?? 'Time not set',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(timing),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle button
              Icon(
                canToggle ? Icons.toggle_off : Icons.block,
                size: 32,
                color: canToggle
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canToggleMeal(MealTiming? timing) {
    if (timing == null) return false;

    // Can toggle if meal is currently active or upcoming
    return timing.isCurrentlyActive || timing.isUpcoming;
  }

  String _getMealStatus(MealTiming? timing) {
    if (timing == null) return 'Not available';
    if (timing.isCurrentlyActive) return 'Ongoing - Can skip';
    if (timing.isUpcoming) return 'Upcoming - Can skip';
    if (timing.hasPassed) return 'Already passed';
    return 'Not yet available';
  }

  Color _getStatusColor(MealTiming? timing) {
    if (timing == null) return Colors.grey;
    if (timing.isCurrentlyActive) return Colors.orange;
    if (timing.isUpcoming) return Colors.blue;
    if (timing.hasPassed) return Colors.red;
    return Colors.grey;
  }

  void _showConfirmationDialog(BuildContext context, String mealType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip $mealType?'),
        content: Text(
          'Are you sure you want to skip $mealType for today? This action can only be done once.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onToggle(mealType);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$mealType skipped successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
