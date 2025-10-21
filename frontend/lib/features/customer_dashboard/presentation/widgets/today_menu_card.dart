// lib/features/customer_dashboard/presentation/widgets/today_menu_card.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class TodayMenuCard extends StatelessWidget {
  final Map<String, dynamic>? menu;
  final Membership membership;

  const TodayMenuCard({
    super.key,
    required this.menu,
    required this.membership,
  });

  @override
  Widget build(BuildContext context) {
    if (menu == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Menu not available',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Menu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lunch menu (if user has lunch plan)
            if (membership.hasLunch && menu!['lunch'] != null)
              _buildMealSection(
                  context, 'Lunch', menu!['lunch'], Icons.wb_sunny),

            if (membership.hasLunch &&
                membership.hasDinner &&
                menu!['lunch'] != null &&
                menu!['dinner'] != null)
              const Divider(height: 24),

            // Dinner menu (if user has dinner plan)
            if (membership.hasDinner && menu!['dinner'] != null)
              _buildMealSection(
                  context, 'Dinner', menu!['dinner'], Icons.nights_stay),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String mealType,
      Map<String, dynamic> mealData, IconData icon) {
    final items = (mealData['items'] as List<dynamic>?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              mealType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
