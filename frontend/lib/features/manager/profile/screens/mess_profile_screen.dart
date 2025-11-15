// lib/features/manager/profile/screens/mess_profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import 'package:mess_management_app/core/api/dio_client_provider.dart';
import 'package:mess_management_app/features/auth/widgets/logout_action.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/mess_profile_providers.dart';

class MessProfileScreen extends ConsumerStatefulWidget {
  const MessProfileScreen({super.key});

  @override
  ConsumerState<MessProfileScreen> createState() => _MessProfileScreenState();
}

class _MessProfileScreenState extends ConsumerState<MessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Identity (read-only)
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _serviceType = TextEditingController();
  final _cuisine = TextEditingController();

  // Editable basic fields
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _maxCapacity = TextEditingController();
  final _dailyRate = TextEditingController();

  // Rules
  final _minLeaveDays = TextEditingController();
  final _rebatePerThali = TextEditingController();
  final _skipPercent = TextEditingController();
  final _minMonthlyCharge = TextEditingController();

  // Thali / tiffin
  final _basicThali = TextEditingController();
  bool _tiffinService = false;

  // Timings
  TimeOfDay? _lunchStart;
  TimeOfDay? _lunchEnd;
  TimeOfDay? _dinnerStart;
  TimeOfDay? _dinnerEnd;

  // Plans snapshot (from backend)
  List<Map<String, dynamic>> _plans = [];

  File? _picked;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _serviceType.dispose();
    _cuisine.dispose();
    _address.dispose();
    _phone.dispose();
    _maxCapacity.dispose();
    _dailyRate.dispose();
    _minLeaveDays.dispose();
    _rebatePerThali.dispose();
    _skipPercent.dispose();
    _minMonthlyCharge.dispose();
    _basicThali.dispose();
    super.dispose();
  }

  TimeOfDay? _parseHHMM(String? v) {
    if (v == null || v.isEmpty) return null;
    final parts = v.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatHHMM(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(BuildContext context, void Function(TimeOfDay) setter,
      {TimeOfDay? initial}) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? now,
    );
    if (picked != null) {
      setState(() => setter(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messProfileProvider);
    final dio = ref.read(dioClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Profile'),
        actions: const [LogoutAction()],
      ),
      body: messAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
          ),
        ),
        error: (e, _) =>
            _Error(message: 'Failed to load', detail: e.toString()),
        data: (mess) {
          // One-time initialization from backend data
          if (!_initialized) {
            _name.text = (mess['messName'] ?? '').toString();
            _city.text = (mess['city'] ?? '').toString();
            _serviceType.text = (mess['serviceType'] ?? '').toString();
            _cuisine.text = (mess['cuisine'] ?? '').toString();

            _address.text = (mess['address'] ?? '').toString();
            _phone.text = (mess['contactPhone'] ?? '').toString();
            _maxCapacity.text = (mess['maxCapacity'] ?? '').toString();
            _dailyRate.text = (mess['dailyThaliRate'] ?? '').toString();

            final rules =
                (mess['rules'] as Map?)?.cast<String, dynamic>() ?? {};
            _minLeaveDays.text =
                (rules['minLeaveDaysForRebate'] ?? '').toString();
            _rebatePerThali.text = (rules['rebatePerThali'] ?? '').toString();
            _skipPercent.text =
                (rules['skipAllowancePercent'] ?? '').toString();
            _minMonthlyCharge.text =
                (rules['minMonthlyCharge'] ?? '').toString();

            _basicThali.text = (mess['basicThaliDetails'] ?? '').toString();
            _tiffinService = mess['tiffinService'] == true;

            final timings =
                (mess['timings'] as Map?)?.cast<String, dynamic>() ?? {};
            _lunchStart = _parseHHMM(timings['lunchStart'] as String?);
            _lunchEnd = _parseHHMM(timings['lunchEnd'] as String?);
            _dinnerStart = _parseHHMM(timings['dinnerStart'] as String?);
            _dinnerEnd = _parseHHMM(timings['dinnerEnd'] as String?);

            final rawPlans = mess['plans'] as List? ?? const [];
            _plans = rawPlans
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            _initialized = true;
          }

          final scheduled =
              (mess['scheduledUpdates'] as Map?)?.cast<String, dynamic>() ?? {};
          final effective = mess['scheduledEffectiveFrom'] != null
              ? DateTime.tryParse(mess['scheduledEffectiveFrom'])
              : null;

          final imagePath = (mess['messImage'] as String?) ?? '';
          final imageUrl = dio.resolveServerUrl(imagePath);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Image preview + picker
              Center(
                child: GestureDetector(
                  onTap: () {
                    final img = _picked?.path ?? imageUrl;
                    if (img.isEmpty) return;
                    showDialog(
                      context: context,
                      builder: (_) => _ImageViewer(imagePathOrUrl: img),
                    );
                  },
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.surfaceColor,
                    backgroundImage:
                        (imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                    child: (imageUrl.isEmpty && _picked == null)
                        ? const Icon(Icons.image, color: AppTheme.textSecondary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final x = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (x != null) {
                    setState(() => _picked = File(x.path));
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Pick Image'),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identity (read-only)
                    _readOnlyField('Mess Name', _name),
                    _readOnlyField('City', _city),
                    _readOnlyField('Service Type', _serviceType),
                    _readOnlyField('Cuisine', _cuisine),

                    const SizedBox(height: 8),
                    Text(
                      'Contact & Capacity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Address', _address),
                    _field('Contact Phone', _phone,
                        keyboard: TextInputType.phone),
                    _field('Max Capacity', _maxCapacity,
                        keyboard: TextInputType.number),

                    const SizedBox(height: 16),
                    Text(
                      'Meal Timings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _timingRow(
                      context,
                      label: 'Lunch',
                      start: _lunchStart,
                      end: _lunchEnd,
                      onStartPicked: (t) => _lunchStart = t,
                      onEndPicked: (t) => _lunchEnd = t,
                    ),
                    const SizedBox(height: 8),
                    _timingRow(
                      context,
                      label: 'Dinner',
                      start: _dinnerStart,
                      end: _dinnerEnd,
                      onStartPicked: (t) => _dinnerStart = t,
                      onEndPicked: (t) => _dinnerEnd = t,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Plans (pricing)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_plans.isEmpty)
                      Text(
                        'No plans configured',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      )
                    else
                      ..._plans
                          .asMap()
                          .entries
                          .map((entry) => _planCard(context, entry.key))
                          .toList(),

                    const SizedBox(height: 16),
                    Text(
                      'Rules & Thali',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Min leave days for rebate', _minLeaveDays,
                        keyboard: TextInputType.number),
                    _field('Rebate per thali', _rebatePerThali,
                        keyboard: TextInputType.number),
                    _field('Skip allowance percent', _skipPercent,
                        keyboard: TextInputType.number),
                    _field('Min monthly charge', _minMonthlyCharge,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Tiffin service'),
                      value: _tiffinService,
                      onChanged: (v) => setState(() => _tiffinService = v),
                    ),
                    _field('Basic thali details', _basicThali,
                        keyboard: TextInputType.multiline),

                    const SizedBox(height: 16),
                    Text(
                      'Daily thali rate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Daily thali rate', _dailyRate,
                        keyboard: TextInputType.number),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              if (scheduled.isNotEmpty || effective != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scheduled Changes',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (effective != null)
                          Text(
                            'Effective from: ${DateFormat('MMM d, y').format(effective.toLocal())}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        const SizedBox(height: 8),
                        ...scheduled.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save (changes apply from next month)'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      final fields = <String, String>{
                        // Allowed scalar fields
                        'address': _address.text.trim(),
                        'contactPhone': _phone.text.trim(),
                        'maxCapacity': _maxCapacity.text.trim(),
                        'dailyThaliRate': _dailyRate.text.trim(),
                        'tiffinService': _tiffinService.toString(),
                        'basicThaliDetails': _basicThali.text.trim(),
                        // Rules (sent as flat keys; backend stores under mess.rules via scheduledUpdates)
                        'rules.minLeaveDaysForRebate':
                            _minLeaveDays.text.trim(),
                        'rules.rebatePerThali': _rebatePerThali.text.trim(),
                        'rules.skipAllowancePercent': _skipPercent.text.trim(),
                        'rules.minMonthlyCharge': _minMonthlyCharge.text.trim(),
                        // Timings (HH:mm)
                        'timings.lunchStart': _formatHHMM(_lunchStart),
                        'timings.lunchEnd': _formatHHMM(_lunchEnd),
                        'timings.dinnerStart': _formatHHMM(_dinnerStart),
                        'timings.dinnerEnd': _formatHHMM(_dinnerEnd),
                      };

                      // Plans pricing: name read-only, rate editable
                      for (var i = 0; i < _plans.length; i++) {
                        final p = _plans[i];
                        final id = p['_id']?.toString() ?? '$i';
                        final rate = p['rate']?.toString() ?? '';
                        fields['plans.$id.rate'] = rate;
                      }

                      MultipartFile? mf;
                      if (_picked != null) {
                        mf = await MultipartFile.fromFile(
                          _picked!.path,
                          filename: _picked!.path.split('/').last,
                        );
                      }

                      await ref.read(messProfileUpdaterProvider)(
                        fields,
                        image: mf,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Changes scheduled for next month'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _readOnlyField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.surfaceColor,
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: keyboard == TextInputType.multiline ? null : 1,
        decoration: InputDecoration(labelText: label),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _timingRow(
    BuildContext context, {
    required String label,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required void Function(TimeOfDay) onStartPicked,
    required void Function(TimeOfDay) onEndPicked,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(
              '${label} start: ${start != null ? start.format(context) : '--:--'}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => _pickTime(context, onStartPicked, initial: start),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(
              '${label} end: ${end != null ? end.format(context) : '--:--'}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => _pickTime(context, onEndPicked, initial: end),
          ),
        ),
      ],
    );
  }

  Widget _planCard(BuildContext context, int index) {
    final plan = _plans[index];
    final name = (plan['name'] ?? '').toString();
    final rate = (plan['rate'] ?? '').toString();
    final controller = TextEditingController(text: rate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                name.isEmpty ? 'Plan ${index + 1}' : name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                ),
                onChanged: (v) => plan['rate'] = v.trim(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String imagePathOrUrl;
  const _ImageViewer({required this.imagePathOrUrl});

  @override
  Widget build(BuildContext context) {
    final isFile = !imagePathOrUrl.startsWith('http');
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: isFile
                ? Image.file(File(imagePathOrUrl), fit: BoxFit.contain)
                : Image.network(imagePathOrUrl, fit: BoxFit.contain),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message, detail;
  const _Error({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
