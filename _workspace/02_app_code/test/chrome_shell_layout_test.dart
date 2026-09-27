import 'package:campus_on/app.dart';
import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The chrome around the content — bottom tab labels and app-bar titles — is
/// where a longer language runs out of room first: `Trang chủ` against `홈`,
/// `Hướng dẫn hành chính` against `행정안내`. The guide layout test only looks at
/// list item titles, so truncation here used to pass unnoticed (감사 05/034 S-7).
///
/// One pass per language on a 320×568 phone at 200 % text.

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

/// Every piece of text inside [of] that is cut short: it overflowed its line
/// limit, or it is held to one line (`maxLines: 1`, or `softWrap: false` with no
/// limit at all) and is narrower than the text needs (감사 05/035 SF-4).
List<String> _clipped(WidgetTester tester, Finder of) {
  final out = <String>[];
  for (final e in find.descendant(of: of, matching: find.byType(RichText)).evaluate()) {
    final p = e.renderObject as RenderParagraph;
    final oneLine = p.maxLines == 1 || (p.maxLines == null && !p.softWrap);
    if (p.didExceedMaxLines ||
        (oneLine && p.size.width < p.getMinIntrinsicWidth(double.infinity) - 0.5)) {
      out.add(p.text.toPlainText());
    }
  }
  return out;
}

/// A label whose text does not fit the box it was given: the height it needs at
/// that width is more than the height it got, so part of it is not on screen.
/// Used for the tab bar, where a single long word (`Settings`) wraps and needs
/// the bar to be tall enough to show both lines (감사 05/036 SF-3, measured).
List<String> _cutWords(WidgetTester tester, Finder of) {
  final out = <String>[];
  for (final e in find.descendant(of: of, matching: find.byType(RichText)).evaluate()) {
    final p = e.renderObject as RenderParagraph;
    if (p.size.height + 0.5 < p.getMinIntrinsicHeight(p.size.width)) {
      out.add(p.text.toPlainText());
    }
  }
  return out;
}

