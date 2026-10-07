import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/facility/facility_detail_screen.dart';
import 'package:campus_on/presentation/guide/guide_category_screen.dart';
import 'package:campus_on/presentation/guide/guide_detail_screen.dart';
import 'package:campus_on/presentation/guide/guide_item_list_screen.dart';
import 'package:campus_on/presentation/home/home_screen.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';
import 'package:campus_on/presentation/providers/provider_cache.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/providers/search_provider.dart';
import 'package:campus_on/presentation/search/search_screen.dart';
import 'package:campus_on/presentation/shared/widgets/route_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Audit §3.3 Low fixes owned by the navigation/search/guide team:
/// L-9 (bad category id), L-10 (error page + `/`), L-16 (result tap → recent
/// search), L-18 (200% font scale overflow), L-26 (guide icons),
/// L-27 (recent-search persist result), L-30 (custom card button roles).
class _Store extends InMemorySharedPreferencesStore {
  _Store(super.data) : super.withData();
  bool fail = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (fail) return false;
    return super.setValue(type, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (fail) return false;
    return super.remove(key);
  }
}

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'en',
      'recent_searches_v1': ['library'],
    });
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Mounts the real router at [path]. [textScale] wraps the app in a
  /// MediaQuery override so layouts can be checked under large font scale.
  Future<void> mount(WidgetTester tester, String path,
      {double textScale = 1.0}) async {
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      providerCacheTtlProvider.overrideWithValue(Duration.zero),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(floorPlansProvider.future));
    AppRouter.router.go(path);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await settle(tester);
  }

  /// Phone-sized surface so Row overflow actually has a chance to happen.
  void usePhoneSurface(WidgetTester tester, {double height = 800}) {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('L-10 router error page', () {
    testWidgets('unknown location shows the localized not-found page',
        (tester) async {
      await mount(tester, '/this/route/does/not/exist');
      expect(find.byType(RouteErrorView), findsOneWidget);
      expect(find.text('Page not found'), findsWidgets);
      expect(find.textContaining('Page Not Found'), findsNothing);
    });

    testWidgets('"Go home" on the not-found page lands on the home tab',
        (tester) async {
      await mount(tester, '/nope');
      await tester.tap(find.text('Go home'));
      await settle(tester);
      expect(find.byType(RouteErrorView), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('`/` redirects to /home', (tester) async {
      await mount(tester, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RouteErrorView), findsNothing);
      expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path,
          '/home');
    });
  });

  group('L-9 unknown guide category', () {
    test('fromId returns null instead of the first category', () {
      expect(GuideCategory.fromId('immigration'), GuideCategory.immigration);
      expect(GuideCategory.fromId('emergency'), GuideCategory.emergency);
      expect(GuideCategory.fromId('bogus'), isNull);
      expect(GuideCategory.fromId(''), isNull);
      expect(GuideCategory.fromId(null), isNull);
    });

    test('an item with an unknown categoryId still parses with a default', () {
      final item = AdminGuideItem.fromJson(const {
        'id': 'x',
        'categoryId': 'nope',
        'title_ko': '제목',
        'title_en': 'Title',
      });
      expect(item.categoryId, GuideCategory.immigration);
    });

    testWidgets('/home/guide/category/<bad> redirects to the guide hub',
        (tester) async {
      await mount(tester, '/home/guide/category/bogus');
      expect(find.byType(GuideCategoryScreen), findsOneWidget);
      expect(find.byType(GuideItemListScreen), findsNothing);
      expect(find.text('Immigration & Stay'), findsOneWidget);
      expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path,
          '/home/guide');
    });

    testWidgets('legacy /guide/category/<bad> also lands on the hub',
        (tester) async {
      await mount(tester, '/guide/category/not-a-category');
      expect(find.byType(GuideCategoryScreen), findsOneWidget);
      expect(find.byType(GuideItemListScreen), findsNothing);
    });

    testWidgets('a valid category id still opens its item list',
        (tester) async {
      await mount(tester, '/home/guide/category/living');
      expect(find.byType(GuideItemListScreen), findsOneWidget);
      expect(find.byType(RouteErrorView), findsNothing);
    });
  });

  group('L-16 result tap saves the query to recent searches', () {
    testWidgets('facility result', (tester) async {
      await mount(tester, '/search');
      await tester.enterText(find.byType(TextField), 'Library');
      await settle(tester);
      final result = find.byWidgetPredicate((w) =>
          w is ListTile &&
          w.title is Text &&
          ((w.title as Text).data ?? '').contains('Library'));
      expect(result, findsWidgets);
      await tester.tap(result.first);
      await settle(tester);
      expect(find.byType(FacilityDetailScreen), findsOneWidget);
      expect(container.read(recentSearchesProvider).first, 'Library');
      expect(prefs.getStringList('recent_searches_v1'), ['Library', 'library']);
    });

    testWidgets('guide result', (tester) async {
      await mount(tester, '/search');
      await tester.enterText(find.byType(TextField), 'bank');
      await settle(tester);
      final result = find.byWidgetPredicate((w) =>
          w is ListTile &&
          w.title is Text &&
          ((w.title as Text).data ?? '').toLowerCase().contains('bank'));
      expect(result, findsWidgets);
      await tester.tap(result.first);
      await settle(tester);
      expect(find.byType(GuideDetailScreen), findsOneWidget);
      expect(container.read(recentSearchesProvider).first, 'bank');
      expect(prefs.getStringList('recent_searches_v1'),
          containsAllInOrder(['bank', 'library']));
    });
  });

  group('L-27 recent search persist result', () {
    test('add/clear report a failed write and keep the memory state', () async {
      SharedPreferences.resetStatic();
      final store = _Store({
        'flutter.recent_searches_v1': ['old']
      });
      SharedPreferencesStorePlatform.instance = store;
      final p = await SharedPreferences.getInstance();
      final c = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(p)]);
      addTearDown(c.dispose);
      final notifier = c.read(recentSearchesProvider.notifier);

      expect(await notifier.add('ok'), isTrue);
      expect(notifier.lastWriteFailed, isFalse);
      expect(c.read(recentSearchesProvider), ['ok', 'old']);

      store.fail = true;
      expect(await notifier.add('lost'), isFalse);
      expect(notifier.lastWriteFailed, isTrue);
      // No rollback: this session still shows what the user searched.
      expect(c.read(recentSearchesProvider), ['lost', 'ok', 'old']);

      expect(await notifier.clear(), isFalse);
      expect(c.read(recentSearchesProvider), isEmpty);

      store.fail = false;
      expect(await notifier.add('again'), isTrue);
      expect(notifier.lastWriteFailed, isFalse);
      // Restore the default store for later tests.
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({});
    });
  });

  group('L-18 200% font scale', () {
    testWidgets('recent-search header does not overflow', (tester) async {
      usePhoneSurface(tester);
      await mount(tester, '/search', textScale: 2.0);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Recent searches'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guide phrase card label column scales with the text',
        (tester) async {
      usePhoneSurface(tester, height: 6000);
      await mount(tester, '/home/guide/item/bank-account', textScale: 2.0);
      expect(find.byType(GuideDetailScreen), findsOneWidget);
      // The page is a lazy list: scroll until the phrase section is built so
      // its rows (ko + en labels) actually lay out at 200%.
      await tester.scrollUntilVisible(find.text('Useful phrases'), 400,
          maxScrolls: 200);
      await settle(tester);
      expect(find.text('Useful phrases'), findsOneWidget);
      expect(find.text('한국어'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('L-26 guide icon names', () {
    test('description / replay / warning resolve to Material Symbols', () {
      expect(guideIconFromName('description'), Symbols.description);
      expect(guideIconFromName('replay'), Symbols.replay);
      expect(guideIconFromName('warning'), Symbols.warning);
      expect(guideIconFromName('definitely-unknown'), isNull);
      expect(guideIconFromName(null), isNull);
    });
  });

  group('L-30 custom cards expose a button role', () {
    testWidgets('facility mini-map is a "View on map" button', (tester) async {
      await mount(tester, '/map/facility/s04');
      expect(find.byType(FacilityDetailScreen), findsOneWidget);
      final semantics = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label == 'View on map');
      expect(semantics, findsOneWidget);
      final node = tester.getSemantics(semantics);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.label, contains('View on map'));
    });

    testWidgets('guide related-location card is a labelled button',
        (tester) async {
      usePhoneSurface(tester, height: 6000);
      await mount(tester, '/home/guide/item/campus-clinic');
      expect(find.byType(GuideDetailScreen), findsOneWidget);
      final semantics = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          (w.properties.label ?? '').contains('View location on map'));
      // Related-location cards sit in the last section of the lazy list.
      await tester.scrollUntilVisible(find.text('Links & Locations'), 400,
          maxScrolls: 200);
      await settle(tester);
      expect(semantics, findsWidgets);
      final node = tester.getSemantics(semantics.first);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.label, contains('View location on map'));
    });
  });
}
