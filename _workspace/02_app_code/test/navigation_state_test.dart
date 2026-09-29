import 'dart:convert';

import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/data/repositories/local_favorites_repository.dart';
import 'package:campus_on/data/repositories/mock_facility_repository.dart';
import 'package:campus_on/data/repositories/mock_guide_repository.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/entities/favorite_ref.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/classroom_search_screen.dart';
import 'package:campus_on/presentation/facility/facility_detail_screen.dart';
import 'package:campus_on/presentation/facility/facility_list_screen.dart';
import 'package:campus_on/presentation/guide/guide_detail_screen.dart';
import 'package:campus_on/presentation/guide/guide_item_list_screen.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/providers/search_provider.dart';
import 'package:campus_on/presentation/search/search_screen.dart';
import 'package:campus_on/presentation/settings/favorites_screen.dart';
import 'package:campus_on/presentation/shared/widgets/facility_list_item.dart';
import 'package:campus_on/presentation/shared/widgets/guide_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RetryFacilities extends MockFacilityRepository {
  int calls = 0;
  @override
  Future<List<Facility>> getAll() {
    if (++calls == 1) return Future.error(StateError('offline'));
    return super.getAll();
  }
}

class _RetryGuides extends MockGuideRepository {
  int calls = 0;
  @override
  Future<List<AdminGuideItem>> getAllItems() {
    if (++calls == 1) return Future.error(StateError('offline'));
    return super.getAllItems();
  }
}