void main() {
  // 1.15 is the boundary itself (still the capped, two-line layouts), 1.3 is
  // just above it, 2.0 is the extreme. Checking only 2.0 left the band between
  // 1.0 and 1.15 unrendered (감사 05/038 SF-3).
  for (final scale in const [1.0, 1.15, 1.3, 2.0]) {
  for (final lang in appLanguageCodes) {
    group('$lang (${appLanguageNames[lang]}) chrome at 320×568, ${scale}x text', () {
      testWidgets('bottom tab labels are not cut', (tester) async {
        _smallPhone(tester);
        await tester.pumpWidget(await _app(lang));
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();

        final bar = find.byType(NavigationBar);
        expect(bar, findsOneWidget);
        // Nothing is cut here any more: the bar grows with the text scale, so the
        // English 「Settings」 that used to be clipped now wraps over two lines
        // inside it (감사 05/036, measured). Kept as an empty map on purpose.
        const knownCutLabels = <String, Set<String>>{};
        expect(_clipped(tester, bar), isEmpty,
            reason: '$lang tab labels overflow their line limit');
        expect(_cutWords(tester, bar).toSet(), knownCutLabels[lang] ?? <String>{},
            reason: '$lang tab labels: the set cut at 200 % text has changed');
      });

      // App-bar titles are a different matter: a Material app bar gives its
      // title one line at a fixed height, so at 200 % text the longer titles
      // ellipsize in every language, Korean and English included — this is how
      // the app behaved before the translations and is not something a
      // translation can fix. The screens repeat their heading in the content
      // below, which does scale in full. This test pins down which titles are
      // affected so a new one shows up as a failure rather than going unseen.
      // Measured, not guessed. Chinese titles are short enough to fit; the
      // others lose their tail. The set is compared for equality below so it
      // cannot drift out of date in either direction.
      const knownEllipsized = {
        'ko': {'시설 목록'},
        'en': {'Admin guide', 'Facilities', "Today's menu", 'Favorites',
               'About the app', 'Data sources', 'Classroom search',
               'Academic calendar',   // main's screen, added in this merge
               'Immigration & Stay', 'Health & Insurance', 'School admin',
               'Emergency & Help'},
        'zh': <String>{},
        'vi': {'Hướng dẫn hành chính', 'Danh sách cơ sở', 'Thực đơn hôm nay',
               'Mục yêu thích', 'Giới thiệu ứng dụng', 'Nguồn dữ liệu',
               'Tìm vị trí phòng học',
               'Lịch học vụ',        // main's screen, added in this merge
               'Nhập cảnh và lưu trú',
               'Hạ tầng sinh hoạt', 'Sức khỏe và bảo hiểm',
               'Hành chính nhà trường', 'Khẩn cấp và trợ giúp'},
      };


      // `/home` and `/map` carry no app bar, and neither was ever rendered at
      // 200 % before: the home cards were cut to two characters and the map's
      // campus segments mid-word (감사 05/036 SF-2·SF-3). Here the whole screen
      // is measured, not just a bar.
      testWidgets('home and map read at 200 % text', (tester) async {
        _smallPhone(tester);
        await tester.pumpWidget(await _app(lang));
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();

        // The campus names the other three languages use are romanised
        // (`Seunghak`), and three of them share a 320dp row, so the segmented
        // button cuts them; Korean 「승학」 fits. The labels now carry an ellipsis
        // so the cut is at least visible (감사 05/036 SF-3), and the set is
        // recorded here rather than pretended away.
        // Measured, not aspirational. At 200 % text on a 320dp phone the home
        // cards are one column (감사 05/036 SF-2 fix) and their titles get three
        // lines at the theme size instead of one hard-coded 18px line, which
        // took Korean and Chinese from two characters to the whole title. The
        // longer languages still lose the tail of a long title, and the teaser
        // descriptions still ellipsize — that is the card design's limit at this
        // size, not something a translation can fix, and it shows in Korean too
        // for equally long copy. The map campus labels are romanised in every
        // language but Korean and now carry an ellipsis so the cut is visible
        // (SF-3). Recorded per language and compared for equality so a new
        // truncation fails and a fixed one has to be removed from this list.
        // Nothing is cut here any more. The home cards size themselves to their
        // text at large scale, the classroom heading takes the lines it needs,
        // and the map's campus picker becomes a scrollable chip row instead of a
        // three-way segmented button (감사 05/036 SF-2·SF-3). Kept as an empty
        // set on purpose: if any of those regress, this fails.
        const knownCut = {
          'ko': <String>{},
          'en': <String>{},
          'zh': <String>{},
          'vi': <String>{},
        };
        final cut = <String>{};
        // The calendar rows carry the event names, which are now translated —
        // 조사 04/027 flagged the Vietnamese ones as long enough to worry about
        // on a 320dp row. The row folds above the default text size and the
        // title wraps, so this is the check that settles it rather than
        // shortening real words on a guess.
        for (final route in [
          '/home',
          '/map',
          '/home/calendar',
          '/home/dining',            // menu lines, newly translated
          '/map/facility/s02',       // floor guide: room names on one line
          '/classroom-search',       // the room name under each code
          // All four guides added after the 2026-09-26 gap review: long
          // Vietnamese titles, step lists, and the two checklist-heavy ones
          // that 감사 05/042 NIT-4 asked for.
          '/home/guide/item/financial-scam-response',
          '/home/guide/item/moving-and-utilities',
          '/home/guide/item/waste-and-recycling',
          '/home/guide/item/consumer-disputes',
        ]) {
          AppRouter.router.go(route);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
          final scaffold = find.byType(Scaffold).last;
          cut.addAll(_clipped(tester, scaffold));
          cut.addAll(_cutWords(tester, scaffold));
          // The app-bar title has its own test below, with its own recorded
          // set; counting it here too would report it twice.
          for (final bar in tester.widgetList<AppBar>(find.byType(AppBar))) {
            final title = bar.title;
            if (title is Text && title.data != null) cut.remove(title.data);
          }
        }
        // A title or a control label must never be cut, at any scale. A card
        // teaser may ellipsize only at the default text size, where the cards
        // are fixed-ratio grid cells and the whole text is one tap away; above
        // the boundary the cards size themselves and nothing may be cut
        // (감사 05/038 SF-3).
        final teaserLike = cut.where((t) => t.endsWith('.') || t.endsWith('。')).toSet();
        final headingLike = cut.difference(teaserLike);
        expect(headingLike, knownCut[lang],
            reason: '\$lang @\${scale}x: a heading, control label, calendar '
                'event, menu line or room name is cut on one of the swept '
                'screens. Only the map campus labels may be, and only where '
                'recorded.');
        if (scale > 1.0) {
          expect(teaserLike, isEmpty,
              reason: '$lang @${scale}x: above the boundary the cards size '
                  'themselves, so no teaser may be cut either.');
        }
      });
      testWidgets('app-bar titles ellipsize exactly where recorded', (tester) async {
        _smallPhone(tester);
        await tester.pumpWidget(await _app(lang));
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();

        // Every screen that carries an app bar, including the category lists
        // whose title is a translated category name (감사 05/035 SF-4b).
        final routes = <String>[
          '/home/guide',
          '/home/dining',
          '/map/list',
          '/settings',
          '/settings/favorites',
          '/settings/about',
          '/settings/data-source',
          '/settings/contact',
          '/search',
          '/classroom-search',
          '/home/guide/item/arc-issue',
          '/home/calendar',   // main's academic calendar (감사 05/038 SF-1)
          for (final c in GuideCategory.values) '/home/guide/category/${c.name}',
        ];

        final cut = <String>{};
        for (final route in routes) {
          AppRouter.router.go(route);
          await tester.pumpAndSettle();
          final appBar = find.byType(AppBar);
          // Every route in this list is a screen with an app bar; if one loses
          // it (or the path is a typo) the sweep must fail rather than quietly
          // cover nothing (감사 05/036 NIT-1).
          expect(appBar, findsWidgets, reason: '$route has no AppBar');
          cut.addAll(_clipped(tester, appBar.first));
        }

        // The mock repository answers after 200 ms; let the last screen's
        // request land so the test does not end with a timer pending.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // The recorded set is the worst case (2.0). There, equality: a new
        // truncation fails and so does an entry that stopped being true, so the
        // list cannot quietly rot. Below 2.0 the set must be a subset — fewer
        // titles may be cut, never a different one (감사 05/038 SF-3).
        if (scale == 2.0) {
          expect(cut, knownEllipsized[lang],
              reason: '$lang: the set of app-bar titles cut at 2.0x text has '
                  'changed. Add a new one only after deciding it is acceptable, '
                  'and drop entries that no longer truncate.');
        } else {
          expect(cut.difference(knownEllipsized[lang]!), isEmpty,
              reason: '$lang @${scale}x: a title is cut here that 2.0x does not '
                  'cut — something regressed below the boundary.');
        }
      });
    });
  }
  }
}
