// lib/features/kiosk/presentation/screens/kiosk_main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_member_grid_screen.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_setup_screen.dart';

class KioskMainScreen extends ConsumerStatefulWidget {
  const KioskMainScreen({super.key});
  @override
  ConsumerState<KioskMainScreen> createState() => _KioskMainScreenState();
}

class _KioskMainScreenState extends ConsumerState<KioskMainScreen> {
  String? _messId;

  @override
  void initState() {
    super.initState();
    _loadMessId();
  }

  Future<void> _loadMessId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _messId = prefs.getString('kiosk_mess_id'));
  }

  String _currentMealType() => TimeOfDay.now().hour < 16 ? 'Lunch' : 'Dinner';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_messId == null) {
      return KioskSetupScreen(
        onMessConfigured: (id) => setState(() => _messId = id),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Kiosk'),
        actions: [
          IconButton(
            tooltip: 'Reconfigure',
            icon: const Icon(Icons.settings_suggest_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => KioskSetupScreen(
                existingId: _messId!,
                onMessConfigured: (id) => setState(() => _messId = id),
              ),
            )),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank_rounded,
                size: 100, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text("Welcome to the Mess",
                style: textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text("Please select your entry type",
                style: textTheme.titleLarge
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 60),
            SizedBox(
              width: 350,
              height: 100,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_search_rounded, size: 40),
                label: const Text('Monthly Member',
                    style: TextStyle(fontSize: 24)),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        KioskMemberGridScreen(messId: _messId!),
                  ));
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 350,
              height: 100,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.local_atm_rounded, size: 40),
                label: const Text('Daily User (Pay at Counter)',
                    style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  try {
                    final mealType = _currentMealType();
                    await ref
                        .read(kioskProvider.notifier)
                        .logDailyMeal(messId: _messId!, mealType: mealType);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Daily meal logged! Please collect payment.'),
                      backgroundColor: Colors.green,
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ));
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
