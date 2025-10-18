// lib/features/kiosk/presentation/screens/kiosk_pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';

class KioskPinEntryScreen extends ConsumerStatefulWidget {
  final String messId;
  final KioskMember member;
  const KioskPinEntryScreen(
      {super.key, required this.messId, required this.member});

  @override
  ConsumerState<KioskPinEntryScreen> createState() =>
      _KioskPinEntryScreenState();
}

class _KioskPinEntryScreenState extends ConsumerState<KioskPinEntryScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  String _mealType() => TimeOfDay.now().hour < 16 ? 'Lunch' : 'Dinner';

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a 4–6 digit PIN')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(kioskProvider.notifier).logMonthlyMeal(
            messId: widget.messId,
            customerId: widget.member.userId,
            mealType: _mealType(),
            pin: pin,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${widget.member.name}'s meal logged successfully!"),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.person,
                      size: 60, color: Colors.deepOrange),
                ),
                const SizedBox(height: 16),
                Text(widget.member.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Enter your 4–6 digit PIN to get a thali',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6)
                  ],
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _submit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Confirm Meal',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
