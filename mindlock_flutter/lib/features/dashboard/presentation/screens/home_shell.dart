import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_routes.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.dashboard); break;
            case 1: context.go(AppRoutes.apps); break;
            case 2: context.go(AppRoutes.history); break;
            case 3: context.go(AppRoutes.settings); break;
          }
        },
        selectedIndex: _selectedIndex(context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.apps)) return 1;
    if (location.startsWith(AppRoutes.history)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }
}
