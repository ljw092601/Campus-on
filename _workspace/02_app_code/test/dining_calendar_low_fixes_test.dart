// Audit §3.3 Low fixes for the dining and academic-calendar screens:
// L-11 date-neutral wording, L-12 (a–d) midnight rollover / navigation
// window / "Today" / price grouping, L-13 (a–c) today emphasis / auto-scroll
// / locale date label, L-14 campus clock, L-15 meal slot order, L-18 large
// text scale layout.
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/core/util/campus_clock.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/calendar/academic_calendar_screen.dart';
import 'package:campus_on/presentation/dining/dining_menu_screen.dart';
import 'package:campus_on/presentation/providers/provider_cache.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical phone size used for layout-sensitive tests (360 x 780).
const _phonePhysical = Size(1080, 2340);
const _phoneDpr = 3.0;

void main() {
  tearDown(CampusClock.reset);

  /// Mounts [screen] in a ProviderScope + MaterialApp like the app does.
  /// [textScale] applies a MediaQuery text scaler (L-18); [phone] sizes the
  /// test surface like a narrow phone instead of the 800x600 default.
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    String locale = 'en',
    double textScale = 1.0,
    bool phone = false,
  }) async {
    if (phone) {
      tester.view.physicalSize = _phonePhysical;
      tester.view.devicePixelRatio = _phoneDpr;
      addTearDown(tester.view.reset);
    }
    SharedPreferences.setMockInitialValues({'app_locale': locale});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        providerCacheTtlProvider.overrideWithValue(Duration.zero),
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
        home: screen,
      ),
    ));
    await tester.pumpAndSettle();
  }

  AppLocalizations labels(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  Finder iconButtonWithTooltip(String tooltip) => find.ancestor(
      of: find.byTooltip(tooltip), matching: find.byType(IconButton));

  bool isEnabled(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(iconButtonWithTooltip(tooltip)).onPressed !=
      null;

  String header(DateTime d) => DateFormat.yMMMEd('en').format(d);

  group('L-14 CampusClock', () {
    test('today is the Seoul date of the current UTC instant', () {
      // 15:30Z is 00:30 KST the next day.
      CampusClock.override = () => DateTime.utc(2026, 10, 8, 15, 30);
      expect(CampusClock.today(), DateTime(2026, 10, 9));
      expect(CampusClock.nowInKorea().hour, 0);
      expect(CampusClock.nowInKorea().minute, 30);

      // 14:59Z is still 23:59 KST the same day.
      CampusClock.override = () => DateTime.utc(2026, 10, 8, 14, 59);
      expect(CampusClock.today(), DateTime(2026, 10, 8));
      expect(CampusClock.isToday(DateTime(2026, 10, 8, 18, 45)), isTrue);
      expect(CampusClock.isToday(DateTime(2026, 10, 9)), isFalse);
    });

    test('fix() pins a KST wall clock; reset() restores the system clock', () {
      CampusClock.fix(DateTime(2026, 12, 31, 23, 59, 59));
      expect(CampusClock.today(), DateTime(2026, 12, 31));
      expect(CampusClock.nowInKorea().hour, 23);
      expect(CampusClock.nowUtc(), DateTime.utc(2026, 12, 31, 14, 59, 59));

      CampusClock.reset();
      expect(CampusClock.override, isNull);
      // Unpinned: within a few seconds of the real clock.
      expect(
          CampusClock.nowUtc().difference(DateTime.now().toUtc()).abs(),
          lessThan(const Duration(seconds: 5)));
    });

    test('today() is a date-only local key comparable with DateTime(y,m,d)',
        () {
      CampusClock.fix(DateTime(2026, 3, 1, 8));
      final t = CampusClock.today();
      expect(t.isUtc, isFalse);
      expect((t.hour, t.minute, t.second), (0, 0, 0));
      expect(t == DateTime(2026, 3, 1), isTrue);
    });
  });

  group('L-15 meal slot order', () {
    test('sortMealsBySlot is stable and slot-ordered', () {
      const meals = [
        Meal(type: MealType.dinner, items: ['d']),
        Meal(type: MealType.lunch, items: ['l1']),
        Meal(type: MealType.breakfast, items: ['b']),
        Meal(type: MealType.lunch, items: ['l2']),
      ];
      final sorted = CafeteriaMenu.sortMealsBySlot(meals);
      expect(sorted.map((m) => m.items.single).toList(), ['b', 'l1', 'l2', 'd']);
      expect(meals.first.type, MealType.dinner, reason: 'input untouched');
    });
  });

  group('L-13c locale-aware date label', () {
    // Pure unit tests have no localization delegates, so intl's date symbols
    // must be loaded explicitly (the widget tests get them from the app).
    setUpAll(() => initializeDateFormatting());

    test('en: compact numeric ranges', () {
      expect(formatEventDateRange(DateTime(2026, 9, 1), null, 'en'), '9/1');
      expect(
          formatEventDateRange(DateTime(2026, 10, 20), DateTime(2026, 10, 26),
              'en'),
          '10/20–26');
      expect(
          formatEventDateRange(
              DateTime(2026, 12, 21), DateTime(2027, 1, 13), 'en'),
          '12/21–1/13');
    });

    test('ko: follows the locale pattern instead of a hard-coded M.d', () {
      final start = DateTime(2026, 10, 20);
      final end = DateTime(2026, 10, 26);
      final ko = formatEventDateRange(start, end, 'ko');
      expect(ko,
          '${DateFormat.Md('ko').format(start)}–${DateFormat.d('ko').format(end)}');
      expect(ko, isNot(formatEventDateRange(start, end, 'en')));
      expect(ko, isNot(contains('/')));
    });
  });

  group('L-13 calendar emphasis + auto-scroll', () {
    testWidgets('a row containing today gets the Today badge and is scrolled to',
        (tester) async {
      CampusClock.fix(DateTime(2026, 10, 21, 9)); // inside Midterm exams
      await mount(tester, const AcademicCalendarScreen(), phone: true);
      final l = labels(tester);

      expect(find.text(l.calendar_today), findsOneWidget);
      expect(find.text(l.calendar_upNext), findsNothing);
      final row = find
          .ancestor(of: find.text(l.calendar_today), matching: find.byType(Row))
          .first;
      expect(find.descendant(of: row, matching: find.text('Midterm exams')),
          findsOneWidget);

      // Auto-scrolled: the list moved and the focused row is on screen.
      final pixels =
          tester.state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels;
      expect(pixels, greaterThan(0));
      final rect = tester.getRect(find.text('Midterm exams'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(780));
    });

    testWidgets('with no event today, the next upcoming row is marked Up next',
        (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 9)); // Hangul Day is 10/9
      await mount(tester, const AcademicCalendarScreen(), phone: true);
      final l = labels(tester);

      expect(find.text(l.calendar_today), findsNothing);
      expect(find.text(l.calendar_upNext), findsOneWidget);
      final row = find
          .ancestor(of: find.text(l.calendar_upNext), matching: find.byType(Row))
          .first;
      expect(find.descendant(of: row, matching: find.text('Hangul Day')),
          findsOneWidget);
      final rect = tester.getRect(find.text('Hangul Day'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(780));
    });

    testWidgets('when every event is past, nothing is emphasized or scrolled',
        (tester) async {
      CampusClock.fix(DateTime(2027, 2, 28, 9)); // still AY 2026, all done
      await mount(tester, const AcademicCalendarScreen(), phone: true);
      final l = labels(tester);

      expect(find.text(l.calendar_today), findsNothing);
      expect(find.text(l.calendar_upNext), findsNothing);
      expect(find.text('Commencement'), findsOneWidget);
      expect(
          tester.state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels,
          0);
      expect(tester.takeException(), isNull);
    });
  });

  group('L-18 calendar rows at 200% text scale', () {
    for (final locale in ['en', 'ko']) {
      testWidgets('no overflow on a 360dp phone ($locale)', (tester) async {
        CampusClock.fix(DateTime(2026, 10, 21, 9)); // Today badge present
        await mount(tester, const AcademicCalendarScreen(),
            locale: locale, textScale: 2.0, phone: true);
        final l = labels(tester);
        expect(find.text(l.calendar_today), findsOneWidget);
        // Scroll through the whole year so every row is laid out.
        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(find.text(l.calendar_cat_graduation),
            400,
            scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('L-11 / L-12c dining wording and Today action', () {
    testWidgets('closed wording is "today" only on today', (tester) async {
      CampusClock.fix(DateTime(2026, 10, 10, 12)); // Saturday: mock closed
      await mount(tester, const DiningMenuScreen());
      final l = labels(tester);

      expect(find.text(l.dining_closed), findsNWidgets(3));
      expect(find.text(l.dining_closed_date), findsNothing);
      expect(find.text(l.dining_goToday), findsNothing);

      // Move to Sunday → date-neutral wording and the Today action appears.
      await tester.tap(iconButtonWithTooltip(l.dining_nextDay));
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 11))), findsOneWidget);
      expect(find.text(l.dining_closed), findsNothing);
      expect(find.text(l.dining_closed_date), findsNWidgets(3));
      expect(find.text(l.dining_goToday), findsOneWidget);

      // Today action returns to today and hides itself.
      await tester.tap(find.text(l.dining_goToday));
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 10))), findsOneWidget);
      expect(find.text(l.dining_closed), findsNWidgets(3));
      expect(find.text(l.dining_goToday), findsNothing);
    });
  });

  group('L-12b dining navigation window', () {
    testWidgets('arrows disable at today-7 and today+14', (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 12));
      await mount(tester, const DiningMenuScreen());
      final l = labels(tester);

      expect(isEnabled(tester, l.dining_prevDay), isTrue);
      expect(isEnabled(tester, l.dining_nextDay), isTrue);

      for (var i = 0; i < diningFutureDayLimit; i++) {
        expect(isEnabled(tester, l.dining_nextDay), isTrue, reason: 'step $i');
        await tester.tap(iconButtonWithTooltip(l.dining_nextDay));
        await tester.pumpAndSettle();
      }
      expect(find.text(header(DateTime(2026, 10, 22))), findsOneWidget);
      expect(isEnabled(tester, l.dining_nextDay), isFalse);
      // Tapping a disabled arrow does nothing.
      await tester.tap(iconButtonWithTooltip(l.dining_nextDay),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 22))), findsOneWidget);

      for (var i = 0; i < diningFutureDayLimit + diningPastDayLimit; i++) {
        expect(isEnabled(tester, l.dining_prevDay), isTrue, reason: 'step $i');
        await tester.tap(iconButtonWithTooltip(l.dining_prevDay));
        await tester.pumpAndSettle();
      }
      expect(find.text(header(DateTime(2026, 10, 1))), findsOneWidget);
      expect(isEnabled(tester, l.dining_prevDay), isFalse);
      expect(isEnabled(tester, l.dining_nextDay), isTrue);
    });
  });

  group('L-12a dining midnight rollover', () {
    testWidgets('header follows the campus date when it rolls over',
        (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 23, 59, 30));
      await mount(tester, const DiningMenuScreen());
      final l = labels(tester);
      expect(find.text(header(DateTime(2026, 10, 8))), findsOneWidget);

      CampusClock.fix(DateTime(2026, 10, 9, 0, 0, 30));
      await tester.pump(diningMidnightPollInterval);
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 9))), findsOneWidget);
      expect(find.text(header(DateTime(2026, 10, 8))), findsNothing);
      // Still "today", so no Today action.
      expect(find.text(l.dining_goToday), findsNothing);
    });

    testWidgets('a date the user picked is kept, but Today appears',
        (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 23, 59, 30));
      await mount(tester, const DiningMenuScreen());
      final l = labels(tester);
      await tester.tap(iconButtonWithTooltip(l.dining_prevDay));
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 7))), findsOneWidget);

      CampusClock.fix(DateTime(2026, 10, 9, 0, 0, 30));
      await tester.pump(diningMidnightPollInterval);
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 7))), findsOneWidget);
      expect(find.text(l.dining_goToday), findsOneWidget);
    });

    testWidgets('app resume re-checks the date', (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 23, 59, 30));
      await mount(tester, const DiningMenuScreen());
      expect(find.text(header(DateTime(2026, 10, 8))), findsOneWidget);

      CampusClock.fix(DateTime(2026, 10, 10, 7));
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text(header(DateTime(2026, 10, 10))), findsOneWidget);
    });
  });

  group('L-12d price formatting', () {
    testWidgets('prices carry a thousands separator', (tester) async {
      CampusClock.fix(DateTime(2026, 10, 8, 12)); // Thursday: menus served
      await mount(tester, const DiningMenuScreen());
      final l = labels(tester);
      expect(l.dining_price(5500), '₩5,500');
      expect(find.text('₩5,500'), findsWidgets);
      expect(find.textContaining('₩5500'), findsNothing);
    });
  });
}
