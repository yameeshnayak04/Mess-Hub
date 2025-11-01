// lib/features/manager/profile/screens/mess_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mess_management_app/core/api/dio_client_provider.dart';
import 'package:mess_management_app/features/auth/widgets/logout_action.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/mess_profile_providers.dart';
import 'package:dio/dio.dart';
import 'package:mess_management_app/core/api/dio_client.dart';

class MessProfileScreen extends ConsumerStatefulWidget {
  const MessProfileScreen({super.key});
  @override
  ConsumerState<MessProfileScreen> createState() => _MessProfileScreenState();
}

class _MessProfileScreenState extends ConsumerState<MessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _serviceType = TextEditingController();
  final _cuisine = TextEditingController();
  final _maxCapacity = TextEditingController();
  final _dailyRate = TextEditingController();
  File? _picked;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _serviceType.dispose();
    _cuisine.dispose();
    _maxCapacity.dispose();
    _dailyRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messProfileProvider);
    final dio = ref.read(dioClientProvider); // import dio_client_provider.dart

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Profile'),
        actions: const [LogoutAction()],
      ),
      body: messAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange))),
        error: (e, _) =>
            _Error(message: 'Failed to load', detail: e.toString()),
        data: (mess) {
          // Initialize controllers once with current values
          _name.text =
              _name.text.isEmpty ? (mess['messName'] ?? '') : _name.text;
          _address.text =
              _address.text.isEmpty ? (mess['address'] ?? '') : _address.text;
          _city.text = _city.text.isEmpty ? (mess['city'] ?? '') : _city.text;
          _phone.text =
              _phone.text.isEmpty ? (mess['contactPhone'] ?? '') : _phone.text;
          _serviceType.text = _serviceType.text.isEmpty
              ? (mess['serviceType'] ?? '')
              : _serviceType.text;
          _cuisine.text =
              _cuisine.text.isEmpty ? (mess['cuisine'] ?? '') : _cuisine.text;
          _maxCapacity.text = _maxCapacity.text.isEmpty
              ? '${mess['maxCapacity'] ?? ''}'
              : _maxCapacity.text;
          _dailyRate.text = _dailyRate.text.isEmpty
              ? '${mess['dailyThaliRate'] ?? ''}'
              : _dailyRate.text;

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
              // Image preview
              Center(
                child: GestureDetector(
                  onTap: () {
                    final img = _picked?.path ?? imageUrl;
                    if (img == null || img.isEmpty) return;
                    showDialog(
                        context: context,
                        builder: (_) => _ImageViewer(imagePathOrUrl: img));
                  },
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.surfaceColor,
                    backgroundImage:
                        (imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                    child: (imageUrl == null && _picked == null)
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
                  if (x != null) setState(() => _picked = File(x.path));
                },
                icon: const Icon(Icons.upload),
                label: const Text('Pick Image'),
              ),

              const SizedBox(height: 16),

              // Form
              Form(
                key: _formKey,
                child: Column(children: [
                  _field('Mess Name', _name),
                  _field('Address', _address),
                  _field('City', _city),
                  _field('Contact Phone', _phone,
                      keyboard: TextInputType.phone),
                  _field('Service Type', _serviceType),
                  _field('Cuisine', _cuisine),
                  _field('Max Capacity', _maxCapacity,
                      keyboard: TextInputType.number),
                  _field('Daily Thali Rate', _dailyRate,
                      keyboard: TextInputType.number),
                ]),
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
                                    ?.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          ...scheduled.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('${e.key}: ${e.value}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              )),
                        ]),
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save (applies next month)'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      final fields = {
                        'messName': _name.text.trim(),
                        'address': _address.text.trim(),
                        'city': _city.text.trim(),
                        'contactPhone': _phone.text.trim(),
                        'serviceType': _serviceType.text.trim(),
                        'cuisine': _cuisine.text.trim(),
                        'maxCapacity': _maxCapacity.text.trim(),
                        'dailyThaliRate': _dailyRate.text.trim(),
                      };
                      MultipartFile? mf;
                      if (_picked != null) {
                        mf = await MultipartFile.fromFile(_picked!.path,
                            filename: _picked!.path.split('/').last);
                      }
                      await ref.read(messProfileUpdaterProvider)(fields,
                          image: mf);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Changes scheduled for next month')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: AppTheme.errorRed),
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

  String _resolveUrl(String path) {
    // Adjust if you already prepend baseUrl in Dio interceptors
    return _looksAbsolute(path)
        ? path
        : '${Uri.base.scheme}://${Uri.base.host}:${Uri.base.port}$path';
  }

  bool _looksAbsolute(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  Widget _field(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
      child: Stack(children: [
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
              onPressed: () => Navigator.pop(context)),
        ),
      ]),
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
