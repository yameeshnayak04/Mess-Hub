// lib/features/manager_dashboard/presentation/widgets/menu_upload_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';

class MenuUploadDialog extends ConsumerStatefulWidget {
  const MenuUploadDialog({super.key});

  @override
  ConsumerState<MenuUploadDialog> createState() => _MenuUploadDialogState();
}

class _MenuUploadDialogState extends ConsumerState<MenuUploadDialog> {
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _lunchController.dispose();
    _dinnerController.dispose();
    super.dispose();
  }

  Future<void> _uploadMenu() async {
    if (_lunchController.text.trim().isEmpty &&
        _dinnerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least one meal'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final menuData = <String, dynamic>{
        'date': DateTime.now().toIso8601String(),
      };
      if (_lunchController.text.trim().isNotEmpty) {
        menuData['lunch'] = _lunchController.text.trim();
      }
      if (_dinnerController.text.trim().isNotEmpty) {
        menuData['dinner'] = _dinnerController.text.trim();
      }

      await ref
          .read(managerDashboardProvider.notifier)
          .uploadTodayMenu(menuData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Menu uploaded successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Today\'s Menu',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _lunchController,
              decoration: const InputDecoration(
                labelText: 'Lunch Menu',
                hintText: 'e.g., Dal, Rice, Sabzi, Roti',
                prefixIcon: Icon(Icons.wb_sunny),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dinnerController,
              decoration: const InputDecoration(
                labelText: 'Dinner Menu',
                hintText: 'e.g., Paneer, Roti, Rice, Salad',
                prefixIcon: Icon(Icons.nights_stay),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isUploading ? null : _uploadMenu,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
