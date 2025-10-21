// lib/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
      // ✅ FIXED: Better error detection for "No Mess" scenario
      final errorLower = _initError!.toLowerCase();
      final isNoMessError = errorLower.contains('not created') ||
          errorLower.contains('no mess') ||
          errorLower.contains('have not created');

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
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  // Show debug info
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This appears to be a network or API routing error.\n\n'
                          'Please check:\n'
                          '1. Backend server is running\n'
                          '2. API base URL is correct\n'
                          '3. /api/manager routes are registered',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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

    // ✅ Get service type for conditional navigation
    final serviceType = dashboardState.messProfile?.serviceType ?? 'Monthly';

    // ✅ Build tabs dynamically based on service type
    final tabs = <Widget>[
      const HomeTab(),
      const MembersTab(),
      const PaymentsTab(),
      if (serviceType == 'Monthly' || serviceType == 'Both') const KioskTab(),
    ];

    // ✅ Build navigation destinations dynamically
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Members',
      ),
      const NavigationDestination(
        icon: Icon(Icons.payment_outlined),
        selectedIcon: Icon(Icons.payment),
        label: 'Payments',
      ),
      if (serviceType == 'Monthly' || serviceType == 'Both')
        const NavigationDestination(
          icon: Icon(Icons.tablet_outlined),
          selectedIcon: Icon(Icons.tablet),
          label: 'Kiosk',
        ),
    ];

    // Normal dashboard view
    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardState.messProfile?.name ?? 'My Mess Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          // ✅ Service type badge
          if (serviceType == 'Both')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant,
                      size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Monthly + Daily',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessProfileScreen()),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: destinations,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
