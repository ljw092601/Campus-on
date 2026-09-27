import 'dart:math' as math;

import 'package:campus_on/app.dart';
import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/presentation/guide/guide_detail_screen.dart';
import 'package:campus_on/presentation/guide/guide_item_list_screen.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chinese and Vietnamese on a small phone at 200 % text: every guide that has
/// a translation opens and lays out without overflow, and list titles are not
/// cut to their first characters. Guides that are not translated yet are
/// covered too — they show the English fallback, which must fit as well.
///
/// The test font is not the shipped one, so this proves layout and fallback,
/// not how the real Chinese/Vietnamese glyphs look; that is checked in a
/// browser run.

Future<ProviderScope> _app(String locale) async {
  SharedPreferences.setMockInitialValues({'app_locale': locale});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const CampusOnApp(),
  );
}

void _smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

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
    await tester.pumpAndSettle();
    eachStep?.call();
  }
}

/// Guides carrying a translation for [lang], plus one that has none, so both
/// the translated and the fallback path are laid out.
List<AdminGuideItem> _sample(String lang) {
  final translated =
      MockData.guideItems.where((g) => g.i18n.containsKey(lang)).toList();
  final untranslated =
      MockData.guideItems.where((g) => !g.i18n.containsKey(lang)).toList();
  return [...translated, if (untranslated.isNotEmpty) untranslated.first];
}

void main() {
  for (final lang in const ['zh', 'vi']) {
    group('$lang (${appLanguageNames[lang]}) on a 320×568 phone at 200 % text',
        () {
      for (final g in _sample(lang)) {
        final tag = g.i18n.containsKey(lang) ? 'translated' : 'fallback';
        testWidgets('${g.id} ($tag)', (tester) async {
          _smallPhone(tester);
          await tester.pumpWidget(await _app(lang));
          await tester.pumpAndSettle();
          AppRouter.router.go('/home');
          await tester.pumpAndSettle();
          AppRouter.router.go('/home/guide/item/${g.id}');
          await tester.pumpAndSettle();
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;
          await tester.pumpAndSettle();

          final screen = find.byType(GuideDetailScreen);
          expect(screen, findsOneWidget);
          // The heading is shown in the reader's language, or the fallback.
          expect(find.text(g.detailTitle(Locale(lang))), findsOneWidget);
          await _scrollThrough(tester, screen);
        });
      }

      testWidgets('category lists show whole titles', (tester) async {
        _smallPhone(tester);
        await tester.pumpWidget(await _app(lang));
        await tester.pumpAndSettle();
        AppRouter.router.go('/home/guide');
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        await tester.pumpAndSettle();

        for (final c in GuideCategory.values) {
          AppRouter.router.go('/home/guide');
          await tester.pumpAndSettle();
          AppRouter.router.go('/home/guide/category/${c.name}');
          await tester.pumpAndSettle();
          final screen = find.byType(GuideItemListScreen);
          expect(screen, findsOneWidget, reason: '$lang ${c.name}');
          void titlesWhole() {
            for (final g in MockData.guideItems.where((g) => g.categoryId == c)) {
              final title = find.descendant(
                  of: screen, matching: find.text(g.title(Locale(lang))));
              if (title.evaluate().isEmpty) continue;
              expect(
                  tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
                  isFalse,
                  reason: '$lang ${g.id}');
            }
          }

          titlesWhole();
          await _scrollThrough(tester, screen, eachStep: titlesWhole);
        }
      });
    });
  }
}
