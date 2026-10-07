// Dining screen on the section-based menu model: campus-group tabs, per-slot
// headers, set vs. a-la-carte pricing, ₩1,000 breakfast emphasis, structured
// hours with breaks, folding of long lists, status wording, semantics, and
// 200% text scale on a 360dp phone.
//
// Uses a fake [DiningRepository] with hand-built [CafeteriaMenu]s so nothing
// here depends on the mock repository's sample data.
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/core/util/campus_clock.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/repositories/dining_repository.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/dining/dining_menu_screen.dart';
import 'package:campus_on/presentation/providers/provider_cache.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDining implements DiningRepository {
  const _FakeDining(this.menus);
  final List<CafeteriaMenu> menus;
  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async => menus;
}

// Repository order is deliberately shuffled; the screen must sort by `order`.
const _menus = [
  CafeteriaMenu(
    id: 'eng',
    nameKo: '공과대학 식당',
    nameEn: 'Engineering Cafeteria',
    campus: Campus.seunghak,
    order: 2,
    hoursKo: '운영시간 미표기',
    hoursEn: 'Hours not listed',
    sections: [
      MenuSection(
          slot: MealSlot.dinner,
          kind: MenuKind.set,
          items: [MenuItem(name: '김치찌개'), MenuItem(name: '쌀밥')],
          price: 5500),
    ],
  ),
  CafeteriaMenu(
    id: 'dorm',
    nameKo: '기숙사 식당',
    nameEn: 'Dormitory Cafeteria',
    campus: Campus.seunghak,
    order: 3,
    serviceHours: [ServiceHours(open: '11:30', close: '13:30')],
    sections: [],
    status: DiningAvailability.closed,
  ),
  CafeteriaMenu(
    id: 'hall',
    nameKo: '학생회관 식당',
    nameEn: 'Student Hall Cafeteria',
    campus: Campus.seunghak,
    order: 1,
    facilityId: 'f-hall',
    // Unsorted windows → summary 09:00–16:30 with two breaks.
    serviceHours: [
      ServiceHours(open: '10:00', close: '14:30'),
      ServiceHours(open: '09:00', close: '09:30'),
      ServiceHours(open: '15:00', close: '16:30'),
    ],
    // Unsorted sections → breakfast ₩1,000 first, then lunch set, lunch à la carte.
    sections: [
      MenuSection(slot: MealSlot.lunch, kind: MenuKind.alacarte, items: [
        MenuItem(name: '국밥', price: 6000),
        MenuItem(name: '돈까스', price: 7500)
      ]),
      MenuSection(
          slot: MealSlot.lunch,
          kind: MenuKind.set,
          items: [
            MenuItem(name: '제육볶음'),
            MenuItem(name: '미역국'),
            MenuItem(name: '쌀밥')
          ],
          price: 7000,
          note: '셀프바'),
      MenuSection(
          slot: MealSlot.breakfast,
          kind: MenuKind.thousandWon,
          items: [MenuItem(name: '계란죽')],
          price: 1000,
          note: '09:00부터 선착순'),
    ],
  ),
  CafeteriaMenu(
    id: 'gudeok',
    nameKo: '구덕 식당',
    nameEn: 'Gudeok Cafeteria',
    campus: Campus.gudeok,
    order: 1,
    serviceHours: [ServiceHours(open: '09:00', close: '18:00')],
    sections: [
      MenuSection(slot: MealSlot.allDay, kind: MenuKind.alacarte, items: [
        MenuItem(name: '포케', price: 8000),
      ]),
      MenuSection(slot: MealSlot.lunch, kind: MenuKind.snack, items: [
        MenuItem(name: '김밥', price: 3000),
        MenuItem(name: '라면', price: 3500),
        MenuItem(name: '핫도그', price: 2500),
        MenuItem(name: '떡볶이', price: 4000),
        MenuItem(name: '샌드위치', price: 3500),
        MenuItem(name: '토스트', price: 2500),
        MenuItem(name: '유부초밥', price: 3500),
        MenuItem(name: '컵과일', price: 2000),
      ]),
    ],
  ),
  CafeteriaMenu(
    id: 'bumin',
    nameKo: '부민 식당',
    nameEn: 'Bumin Cafeteria',
    campus: Campus.bumin,
    order: 2,
    sections: [],
    status: DiningAvailability.unpublished,
  ),
];

