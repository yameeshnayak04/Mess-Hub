// lib/features/customer_dashboard/presentation/screens/customer_dashboard_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/home_tab_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/discover_tab_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/profile_tab_screen.dart';

class CustomerDashboardShell extends ConsumerStatefulWidget {
  const CustomerDashboardShell({super.key});

  @override
  ConsumerState<CustomerDashboardShell> createState() =>
      _CustomerDashboardShellState();
}

class _CustomerDashboardShellState
    extends ConsumerState<CustomerDashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const DiscoverTabScreen(),
    const ProfileTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load memberships on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDashboardProvider.notifier).loadMemberships();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        // In CustomerDashboardShell's onDestinationSelected:
        onDestinationSelected: (i) async {
          setState(() => _currentIndex = i);
          if (i == 0) {
            await ref
                .read(customerDashboardProvider.notifier)
                .loadMemberships();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
