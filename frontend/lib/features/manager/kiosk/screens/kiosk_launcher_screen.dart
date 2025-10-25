import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class KioskLauncherScreen extends ConsumerWidget {
  const KioskLauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tablet_mac,
                size: 120,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(height: 32),
              Text(
                'Kiosk Mode',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Launch kiosk mode to mark attendance for members during meal times',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(RouteNames.kioskMode),
                  icon: const Icon(Icons.launch, size: 28),
                  label: const Text(
                    'Launch Kiosk Mode',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: AppTheme.lightOrange,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.darkOrange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Members select their name from the grid\n'
                        '• Enter their 4-digit Kiosk PIN\n'
                        '• Attendance is marked automatically\n'
                        '• Works for both Lunch and Dinner',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkOrange,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
