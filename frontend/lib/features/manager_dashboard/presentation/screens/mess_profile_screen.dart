// lib/features/manager_dashboard/presentation/screens/mess_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';

class MessProfileScreen extends ConsumerStatefulWidget {
  const MessProfileScreen({super.key});

  @override
  ConsumerState<MessProfileScreen> createState() => _MessProfileScreenState();
}

class _MessProfileScreenState extends ConsumerState<MessProfileScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _contact = TextEditingController();
  String _cuisine = 'Veg';
  String _serviceType = 'Both';
  final _dailyRate = TextEditingController();
  final _specialRate = TextEditingController();
  final _securityDeposit = TextEditingController();
  final _maxMembers = TextEditingController(text: '100');
  final _toggleSkipRebate = TextEditingController(text: '0');
  final _minMonthlyCharge = TextEditingController(text: '0');
  final _leaveDeadline = TextEditingController(text: '22:00');
  final _lunchStart = TextEditingController(text: '12:00');
  final _lunchEnd = TextEditingController(text: '14:30');
  final _dinnerStart = TextEditingController(text: '19:30');
  final _dinnerEnd = TextEditingController(text: '22:00');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ref.read(messProfileProvider.future);
    _name.text = data['name'] ?? '';
    _address.text = data['address'] ?? '';
    _city.text = data['city'] ?? '';
    _contact.text = data['managerContact'] ?? '';
    _cuisine = data['cuisine'] ?? 'Veg';
    _serviceType = data['serviceType'] ?? 'Both';
    _dailyRate.text = (data['dailyThaliRate']?.toString() ?? '');
    _specialRate.text = (data['specialThaliRate']?.toString() ?? '');
    _securityDeposit.text = (data['securityDeposit']?.toString() ?? '0');
    _maxMembers.text = (data['maxMembers']?.toString() ?? '100');
    _toggleSkipRebate.text =
        (data['toggleSkipRebatePercentage']?.toString() ?? '0');
    _minMonthlyCharge.text = (data['minMonthlyCharge']?.toString() ?? '0');
    _leaveDeadline.text =
        (data['leaveApplicationDeadlineTime']?.toString() ?? '22:00');
    final lunch = (data['timings']?['lunch'] ?? {}) as Map<String, dynamic>;
    final dinner = (data['timings']?['dinner'] ?? {}) as Map<String, dynamic>;
    _lunchStart.text = lunch['start']?.toString() ?? '12:00';
    _lunchEnd.text = lunch['end']?.toString() ?? '14:30';
    _dinnerStart.text = dinner['start']?.toString() ?? '19:30';
    _dinnerEnd.text = dinner['end']?.toString() ?? '22:00';
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _address,
      _city,
      _contact,
      _dailyRate,
      _specialRate,
      _securityDeposit,
      _maxMembers,
      _toggleSkipRebate,
      _minMonthlyCharge,
      _leaveDeadline,
      _lunchStart,
      _lunchEnd,
      _dinnerStart,
      _dinnerEnd,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final includesDaily = _serviceType == 'Both';
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Mess Name *')),
          const SizedBox(height: 12),
          TextField(
              controller: _contact,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Public Contact Number *', prefixText: '+91 ')),
          const SizedBox(height: 12),
          TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address *'),
              maxLines: 2),
          const SizedBox(height: 12),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City *')),
          const SizedBox(height: 12),
          _chips('Cuisine', ['Veg', 'Non-Veg', 'Both'], _cuisine,
              (v) => setState(() => _cuisine = v)),
          const SizedBox(height: 12),
          _chips('Service Type', ['Both', 'Monthly Only'], _serviceType,
              (v) => setState(() => _serviceType = v)),
          const SizedBox(height: 12),
          if (includesDaily) ...[
            TextField(
                controller: _dailyRate,
                decoration: const InputDecoration(
                    labelText: 'Daily Thali Rate *', prefixText: '₹ '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 12),
            TextField(
                controller: _specialRate,
                decoration: const InputDecoration(
                    labelText: 'Special Thali Rate (optional)',
                    prefixText: '₹ '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _lunchStart,
                    decoration: const InputDecoration(
                        labelText: 'Lunch Start (HH:MM)'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _lunchEnd,
                    decoration:
                        const InputDecoration(labelText: 'Lunch End (HH:MM)'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _dinnerStart,
                    decoration: const InputDecoration(
                        labelText: 'Dinner Start (HH:MM)'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _dinnerEnd,
                    decoration: const InputDecoration(
                        labelText: 'Dinner End (HH:MM)'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _maxMembers,
                    decoration: const InputDecoration(labelText: 'Max Members'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _securityDeposit,
                    decoration:
                        const InputDecoration(labelText: 'Security Deposit'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _toggleSkipRebate,
                    decoration: const InputDecoration(
                        labelText: 'Toggle Skip Rebate %'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _minMonthlyCharge,
                    decoration:
                        const InputDecoration(labelText: 'Min Monthly Charge'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 12),
          TextField(
              controller: _leaveDeadline,
              decoration: const InputDecoration(
                  labelText: 'Leave Application Deadline (HH:MM)')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final body = {
                'name': _name.text.trim(),
                'address': _address.text.trim(),
                'city': _city.text.trim(),
                'managerContact': _contact.text.trim(),
                'cuisine': _cuisine,
                'serviceType': _serviceType,
                'timings': {
                  'lunch': {
                    'start': _lunchStart.text.trim(),
                    'end': _lunchEnd.text.trim()
                  },
                  'dinner': {
                    'start': _dinnerStart.text.trim(),
                    'end': _dinnerEnd.text.trim()
                  },
                },
                'maxMembers': int.tryParse(_maxMembers.text.trim()) ?? 100,
                'securityDeposit':
                    double.tryParse(_securityDeposit.text.trim()) ?? 0,
                'toggleSkipRebatePercentage':
                    int.tryParse(_toggleSkipRebate.text.trim()) ?? 0,
                'minMonthlyCharge':
                    double.tryParse(_minMonthlyCharge.text.trim()) ?? 0,
                'leaveApplicationDeadlineTime': _leaveDeadline.text.trim(),
                if (includesDaily)
                  'dailyThaliRate':
                      double.tryParse(_dailyRate.text.trim()) ?? 0,
                if (includesDaily && _specialRate.text.trim().isNotEmpty)
                  'specialThaliRate':
                      double.tryParse(_specialRate.text.trim()) ?? 0,
              };
              final updated =
                  await ref.read(updateMessProfileProvider(body).future);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')));
              }
              // Refresh
              ref.invalidate(messProfileProvider);
            },
            child: const Text('Save Changes'),
          ),
        ]),
      ),
    );
  }

  Widget _chips(String label, List<String> items, String selected,
      void Function(String) onPick) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: items
            .map((n) => ChoiceChip(
                label: Text(n),
                selected: selected == n,
                onSelected: (_) => onPick(n)))
            .toList(),
      ),
    ]);
  }
}
