// lib/features/manager_dashboard/presentation/widgets/kiosk_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_main_screen.dart';

class KioskTab extends ConsumerWidget {
  const KioskTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messAsync = ref.watch(messProfileProvider);
    return messAsync.when(
      data: (mess) {
        final messId = (mess['_id'] ?? '').toString();
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tablet_android,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 32),
                  Text('Kiosk Mode',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Mark meal attendance for your members',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: messId.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          KioskMainScreen(messId: messId)));
                            },
                      icon: const Icon(Icons.launch),
                      label: const Text('Launch Kiosk',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Flexible(
                          child: Text(
                              'Use this mode to mark meal attendance for your monthly members.',
                              style: TextStyle(fontSize: 13))),
                    ]),
                  ),
                ]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
