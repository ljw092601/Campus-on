import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';

/// Root shell hosting the 3 bottom tabs. Adaptive bottom bar (UX doc §7):
/// Material [NavigationBar] on Android, [CupertinoTabBar] look on iOS.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // Re-tapping the active tab pops that branch to its root (UX doc §3).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <_TabItem>[
      _TabItem(Symbols.home, l.tab_home_label),
      _TabItem(Symbols.map, l.tab_map_label),
      _TabItem(Symbols.settings, l.tab_settings_label),
    ];

    final isCupertino = !kIsWeb && _isIOS;

    // System back only reaches this route once the active branch has nothing
    // left to pop. Instead of letting Android kill the activity from a non-home
    // tab (Map/Settings roots), fall back to the Home tab; only a second back
    // from the home root actually leaves the app (standard bottom-nav UX).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0, initialLocation: true);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: isCupertino
            ? CupertinoTabBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTap,
                items: [
                  for (final it in items)
                    BottomNavigationBarItem(
                        icon: Icon(it.icon), label: it.label),
                ],
              )
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onTap,
                destinations: [
                  for (final it in items)
                    NavigationDestination(icon: Icon(it.icon), label: it.label),
                ],
              ),
      ),
    );
  }

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}

class _TabItem {
  const _TabItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
