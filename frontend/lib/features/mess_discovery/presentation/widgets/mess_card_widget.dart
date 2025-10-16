// lib/features/mess_discovery/presentation/widgets/mess_card_widget.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

class MessCardWidget extends StatelessWidget {
  final Mess mess;
  final VoidCallback onTap;

  const MessCardWidget({super.key, required this.mess, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mess Name and Rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(mess.name,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (mess.reviewCount > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      mess.averageRating.toStringAsFixed(1),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mess.address,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // Service Type and Daily Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Service Type & Cuisine Chips
                  Wrap(
                    spacing: 8.0,
                    children: [
                      Chip(
                        label: Text(mess.serviceType),
                        backgroundColor:
                            colorScheme.secondaryContainer.withOpacity(0.7),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text(mess.cuisine),
                        avatar: Icon(
                            mess.cuisine == 'Veg'
                                ? Icons.eco_rounded
                                : Icons.fastfood_rounded,
                            size: 16),
                        backgroundColor: mess.cuisine == 'Veg'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  // Daily Rate (if available)
                  if (mess.dailyThaliRate != null && mess.dailyThaliRate! > 0)
                    Text.rich(
                      TextSpan(
                        text: '₹${mess.dailyThaliRate?.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: ' / thali',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