/// 360dp wide; tall enough that every card of a tab is laid out at 100%.
const _tallPhysical = Size(1080, 7200);

/// Logical phone size for layout-sensitive tests (360 x 780).
const _phonePhysical = Size(1080, 2340);
const _dpr = 3.0;

void main() {
  tearDown(CampusClock.reset);

  Future<void> mount(
    WidgetTester tester, {
    String locale = 'en',
    double textScale = 1.0,
    bool phone = false,
    List<CafeteriaMenu> menus = _menus,
  }) async {
    CampusClock.fix(DateTime(2026, 10, 8, 12));
    tester.view.physicalSize = phone ? _phonePhysical : _tallPhysical;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'app_locale': locale});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        providerCacheTtlProvider.overrideWithValue(Duration.zero),
        diningRepositoryProvider.overrideWithValue(_FakeDining(menus)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DiningMenuScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  AppLocalizations labels(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  ColorScheme scheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme;

  Finder card(String id) => find.byKey(ValueKey('cafeteria-$id'));

  Finder inCard(String id, Finder f) =>
      find.descendant(of: card(id), matching: f);

  double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

  Future<void> switchTo(WidgetTester tester, CampusGroup g) async {
    final l = labels(tester);
    await tester.tap(find.text(g == CampusGroup.seunghak
        ? l.dining_campusGroup_seunghak
        : l.dining_campusGroup_gudeokBumin));
    await tester.pumpAndSettle();
  }

  Future<void> nextDay(WidgetTester tester) async {
    await tester.tap(find.byTooltip(labels(tester).dining_nextDay));
    await tester.pumpAndSettle();
  }

  group('campus group tabs', () {
    testWidgets('Seunghak is shown first, cafeterias sorted by order',
        (tester) async {
      await mount(tester);
      expect(find.text('Student Hall Cafeteria'), findsOneWidget);
      expect(find.text('Engineering Cafeteria'), findsOneWidget);
      expect(find.text('Dormitory Cafeteria'), findsOneWidget);
      expect(find.text('Gudeok Cafeteria'), findsNothing);
      expect(find.text('Bumin Cafeteria'), findsNothing);

      final hall = top(tester, card('hall'));
      final eng = top(tester, card('eng'));
      final dorm = top(tester, card('dorm'));
      expect(hall, lessThan(eng), reason: 'order 1 before 2');
      expect(eng, lessThan(dorm), reason: 'order 2 before 3');
      // Same-campus tab: no redundant campus badge inside the cards.
      expect(inCard('hall', find.text(labels(tester).map_campus_seunghak)),
          findsNothing);
    });

    testWidgets('switching to Gudeok·Bumin filters and survives a day change',
        (tester) async {
      await mount(tester);
      final l = labels(tester);
      await switchTo(tester, CampusGroup.gudeokBumin);
      expect(find.text('Gudeok Cafeteria'), findsOneWidget);
      expect(find.text('Bumin Cafeteria'), findsOneWidget);
      expect(find.text('Student Hall Cafeteria'), findsNothing);
      expect(top(tester, card('gudeok')), lessThan(top(tester, card('bumin'))));
      // Mixed-campus tab shows which campus each cafeteria is on.
      expect(find.text(l.map_campus_gudeok), findsOneWidget);
      expect(find.text(l.map_campus_bumin), findsOneWidget);

      await nextDay(tester);
      expect(find.text(l.dining_goToday), findsOneWidget);
      expect(find.text('Gudeok Cafeteria'), findsOneWidget);
      expect(find.text('Student Hall Cafeteria'), findsNothing);

      await switchTo(tester, CampusGroup.seunghak);
      expect(find.text('Student Hall Cafeteria'), findsOneWidget);
      expect(find.text('Gudeok Cafeteria'), findsNothing);
    });

    testWidgets('a group with no cafeterias shows its own empty state',
        (tester) async {
      await mount(tester, menus: [_menus[0]]); // Seunghak only
      final l = labels(tester);
      expect(find.text(l.dining_group_empty), findsNothing);
      await switchTo(tester, CampusGroup.gudeokBumin);
      expect(find.text(l.dining_group_empty), findsOneWidget);
      expect(find.text(l.dining_empty), findsNothing);
    });
  });

  group('sections', () {
    testWidgets('serving order with one header per slot', (tester) async {
      await mount(tester);
      final l = labels(tester);
      const c = 'hall';
      expect(inCard(c, find.text(l.dining_slot_breakfast)), findsOneWidget);
      expect(inCard(c, find.text(l.dining_slot_lunch)), findsOneWidget,
          reason: 'two lunch sections share one header');
      expect(inCard(c, find.text(l.dining_slot_dinner)), findsNothing);

      final breakfast =
          top(tester, inCard(c, find.text(l.dining_slot_breakfast)));
      final thousand =
          top(tester, inCard(c, find.text(l.dining_kind_thousandWon)));
      final lunch = top(tester, inCard(c, find.text(l.dining_slot_lunch)));
      final set = top(tester, inCard(c, find.text(l.dining_kind_set)));
      final alacarte =
          top(tester, inCard(c, find.text(l.dining_kind_alacarte)));
      expect(breakfast, lessThan(thousand));
      expect(thousand, lessThan(lunch));
      expect(lunch, lessThan(set));
      expect(set, lessThan(alacarte), reason: 'set before à la carte');
    });

    testWidgets('set: one tray price beside the chip, items joined with " · "',
        (tester) async {
      await mount(tester);
      final l = labels(tester);
      final price = inCard('hall', find.text(l.dining_price(7000)));
      expect(price, findsOneWidget);
      expect(l.dining_price(7000), '₩7,000');
      final chip = inCard('hall', find.text(l.dining_kind_set));
      expect((tester.getCenter(chip).dy - tester.getCenter(price).dy).abs(),
          lessThan(4),
          reason: 'kind chip and price on one line');
      expect(inCard('hall', find.text('제육볶음 · 미역국 · 쌀밥')), findsOneWidget);
      expect(inCard('hall', find.text('셀프바')), findsOneWidget);
      // Items of a set section carry no own price.
      expect(inCard('hall', find.text('제육볶음')), findsNothing);
    });

    testWidgets('à la carte: one priced row per item', (tester) async {
      await mount(tester);
      final l = labels(tester);
      expect(inCard('hall', find.text('국밥')), findsOneWidget);
      expect(inCard('hall', find.text(l.dining_price(6000))), findsOneWidget);
      expect(inCard('hall', find.text('돈까스')), findsOneWidget);
      expect(inCard('hall', find.text(l.dining_price(7500))), findsOneWidget);
      final name = tester.getCenter(inCard('hall', find.text('국밥')));
      final price =
          tester.getCenter(inCard('hall', find.text(l.dining_price(6000))));
      expect((name.dy - price.dy).abs(), lessThan(4), reason: 'same row');
      expect(name.dx, lessThan(price.dx), reason: 'price trails the name');
    });

    testWidgets('₩1,000 breakfast is emphasized and shows its note',
        (tester) async {
      await mount(tester);
      final l = labels(tester);
      final chipText = inCard('hall', find.text(l.dining_kind_thousandWon));
      expect(chipText, findsOneWidget);
      expect(inCard('hall', find.text('09:00부터 선착순')), findsOneWidget);
      expect(inCard('hall', find.text(l.dining_price(1000))), findsOneWidget);
      final box = tester.widget<Container>(
          find.ancestor(of: chipText, matching: find.byType(Container)).first);
      expect((box.decoration as BoxDecoration).color, scheme(tester).primary);
      final setBox = tester.widget<Container>(find
          .ancestor(
              of: inCard('hall', find.text(l.dining_kind_set)),
              matching: find.byType(Container))
          .first);
      expect((setBox.decoration as BoxDecoration).color,
          scheme(tester).secondaryContainer);
    });

    testWidgets('long à la carte lists fold after 6 rows', (tester) async {
      await mount(tester);
      final l = labels(tester);
      await switchTo(tester, CampusGroup.gudeokBumin);
      expect(inCard('gudeok', find.text('김밥')), findsOneWidget);
      expect(inCard('gudeok', find.text('토스트')), findsOneWidget);
      expect(inCard('gudeok', find.text('유부초밥')), findsNothing);
      expect(inCard('gudeok', find.text('컵과일')), findsNothing);
      expect(find.text(l.dining_showMore(2)), findsOneWidget);
      // The one-item all-day section is not foldable.
      expect(find.text(l.dining_showMore(0)), findsNothing);

      await tester.tap(find.text(l.dining_showMore(2)));
      await tester.pumpAndSettle();
      expect(inCard('gudeok', find.text('유부초밥')), findsOneWidget);
      expect(inCard('gudeok', find.text('컵과일')), findsOneWidget);
      expect(find.text(l.dining_showLess), findsOneWidget);
      expect(find.text(l.dining_showMore(2)), findsNothing);
    });
  });

  group('hours line', () {
    testWidgets('en: summary with breaks, single window, free-text note',
        (tester) async {
      await mount(tester);
      expect(
          inCard('hall',
              find.text('09:00–16:30 · Break 09:30–10:00, 14:30–15:00')),
          findsOneWidget);
      expect(inCard('dorm', find.text('11:30–13:30')), findsOneWidget);
      expect(inCard('eng', find.text('Hours not listed')), findsOneWidget);
    });

    testWidgets('ko: 휴게 wording and the Korean note', (tester) async {
      await mount(tester, locale: 'ko');
      expect(
          inCard(
              'hall', find.text('09:00~16:30 · 휴게 09:30~10:00, 14:30~15:00')),
          findsOneWidget);
      expect(inCard('eng', find.text('운영시간 미표기')), findsOneWidget);
      expect(find.text('학생회관 식당'), findsOneWidget);
    });
  });

  group('status wording', () {
    testWidgets('closed / unpublished keep today vs. date-neutral phrasing',
        (tester) async {
      await mount(tester);
      final l = labels(tester);
      expect(inCard('dorm', find.text(l.dining_closed)), findsOneWidget);
      expect(inCard('dorm', find.text(l.dining_slot_lunch)), findsNothing);
      await nextDay(tester);
      expect(inCard('dorm', find.text(l.dining_closed_date)), findsOneWidget);
      expect(inCard('dorm', find.text(l.dining_closed)), findsNothing);

      await switchTo(tester, CampusGroup.gudeokBumin);
      expect(inCard('bumin', find.text(l.dining_unpublished_date)),
          findsOneWidget);
      await tester.tap(find.text(l.dining_goToday));
      await tester.pumpAndSettle();
      expect(inCard('bumin', find.text(l.dining_unpublished)), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('each card announces name + status; kind chips are text',
        (tester) async {
      final handle = tester.ensureSemantics();
      await mount(tester);
      final l = labels(tester);
      expect(
          find.bySemanticsLabel(
              l.dining_a11y_card('Dormitory Cafeteria', l.dining_closed)),
          findsOneWidget);
      expect(
          find.bySemanticsLabel(l.dining_a11y_card(
              'Student Hall Cafeteria', l.dining_status_open)),
          findsOneWidget);
      // Kind chips are real text: a tray section reads as one unit
      // ("₩1,000 breakfast, ₩1,000, 계란죽, note"), an à la carte chip is its
      // own node followed by one node per dish row.
      expect(
          find.bySemanticsLabel(
              '${l.dining_kind_thousandWon}\n${l.dining_price(1000)}\n계란죽\n09:00부터 선착순'),
          findsOneWidget);
      expect(find.bySemanticsLabel(l.dining_kind_alacarte), findsOneWidget);
      expect(
          find.bySemanticsLabel('국밥\n${l.dining_price(6000)}'), findsOneWidget);
      handle.dispose();
    });
  });

  group('200% text scale on a 360dp phone', () {
    for (final locale in ['en', 'ko']) {
      testWidgets('no overflow across both tabs ($locale)', (tester) async {
        await mount(tester, locale: locale, textScale: 2.0, phone: true);
        final l = labels(tester);
        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(card('dorm'), 300,
            scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await switchTo(tester, CampusGroup.gudeokBumin);
        await tester.scrollUntilVisible(find.text(l.dining_showMore(2)), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.text(l.dining_showMore(2)));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.dining_showMore(2)));
        await tester.pumpAndSettle();
        expect(find.text(l.dining_showLess), findsOneWidget);
        await tester.scrollUntilVisible(card('bumin'), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
