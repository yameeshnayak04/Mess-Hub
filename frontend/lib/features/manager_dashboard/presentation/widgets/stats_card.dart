// lib/features/manager_dashboard/presentation/widgets/stats_card.dart
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = Colors.deepOrange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 32, color: iconColor),
                const SizedBox(height: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value,
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(title, style: textTheme.bodyMedium),
                ]),
              ]),
        ),
      ),
    );
  }
}
