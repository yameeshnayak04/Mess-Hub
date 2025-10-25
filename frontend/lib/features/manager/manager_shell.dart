import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';

class ManagerShell extends StatefulWidget {
  final Widget child;

  const ManagerShell({
    super.key,
    required this.child,
  });

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        context.go(RouteNames.managerHome);
        break;
      case 1:
        context.go(RouteNames.managerMembers);
        break;
      case 2:
        context.go(RouteNames.managerPayments);
        break;
      case 3:
        context.go(RouteNames.managerKiosk);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current index based on location
    final location = GoRouterState.of(context).matchedLocation;
    if (location == RouteNames.managerHome) {
      _currentIndex = 0;
    } else if (location == RouteNames.managerMembers) {
      _currentIndex = 1;
    } else if (location == RouteNames.managerPayments) {
      _currentIndex = 2;
    } else if (location == RouteNames.managerKiosk) {
      _currentIndex = 3;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
        ],
      ),
    );
  }
}
