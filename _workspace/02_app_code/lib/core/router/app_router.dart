import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_guide.dart';
import '../../presentation/classroom/classroom_search_screen.dart';
import '../../presentation/dining/dining_menu_screen.dart';
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
/// Layout: a [StatefulShellRoute.indexedStack] with 3 branches (Home / Map /
/// Settings), each an independent Navigator stack so the bottom tab bar
/// stays visible on detail screens (UX doc §3). The guide routes (`/guide` and
/// its children) live inside the home branch, so `context.go('/guide')` from
/// the home "Admin guide" card keeps the Home tab active. Search and classroom
/// search are root-navigator routes rendered full-screen above the shell (S8).
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
        builder: (context, state, navShell) =>
            AppShell(navigationShell: navShell),
        branches: [
          // Branch 0 — Home (+ dining placeholder + guide routes S5→S6→S7,
          // moved here from the removed Guide tab so the Home tab stays
          // active while browsing guides).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'dining',
                    builder: (context, state) => const DiningMenuScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/guide',
                builder: (context, state) => const GuideCategoryScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    builder: (context, state) => GuideItemListScreen(
                      category:
                          GuideCategory.fromId(state.pathParameters['id']!),
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
                  // `?floor=03` (classroom search): open the focused
                  // building's peek sheet expanded at that floor.
                  final floor = state.uri.queryParameters['floor'];
                  return MapScreen(
                    focusIds: ids,
                    nearbyQueries: queries,
                    focusFloorCode: (floor == null || floor.isEmpty)
                        ? null
                        : floor,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'list',
                    builder: (context, state) => const FacilityListScreen(),
                  ),
                  GoRoute(
                    path: 'facility/:id',
                    builder: (context, state) => FacilityDetailScreen(
                        facilityId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2 — Settings (+ favorites S10 + info sub-pages)
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
                    builder: (context, state) =>
                        const SettingsInfoScreen(type: SettingsInfoType.about),
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
      // Full-screen classroom-location search above the shell (placeholder).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/classroom-search',
        builder: (context, state) => const ClassroomSearchScreen(),
      ),
    ],
  );
}
