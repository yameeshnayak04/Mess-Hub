// lib/features/kiosk/presentation/screens/kiosk_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KioskSetupScreen extends StatefulWidget {
  final String? existingId;
  final ValueChanged<String> onMessConfigured;
  const KioskSetupScreen(
      {super.key, this.existingId, required this.onMessConfigured});

  @override
  State<KioskSetupScreen> createState() => _KioskSetupScreenState();
}

class _KioskSetupScreenState extends State<KioskSetupScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingId != null) _controller.text = widget.existingId!;
  }

  Future<void> _save() async {
    final id = _controller.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid Mess ID')));
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kiosk_mess_id', id);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onMessConfigured(id);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Kiosk')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Enter Mess ID to link this device:',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 60c72b2f9b1d8e001c8e4d9b'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator.adaptive()
                : const Text('Save'),
          ),
        ]),
      ),
    );
  }
}
