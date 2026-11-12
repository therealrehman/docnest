import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

/// Bottom navigation shell for the four main tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = <(String, IconData, IconData, String)>[
    (AppRoutes.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
    (AppRoutes.documents, Icons.folder_outlined, Icons.folder_rounded, 'Documents'),
    (AppRoutes.reminders, Icons.notifications_outlined, Icons.notifications_rounded, 'Reminders'),
    (AppRoutes.settings, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  int get _selectedIndex {
    final index = _tabs.indexWhere((tab) => tab.$1 == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].$1),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2),
              selectedIcon: Icon(tab.$3),
              label: tab.$4,
            ),
        ],
      ),
    );
  }
}
