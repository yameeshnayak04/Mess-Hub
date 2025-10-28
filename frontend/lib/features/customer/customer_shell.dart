import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';

class CustomerShell extends StatefulWidget {
  final Widget child;

  const CustomerShell({
    super.key,
    required this.child,
  });

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  // Map index -> route
  static const _tabs = <int, String>{
    0: RouteNames.home,
    1: RouteNames.discover,
    2: RouteNames.profile,
  };

  // Map route -> index
  int _indexForLocation(String location) {
    if (location.startsWith(RouteNames.home)) return 0;
    if (location.startsWith(RouteNames.discover)) return 1;
    if (location.startsWith(RouteNames.profile)) return 2;
    return 0;
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    final target = _tabs[index]!;
    // Use go to replace stack for tab switch
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    // Keep bottom bar selection in sync with current route
    final location = GoRouterState.of(context).matchedLocation;
    final derived = _indexForLocation(location);
    if (derived != _currentIndex) {
      // Avoid setState during build cascades
      _currentIndex = derived;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
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
    );
  }
}
