// lib/features/customer_dashboard/presentation/screens/profile_tab_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';

class ProfileTabScreen extends ConsumerStatefulWidget {
  const ProfileTabScreen({super.key});
  @override
  ConsumerState<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends ConsumerState<ProfileTabScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);
    final notifier = ref.read(customerDashboardProvider.notifier);

    final me = state.profile ?? {};
    _name.text = me['name']?.toString() ?? _name.text;
    _phone.text = me['phone']?.toString() ?? _phone.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Enter phone'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;
                      await notifier.updateProfile({
                        'name': _name.text.trim(),
                        'phone': _phone.text.trim()
                      });
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated')));
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                  ),
                  const Divider(height: 32),
                  Text('Kiosk PIN',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Pinput(
                    controller: _pin,
                    length: 4,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final p = _pin.text.trim();
                      if (p.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter 4-digit PIN')));
                        return;
                      }
                      await notifier.updatePin(p);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN updated')));
                    },
                    icon: const Icon(Icons.key),
                    label: const Text('Update PIN'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
