// This file contains a reusable widget for displaying a mess summary.

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mess Name
              Text(
                mess.name,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mess.address,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(),
              const SizedBox(height: 12),

              // Service Type and Daily Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Service Type Chip
                  Chip(
                    label: Text(mess.serviceType),
                    backgroundColor:
                        colorScheme.primaryContainer.withOpacity(0.5),
                    labelStyle: textTheme.labelLarge
                        ?.copyWith(color: colorScheme.onPrimaryContainer),
                    side: BorderSide.none,
                  ),

                  // Daily Rate (if available)
                  if (mess.dailyThaliRate != null && mess.dailyThaliRate! > 0)
                    Text.rich(
                      TextSpan(
                        text: '₹${mess.dailyThaliRate?.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(
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
