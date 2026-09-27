import 'dart:convert';
import 'dart:math' as math;

import 'package:campus_on/app.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/presentation/guide/guide_detail_screen.dart';
import 'package:campus_on/presentation/guide/guide_item_list_screen.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/search/search_screen.dart';
import 'package:campus_on/presentation/settings/favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The 30-guide catalogue as a user moves through it: every guide opens and
/// lays out on a small phone with large text in both languages, search reaches
/// the owning guide, and back returns to where the user came from (search
/// results, the previous guide, the category list).
///
/// Widget tests use the test font, so this proves layout without overflow and
/// navigation; how the real fonts look is checked on a device or browser.

Future<ProviderScope> _app(String locale,
    {List<String> favoriteGuides = const []}) async {
  SharedPreferences.setMockInitialValues({
    'app_locale': locale,
    if (favoriteGuides.isNotEmpty)
      'favorites_v1': jsonEncode([
        for (final id in favoriteGuides)
          {'type': 'guide', 'id': id, 'savedAt': '2026-09-14T00:00:00Z'},
      ]),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const CampusOnApp(),
  );
}

/// A 320×568 phone (the smallest common logical size). Text is enlarged with
/// [_largeText] once the guide screen is open: the home app bar is outside this
/// suite, and the square test glyphs make its KO|EN toggle far wider than the
/// real font (checked in the browser run instead).
void _smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> _largeText(WidgetTester tester) async {
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  await tester.pumpAndSettle();
}

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Scrolls [screen]'s main list from top to bottom one viewport at a time so
/// every lazily built card is laid out; an overflow anywhere fails the test.
/// [eachStep] runs after every step (e.g. to inspect rows now on screen).
Future<void> _scrollThrough(WidgetTester tester, Finder screen,
    {void Function()? eachStep}) async {
  final scrollable =
      find.descendant(of: screen, matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  var last = -1.0;
  while (position.pixels != last) {
    last = position.pixels;
    position.jumpTo(math.min(
        position.pixels + position.viewportDimension * 0.8,
        position.maxScrollExtent));
    // Settle so cards that load on appear (related facilities) finish.
    await tester.pumpAndSettle();
    eachStep?.call();
  }
  expect(position.pixels, position.maxScrollExtent);
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(
      find.descendant(
          of: find.byType(SearchScreen), matching: find.byType(TextField)),
      query);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

/// Taps the app-bar back button of the page on top (pages below stay in the
/// tree, so the visible one is the last hit-testable button).
Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).hitTestable().last);
  await tester.pumpAndSettle();
}

Finder _resultTile(String title) => find.descendant(
    of: find.byType(SearchScreen),
    matching: find.widgetWithText(ListTile, title));

String _title(String id, String lang) => MockData.guideItems
    .firstWhere((g) => g.id == id)
    .title(Locale(lang));

