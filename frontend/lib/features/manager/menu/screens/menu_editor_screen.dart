// lib/features/manager/menu/screens/menu_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_menu_providers.dart';

class MenuEditorScreen extends ConsumerStatefulWidget {
  const MenuEditorScreen({super.key});
  @override
  ConsumerState<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends ConsumerState<MenuEditorScreen> {
  DateTime _date = DateTime.now();
  final _lunchCtrl = TextEditingController();
  final _dinnerCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final menu = await ref.read(menuForDateProvider(_date).future);
      final lunch = (menu?['lunchItems'] as List?)?.cast<String>() ?? [];
      final dinner = (menu?['dinnerItems'] as List?)?.cast<String>() ?? [];
      _lunchCtrl.text = lunch.join(', ');
      _dinnerCtrl.text = dinner.join(', ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _load();
    }
  }

  List<String> _parseItems(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(managerMenuRepositoryProvider).setMenu(
            date: _date,
            lunchItems: _parseItems(_lunchCtrl.text),
            dinnerItems: _parseItems(_dinnerCtrl.text),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Menu saved'),
            backgroundColor: AppTheme.successGreen),
      );
      ref.invalidate(todaysMenuProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _lunchCtrl.dispose();
    _dinnerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: 'Pick Date',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Date: ${DateFormat('MMM d, y').format(_date)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Lunch Items',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _lunchCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Comma-separated (e.g., Dal, Roti, Rice)',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Dinner Items',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _dinnerCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Comma-separated (e.g., Paneer, Naan, Kheer)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Save Menu'),
                  ),
                ),
              ],
            ),
    );
  }
}
