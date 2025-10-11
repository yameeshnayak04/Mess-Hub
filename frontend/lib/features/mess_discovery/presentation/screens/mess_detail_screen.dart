// This file contains the UI for displaying the detailed profile of a single mess.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

// Use a simple ConsumerWidget as this screen will likely not have complex local state.
class MessDetailScreen extends ConsumerWidget {
  // We will pass the full Mess object for simplicity.
  // In a more complex app, you might just pass the messId and fetch details again.
  final Mess mess;

  const MessDetailScreen({super.key, required this.mess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(mess.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(mess.name,
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(mess.address,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: Colors.grey.shade800))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(mess.managerContact,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly Plans Section
            Text('Monthly Plans',
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (mess.mealPlans.isNotEmpty)
              ...mess.mealPlans.map((plan) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(plan.name,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '₹${plan.currentPrice.toStringAsFixed(0)} / month',
                        style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
            else
              const Text('No monthly plans available.'),

            const SizedBox(height: 24),

            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement join mess functionality
                },
                child: const Text('Join This Mess'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
