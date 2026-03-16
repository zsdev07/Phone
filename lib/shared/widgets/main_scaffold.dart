import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/recents')) return 1;
    if (location.startsWith('/contacts')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onDestinationTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dialpad');
      case 1:
        context.go('/recents');
      case 2:
        context.go('/contacts');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationIndex(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A3E), width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onDestinationTap(context, i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dialpad_outlined),
              selectedIcon: Icon(Icons.dialpad),
              label: 'Keypad',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Recents',
            ),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