class _RetryFavorites extends LocalFavoritesRepository {
  _RetryFavorites(super.prefs);
  int calls = 0;
  @override
  Future<List<FavoriteRef>> getAll() {
    if (++calls == 1) return Future.error(StateError('storage unavailable'));
    return super.getAll();
  }
}

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;
  final guide = MockData.guideItems.first;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'en',
      'recent_searches_v1': ['library'],
      'favorites_v1': jsonEncode([
        {'type': 'facility', 'id': 's04', 'savedAt': '2026-09-29'},
        {'type': 'guide', 'id': guide.id, 'savedAt': '2026-09-29'},
      ]),
    });
    prefs = await SharedPreferences.getInstance();
  });
  Future<void> settle(WidgetTester tester) async {
    // Debounce and repository timers may run without scheduling a frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> mount(WidgetTester tester, String path,
      {List<Override> overrides = const []}) async {
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ]);
    addTearDown(container.dispose);
    AppRouter.router.go(path);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  testWidgets('clear and recent selection cancel pending debounce',
      (tester) async {
    await mount(tester, '/search');
    await tester.enterText(find.byType(TextField), 'bank');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(searchQueryProvider), '');
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    await tester.enterText(find.byType(TextField), 'stale');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'library'));
    await settle(tester);
    expect(container.read(searchQueryProvider), 'library');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'library');
  });

  testWidgets(
      'search result back preserves query; a new session shows recent searches',
      (tester) async {
    await mount(tester, '/home');
    AppRouter.router.push('/search');
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'library');
    await settle(tester);
    final result = find.byWidgetPredicate((w) =>
        w is ListTile &&
        w.title is Text &&
        ((w.title as Text).data ?? '').contains('Library'));
    await tester.tap(result.first);
    await settle(tester);
    expect(find.byType(FacilityDetailScreen), findsOneWidget);
    await back(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'library');
    expect(container.read(searchQueryProvider), 'library');
    await back(tester);
    AppRouter.router.push('/search');
    await settle(tester);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(find.widgetWithText(ActionChip, 'library'), findsOneWidget);
  });

  testWidgets('guide detail system back returns to its category list',
      (tester) async {
    await mount(tester, '/home/guide/category/${guide.categoryId.name}');
    await tester.tap(find.byType(GuideListItem).first);
    await settle(tester);
    expect(find.byType(GuideDetailScreen), findsOneWidget);
    await back(tester);
    expect(find.byType(GuideItemListScreen), findsOneWidget);
  });

  testWidgets('facility list returns from detail, then restores its map',
      (tester) async {
    await mount(tester, '/map?focus=s04&floor=03&room=0306-1&plan=S04&t=list');
    final before = tester.state(find.byType(MapScreen));
    AppRouter.router.push('/map/list');
    await settle(tester);
    await tester.tap(find.byType(FacilityListItem).first);
    await settle(tester);
    expect(find.byType(FacilityDetailScreen), findsOneWidget);
    await back(tester);
    expect(find.byType(FacilityListScreen), findsOneWidget);
    final labels =
        AppLocalizations.of(tester.element(find.byType(FacilityListScreen)));
    await tester.tap(find.descendant(
        of: find.byType(FacilityListScreen),
        matching: find.byTooltip(labels.map_toggle_toMap)));
    await settle(tester);
    expect(tester.state(find.byType(MapScreen)), same(before));
    expect(tester.widget<MapScreen>(find.byType(MapScreen)).focusRoomCode,
        '0306-1');
  });

  testWidgets('favorites details return to the same segment', (tester) async {
    await mount(tester, '/settings/favorites');
    await tester.tap(find.byType(FacilityListItem).first);
    await settle(tester);
    expect(find.byType(FacilityDetailScreen), findsOneWidget);
    await back(tester);
    expect(find.byType(FavoritesScreen), findsOneWidget);
    await tester.tap(find.text('Guides'));
    await settle(tester);
    await tester.tap(find.byType(GuideListItem).first);
    await settle(tester);
    expect(find.byType(GuideDetailScreen), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(GuideListItem), findsOneWidget);
    expect(find.byType(FacilityListItem), findsNothing);
  });

  testWidgets(
      'classroom result and detail pop without losing form or map parameters',
      (tester) async {
    await mount(tester, '/classroom-search');
    await tester.tap(find.byType(TextField).first);
    await settle(tester);
    final choice = find.textContaining('S04 ·').last;
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    final room = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Room');
    await tester.enterText(room, '0306-1');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Show location'));
    await settle(tester);
    expect(find.byType(MapScreen), findsOneWidget);
    final before = tester.widget<MapScreen>(find.byType(MapScreen));
    final beforeState = tester.state(find.byType(MapScreen));
    AppRouter.router.push('/classroom-search/result/facility/s04');
    await settle(tester);
    expect(find.byType(FacilityDetailScreen), findsOneWidget);
    await back(tester);
    final after = tester.widget<MapScreen>(find.byType(MapScreen));
    expect(tester.state(find.byType(MapScreen)), same(beforeState));
    expect(after.focusRoomCode, before.focusRoomCode);
    expect(after.focusToken, before.focusToken);
    await back(tester);
    expect(find.byType(ClassroomSearchScreen), findsOneWidget);
    expect(tester.widget<TextField>(room).controller!.text, '0306-1');
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        startsWith('S04 ·'));
  });

  testWidgets('facility favorites retry performs a second repository read',
      (tester) async {
    final repo = _RetryFacilities();
    await mount(tester, '/settings/favorites', overrides: [
      facilityRepositoryProvider.overrideWithValue(repo),
    ]);
    expect(repo.calls, 1);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await settle(tester);
    expect(repo.calls, 2);
    expect(find.byType(FacilityListItem), findsOneWidget);
  });

  testWidgets('guide favorites retry performs a second repository read',
      (tester) async {
    final repo = _RetryGuides();
    await mount(tester, '/settings/favorites', overrides: [
      guideRepositoryProvider.overrideWithValue(repo),
    ]);
    await tester.tap(find.text('Guides'));
    await settle(tester);
    expect(repo.calls, 1);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await settle(tester);
    expect(repo.calls, 2);
    expect(find.byType(GuideListItem), findsOneWidget);
  });

  testWidgets('favorites retry also recovers a failed local storage read',
      (tester) async {
    final repo = _RetryFavorites(prefs);
    await mount(tester, '/settings/favorites', overrides: [
      favoritesRepositoryProvider.overrideWithValue(repo),
    ]);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await settle(tester);
    expect(repo.calls, 2);
    expect(find.byType(FacilityListItem), findsOneWidget);
  });
}
