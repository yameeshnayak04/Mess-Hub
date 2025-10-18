// lib/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/tabs/home_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/tabs/applications_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/tabs/members_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/tabs/kiosk_tab.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/profile_screen.dart';

class ManagerDashboardShell extends StatefulWidget {
  const ManagerDashboardShell({super.key});
  @override
  State<ManagerDashboardShell> createState() => _ManagerDashboardShellState();
}

class _ManagerDashboardShellState extends State<ManagerDashboardShell> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = const [
    HomeTab(),
    ApplicationsTab(),
    MembersTab(),
    KioskTab(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Applications',
    'Members',
    'Kiosk',
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Applications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Members'),
          BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user),
              label: 'Kiosk'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
