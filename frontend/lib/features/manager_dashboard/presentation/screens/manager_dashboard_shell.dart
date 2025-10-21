// lib/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // ADD THIS
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/home_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/members_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/payments_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/kiosk_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/mess_profile_screen.dart';

class ManagerDashboardShell extends ConsumerStatefulWidget {
  const ManagerDashboardShell({super.key});

  @override
  ConsumerState<ManagerDashboardShell> createState() =>
      _ManagerDashboardShellState();
}

class _ManagerDashboardShellState extends ConsumerState<ManagerDashboardShell> {
  int _selectedIndex = 0;
  bool _isInitializing = true;
  String? _initError;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Use addPostFrameCallback to avoid modifying provider during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    try {
      await ref.read(managerDashboardProvider.notifier).initializeDashboard();

      if (mounted && !_disposed) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted && !_disposed) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  final _tabs = const [
    HomeTab(),
    MembersTab(),
    PaymentsTab(),
    KioskTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(managerDashboardProvider);

    // Show loading during initialization
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Loading dashboard...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error screen if initialization failed
    if (_initError != null) {
      final isNoMessError = _initError!.contains('404') ||
          _initError!.toLowerCase().contains('not created') ||
          _initError!.toLowerCase().contains('no mess');

      if (isNoMessError) {
        // Manager doesn't have a mess - show create screen
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manager Dashboard'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 100,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Mess Found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You haven\'t created a mess yet.\nCreate one to access your dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/mess-onboarding')
                          .then((_) {
                        setState(() {
                          _isInitializing = true;
                          _initError = null;
                        });
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          _initializeDashboard();
                        });
                      });
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('Create Your Mess'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Network/server error - show retry
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manager Dashboard'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Connection Error',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _isInitializing = true;
                        _initError = null;
                      });
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        _initializeDashboard();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Normal dashboard view
    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardState.messProfile?.name ?? 'My Mess Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Mess Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessProfileScreen()),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.tablet_outlined),
            selectedIcon: Icon(Icons.tablet),
            label: 'Kiosk',
          ),
        ],
      ),
    );
  }
}
