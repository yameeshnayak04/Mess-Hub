// This file contains the main entry screen for the Kiosk.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_member_grid_screen.dart';

class KioskMainScreen extends ConsumerWidget {
  // In a real app, the messId would be configured securely when the manager
  // sets up the Kiosk tablet for the first time. For testing, we hardcode it.
  final String messId =
      "PASTE_YOUR_MESS_ID_HERE_FOR_TESTING"; // e.g., "60c72b2f9b1d8e001c8e4d9b"

  const KioskMainScreen({super.key});

  // Helper function to determine if it's lunch or dinner time.
  String _getCurrentMealType() {
    final hour = TimeOfDay.now().hour;
    // Assuming lunch is before 4 PM, otherwise it's dinner.
    if (hour < 16) {
      return 'Lunch';
    } else {
      return 'Dinner';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank_rounded,
                size: 100, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text(
              "Welcome to the Mess",
              style:
                  textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "Please select your entry type",
              style:
                  textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 60),

            // Button for Monthly Members
            SizedBox(
              width: 350,
              height: 100,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_search_rounded, size: 40),
                label: const Text('Monthly Member',
                    style: TextStyle(fontSize: 24)),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => KioskMemberGridScreen(messId: messId),
                  ));
                },
              ),
            ),
            const SizedBox(height: 30),

            // Button for Daily Users
            SizedBox(
              width: 350,
              height: 100,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.local_atm_rounded, size: 40),
                label: const Text('Daily User (Pay at Counter)',
                    style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                onPressed: () async {
                  try {
                    final mealType = _getCurrentMealType();
                    await ref
                        .read(kioskProvider.notifier)
                        .logDailyMeal(messId, mealType);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Daily meal logged! Please collect payment.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
