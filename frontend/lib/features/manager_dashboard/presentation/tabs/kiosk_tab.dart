// lib/features/manager_dashboard/presentation/tabs/kiosk_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_member_grid_screen.dart';

class KioskTab extends ConsumerStatefulWidget {
  const KioskTab({super.key});
  @override
  ConsumerState<KioskTab> createState() => _KioskTabState();
}

class _KioskTabState extends ConsumerState<KioskTab> {
  @override
  void initState() {
    super.initState();
    // Ensure mess profile is loaded so we have messId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(managerDashboardProvider);
      if (state.myMessProfile == null) {
        ref.read(managerDashboardProvider.notifier).fetchMyMessProfile();
      }
    });
  }

  String _mealType() => TimeOfDay.now().hour < 16 ? 'Lunch' : 'Dinner';

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(managerDashboardProvider);
    final messId = dashState.myMessProfile?.id;

    if (messId == null || messId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Fetching mess details...'),
          ],
        ),
      );
    }

    return Scaffold(
      body: KioskMemberGridScreen(messId: messId),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.local_atm_rounded),
        label: const Text('Log Daily User'),
        onPressed: () async {
          try {
            await ref.read(kioskProvider.notifier).logDailyMeal(
                  messId: messId,
                  mealType: _mealType(),
                );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily meal logged')),
            );
            // Refresh grid after logging a daily user is optional; daily users don’t appear in member grid
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
    );
  }
}
