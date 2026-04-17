import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../widgets/app_background.dart';
import 'admin_panel_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSession>().user;
    final isAdmin = user?.roleCode == 'admin';
    final screens =
        isAdmin
            ? const <Widget>[
              HomeScreen(),
              HistoryScreen(),
              AdminPanelScreen(),
              ProfileScreen(),
            ]
            : const <Widget>[
              HomeScreen(),
              HistoryScreen(),
              ProfileScreen(),
            ];
    final destinations =
        isAdmin
            ? const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Trang chu',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Lich su',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Admin',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Tai khoan',
              ),
            ]
            : const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Trang chu',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Lich su',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Tai khoan',
              ),
            ];
    final selectedIndex =
        _currentIndex >= screens.length ? screens.length - 1 : _currentIndex;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: IndexedStack(index: selectedIndex, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A), // Soft dark secondary shadow
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              height: 74,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              destinations: destinations,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
