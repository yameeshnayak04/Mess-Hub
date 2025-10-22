// lib/features/kiosk/presentation/screens/kiosk_pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';

class KioskPinEntryScreen extends ConsumerStatefulWidget {
  final dynamic member;
  const KioskPinEntryScreen({super.key, required this.member});

  @override
  ConsumerState createState() => _KioskPinEntryScreenState();
}

class _KioskPinEntryScreenState extends ConsumerState<KioskPinEntryScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future _verifyAndLog() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a 4-digit PIN'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref
          .read(kioskProvider.notifier)
          .logMonthlyMeal(widget.member.membershipId, _pinController.text);
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✓ ${widget.member.name} marked as eaten!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
          border: Border.all(
              color: Theme.of(context).colorScheme.primary, width: 2)),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Member Info
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  widget.member.photoUrl != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(widget.member.photoUrl!))
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            widget.member.name[0].toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Text(widget.member.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(widget.member.phone,
                      style: const TextStyle(color: Colors.grey)),
                ]),
              ),
            ),
            const SizedBox(height: 40),
            // PIN
            Text(
              'Enter your 4-digit PIN',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Pinput(
              controller: _pinController,
              length: 4,
              autofocus: true,
              obscureText: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              onCompleted: (_) => _verifyAndLog(),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _verifyAndLog,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Verifying...' : 'Mark Attendance'),
                style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
          ]),
        ),
      ),
    );
  }
}
