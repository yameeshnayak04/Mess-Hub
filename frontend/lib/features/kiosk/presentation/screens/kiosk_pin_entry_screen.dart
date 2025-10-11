// This screen confirms the selected member and logs their meal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';

class KioskPinEntryScreen extends ConsumerStatefulWidget {
  final String messId;
  final KioskMember member;

  const KioskPinEntryScreen({
    super.key,
    required this.messId,
    required this.member,
  });

  @override
  ConsumerState<KioskPinEntryScreen> createState() =>
      _KioskPinEntryScreenState();
}

class _KioskPinEntryScreenState extends ConsumerState<KioskPinEntryScreen> {
  bool _isLoading = false;

  String _getCurrentMealType() {
    final hour = TimeOfDay.now().hour;
    return hour < 16 ? 'Lunch' : 'Dinner';
  }

  Future<void> _confirmMeal() async {
    setState(() => _isLoading = true);
    try {
      final mealType = _getCurrentMealType();
      await ref.read(kioskProvider.notifier).logMonthlyMeal(
            widget.messId,
            widget.member.userId,
            mealType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.member.name}\'s meal logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the grid screen after successful logging.
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Member')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.person,
                    size: 80, color: Colors.deepOrange),
              ),
              const SizedBox(height: 24),
              Text(
                widget.member.name,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm meal for this member?',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),

              // TODO: Add a Pinput field here for PIN entry when the backend supports it.

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _confirmMeal,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20)),
                      child: const Text('Confirm Meal',
                          style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
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
