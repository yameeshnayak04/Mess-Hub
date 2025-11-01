// lib/features/customer/customer_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  // Tab index -> route path
  static const Map<int, String> _tabs = {
    0: RouteNames.home,
    1: RouteNames.discover,
    2: RouteNames.profile,
  };

  // Resolve a selected index from the current location
  static int _indexForLocation(String location) {
    if (location.startsWith(RouteNames.discover)) return 1;
    if (location.startsWith(RouteNames.profile)) return 2;
    return 0; // default to Home
  }

  @override
  Widget build(BuildContext context) {
    // Read the active route to highlight the correct tab
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          // Always navigate, even if tapping the current tab (re-opens root)
          onDestinationSelected: (index) => context.go(_tabs[index]!),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.lightOrange,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryOrange),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: AppTheme.primaryOrange),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryOrange),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
