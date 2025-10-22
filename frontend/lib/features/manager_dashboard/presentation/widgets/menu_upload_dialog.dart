// lib/features/manager_dashboard/presentation/widgets/menu_upload_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';

class MenuUploadDialog extends ConsumerStatefulWidget {
  const MenuUploadDialog({super.key});

  @override
  ConsumerState<MenuUploadDialog> createState() => _MenuUploadDialogState();
}

class _MenuUploadDialogState extends ConsumerState<MenuUploadDialog> {
  final _lunchCtrl = TextEditingController();
  final _dinnerCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final menu = await ref.read(dailyMenuProvider(_date).future);
    if (menu != null) {
      _lunchCtrl.text = (menu['lunch'] ?? '').toString();
      _dinnerCtrl.text = (menu['dinner'] ?? '').toString();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _lunchCtrl.dispose();
    _dinnerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Daily Menu'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  initialDate: _date,
                );
                if (picked != null) {
                  setState(() => _date = picked);
                  await _load();
                }
              },
              child: const Text('Change'),
            ),
          ),
          TextField(
            controller: _lunchCtrl,
            decoration: const InputDecoration(labelText: 'Lunch'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dinnerCtrl,
            decoration: const InputDecoration(labelText: 'Dinner'),
            maxLines: 2,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await ref.read(updateDailyMenuProvider({
              'date': _date,
              'lunch': _lunchCtrl.text.trim(),
              'dinner': _dinnerCtrl.text.trim(),
            }).future);
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