void main() {
  group('every guide lays out on a small phone at 200 % text', () {
    for (final lang in const ['ko', 'en']) {
      for (final g in MockData.guideItems) {
        testWidgets('$lang ${g.id}', (tester) async {
          _smallPhone(tester);
          await tester.pumpWidget(await _app(lang));
          await tester.pumpAndSettle();
          // The router is a static singleton: start each guide from home.
          AppRouter.router.go('/home');
          await tester.pumpAndSettle();
          AppRouter.router.go('/home/guide/item/${g.id}');
          await tester.pumpAndSettle();
          await _largeText(tester);

          final screen = find.byType(GuideDetailScreen);
          expect(screen, findsOneWidget);
          expect(find.text(g.detailTitle(Locale(lang))), findsOneWidget);
          await _scrollThrough(tester, screen);
        });
      }
    }
  });

  testWidgets('category lists lay out on a small phone at 200 % text',
      (tester) async {
    _smallPhone(tester);
    for (final lang in const ['ko', 'en']) {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpWidget(await _app(lang));
      await tester.pumpAndSettle();
      AppRouter.router.go('/home/guide');
      await tester.pumpAndSettle();
      await _largeText(tester);
      for (final c in GuideCategory.values) {
        // Via the hub, as a user does, so each list opens at its top.
        AppRouter.router.go('/home/guide');
        await tester.pumpAndSettle();
        AppRouter.router.go('/home/guide/category/${c.name}');
        await tester.pumpAndSettle();
        final screen = find.byType(GuideItemListScreen);
        expect(screen, findsOneWidget, reason: '$lang ${c.name}');
        final seen = <String>{};
        void titlesWhole() {
          for (final g in MockData.guideItems.where((g) => g.categoryId == c)) {
            final title = find.descendant(
                of: screen, matching: find.text(g.title(Locale(lang))));
            if (title.evaluate().isEmpty) continue;
            seen.add(g.id);
            // Whole title, not cut to its first characters.
            expect(tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
                isFalse,
                reason: '$lang ${g.id}');
          }
        }

        titlesWhole();
        await _scrollThrough(tester, screen, eachStep: titlesWhole);
        expect(seen, hasLength(
            MockData.guideItems.where((g) => g.categoryId == c).length));
      }
    }
    AppRouter.router.go('/home/guide');
    await tester.pumpAndSettle();
  });

  group('everyday searches reach the owning guide in the search screen', () {
    const cases = {
      'ko': {
        '알바': 'part-time-work',
        '이사': 'address-and-registration-changes',
        '분실': 'residence-card-reissue',
        '유심': 'mobile-plan',
        '등록금': 'tuition-payment',
        '졸업': 'graduation-requirements',
        'D4': 'status-change-d4-to-d2',
      },
      'en': {
        'part-time job': 'part-time-work',
        'moving': 'address-and-registration-changes',
        'lost card': 'residence-card-reissue',
        'SIM': 'mobile-plan',
        'tuition': 'tuition-payment',
        'graduation': 'graduation-requirements',
        'D-4': 'status-change-d4-to-d2',
      },
    };
    for (final lang in const ['ko', 'en']) {
      testWidgets(lang, (tester) async {
        _tallPhone(tester);
        await tester.pumpWidget(await _app(lang));
        await tester.pumpAndSettle();
        AppRouter.router.go('/home');
        await tester.pumpAndSettle();
        AppRouter.router.push('/search');
        await tester.pumpAndSettle();
        // Queries in either language list titles in the UI language.
        for (final e in {...cases['ko']!, ...cases['en']!}.entries) {
          await _search(tester, e.key);
          expect(_resultTile(_title(e.value, lang)), findsOneWidget,
              reason: '$lang "${e.key}" → ${e.value}');
        }
        // The clear button empties the field and a new query searches again
        // (not reproducible with synthetic input in headless Chrome).
        await tester.tap(find.byTooltip(lang == 'ko' ? '지우기' : 'Clear'));
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNothing);
        await _search(tester, '알바');
        expect(_resultTile(_title('part-time-work', lang)), findsOneWidget);
      });
    }
  });

  testWidgets('search → guide → related guide → back → back keeps the results',
      (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(await _app('ko'));
    await tester.pumpAndSettle();
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    AppRouter.router.push('/search');
    await tester.pumpAndSettle();
    await _search(tester, '알바');

    await tester.tap(_resultTile(_title('part-time-work', 'ko')));
    await tester.pumpAndSettle();
    expect(find.text('유학생 시간제취업 허가 받기'), findsOneWidget);

    final link = find.text('가이드 — 어학연수→학위과정 체류자격 변경');
    await tester.scrollUntilVisible(link, 400,
        scrollable: find
            .descendant(
                of: find.byType(GuideDetailScreen),
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('어학연수(D-4)에서 학위과정 유학(D-2)으로 바꿀 때'), findsOneWidget);

    // Back to the first guide, still scrolled to the link that was tapped.
    await _tapBack(tester);
    expect(find.text('어학연수(D-4)에서 학위과정 유학(D-2)으로 바꿀 때'), findsNothing);
    expect(link.hitTestable(), findsOneWidget);

    await _tapBack(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(GuideDetailScreen), findsNothing);
    expect(_resultTile(_title('part-time-work', 'ko')), findsOneWidget);
  });

  testWidgets('favorites → guide → related guide → back → back keeps favorites',
      (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(
        await _app('en', favoriteGuides: const ['part-time-work']));
    await tester.pumpAndSettle();
    AppRouter.router.go('/settings/favorites');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_title('part-time-work', 'en')));
    await tester.pumpAndSettle();
    final detail = find.byType(GuideDetailScreen);
    expect(detail, findsOneWidget);

    final link = find.text('Guide — Changing from D-4 to D-2');
    await tester.scrollUntilVisible(link, 400,
        scrollable:
            find.descendant(of: detail, matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('Moving from Language Study (D-4) to a Degree (D-2)'),
        findsOneWidget);

    await _tapBack(tester);
    expect(link.hitTestable(), findsOneWidget);
    await _tapBack(tester);
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.byType(GuideDetailScreen), findsNothing);
    // Still on the Settings tab, not moved over to Home.
    expect(find.text(_title('part-time-work', 'en')), findsOneWidget);
  });

  testWidgets('category list → guide → back returns to the list',
      (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(await _app('en'));
    await tester.pumpAndSettle();
    AppRouter.router.go('/home/guide/category/school');
    await tester.pumpAndSettle();

    await tester.tap(find.text(_title('class-attendance-and-exams', 'en')));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDetailScreen), findsOneWidget);

    await _tapBack(tester);
    expect(find.byType(GuideItemListScreen), findsOneWidget);
    expect(find.text(_title('class-attendance-and-exams', 'en')), findsOneWidget);
  });
}
