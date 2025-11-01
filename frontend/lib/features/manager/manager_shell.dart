// lib/features/manager/manager_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/constants.dart';

class ManagerShell extends StatelessWidget {
  final Widget child;
  const ManagerShell({super.key, required this.child});

  // Tab index -> route
  static const Map<int, String> _tabs = {
    0: RouteNames.managerHome,
    1: RouteNames.managerMembers,
    2: RouteNames.managerPayments, // also covers approvals
    3: RouteNames.kioskLauncher, // kiosk root
    4: RouteNames.managerProfile,
  };

  // Compute selected index from location
  static int _indexForLocation(String location) {
    if (location.startsWith(RouteNames.managerMembers) ||
        location.startsWith('/manager/member/')) return 1;
    if (location.startsWith(RouteNames.managerPayments) ||
        location.startsWith(RouteNames.managerBillingApprovals)) return 2;
    if (location.startsWith(RouteNames.kioskLauncher) ||
        location.startsWith(RouteNames.kioskMode)) return 3;
    if (location.startsWith(RouteNames.managerProfile)) return 4;
    return 0; // default to Home
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        // Always navigate, even when tapping the current tab (re-open root)
        onTap: (index) => context.go(_tabs[index]!),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tablet_outlined),
            activeIcon: Icon(Icons.tablet),
            label: 'Kiosk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
