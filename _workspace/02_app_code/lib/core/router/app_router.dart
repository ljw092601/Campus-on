import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_guide.dart';
import '../../presentation/facility/facility_detail_screen.dart';
import '../../presentation/facility/facility_list_screen.dart';
import '../../presentation/guide/guide_category_screen.dart';
import '../../presentation/guide/guide_detail_screen.dart';
import '../../presentation/guide/guide_item_list_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/map/map_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/settings/favorites_screen.dart';
import '../../presentation/settings/settings_info_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/app_shell.dart';

/// go_router configuration.
///
/// Layout: a [StatefulShellRoute.indexedStack] with 4 branches (Home / Map /
/// Guide / Settings), each an independent Navigator stack so the bottom tab bar
/// stays visible on detail screens (UX doc §3). Search is a root-navigator
/// route rendered full-screen above the shell (S8).
///
/// Deep link contract (UX doc §3): `/map?focus=<id1>,<id2>,...` focuses those
/// markers, fitBounds, and auto-opens the first marker's Peek sheet.
/// `/map?nearby=<keyword1>,<keyword2>,...` searches those keywords around
/// campus and pins the off-campus results (e.g. carrier stores from a guide).
class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => AppShell(navigationShell: navShell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1 — Map (+ facility list S3 & detail S4 keep the tab bar)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  final focus = state.uri.queryParameters['focus'];
                  final ids = (focus == null || focus.isEmpty)
                      ? const <String>[]
                      : focus.split(',');
                  final nearby = state.uri.queryParameters['nearby'];
                  final queries = (nearby == null || nearby.trim().isEmpty)
                      ? const <String>[]
                      : nearby
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                  return MapScreen(focusIds: ids, nearbyQueries: queries);
                },
                routes: [
                  GoRoute(
                    path: 'list',
                    builder: (context, state) => const FacilityListScreen(),
                  ),
                  GoRoute(
                    path: 'facility/:id',
                    builder: (context, state) =>
                        FacilityDetailScreen(facilityId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2 — Guide (S5 categories → S6 item list → S7 detail)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (context, state) => const GuideCategoryScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    builder: (context, state) => GuideItemListScreen(
                      category: GuideCategory.fromId(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'item/:id',
                    builder: (context, state) =>
                        GuideDetailScreen(itemId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // Branch 3 — Settings (+ favorites S10 + info sub-pages)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const SettingsInfoScreen(
                        type: SettingsInfoType.about),
                  ),
                  GoRoute(
                    path: 'data-source',
                    builder: (context, state) => const SettingsInfoScreen(
                        type: SettingsInfoType.dataSource),
                  ),
                  GoRoute(
                    path: 'contact',
                    builder: (context, state) => const SettingsInfoScreen(
                        type: SettingsInfoType.contact),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen search above the shell (S8).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
}
