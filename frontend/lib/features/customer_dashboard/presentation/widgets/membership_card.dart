// lib/features/customer_dashboard/presentation/widgets/membership_card.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class MembershipCard extends StatelessWidget {
  final Membership membership;

  const MembershipCard({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          // Navigate to the detailed management screen for this membership.
          Navigator.pushNamed(
            context,
            AppRouter.membershipDetailRoute, // We will create this route
            arguments: {'membership': membership},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mess Name and Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(membership.messName,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Chip(
                    label: Text(membership.status.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: membership.status == 'active'
                        ? Colors.green.shade600
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Mess Address
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(membership.messAddress,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),

              // Plan Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR PLAN',
                          style: textTheme.labelSmall
                              ?.copyWith(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text(membership.mealPlanName,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('₹${membership.mealPlanPrice.toStringAsFixed(0)} / mo',
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to manage',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
