import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every guide must be findable by its own title in every language it is
/// written in — not just in the two hand-picked examples of
/// `guide_i18n_test.dart`. This runs over the real catalogue, so a guide whose
/// translation lands later is covered the moment it lands.
///
/// Vietnamese is searched twice: as written, and with the tone marks and đ
/// removed, the way someone types on a keyboard without them.

/// Tone-mark folding for the test's own queries. The app has its own copy; if
/// the two ever disagree, the assertions below fail, which is the point.
const _fold = {
  'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
  'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
  'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
  'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
  'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
  'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  'đ': 'd',
};

String _plain(String s) => s
    .toLowerCase()
    .split('')
    .map((c) => _fold[c] ?? c)
    .join();

void main() {
  final guides = MockData.guideItems;

  for (final lang in appLanguageCodes) {
    final locale = Locale(lang);
    // ko and en are written into the entities; zh and vi come from the overlay,
    // so only the guides that carry one are expected to answer in them.
    final covered = lang == 'ko' || lang == 'en'
        ? guides
        : guides.where((g) => g.i18n.containsKey(lang)).toList();

    group('$lang (${appLanguageNames[lang]}) — ${covered.length} guides', () {
      for (final g in covered) {
        final title = g.title(locale);

        if (lang == 'zh' || lang == 'vi') {
          test('${g.id} really has a $lang title (not an English fallback)', () {
            // Without this, a guide whose overlay has no `title` would be
            // searched by its English title and the test below would pass
            // while telling us nothing about $lang (감사 05/034 S-3b).
            expect(g.i18n[lang]!['title'], isNotNull);
            expect(title, g.i18n[lang]!['title']);
          });
        }

        test('${g.id} is found by its $lang title', () {
          final hits = searchGuideItems(guides, title);
          expect(hits, contains(g), reason: '「$title」 found nothing for ${g.id}');
          // An exact title match ranks first; another guide may only tie with
          // it by carrying the very same title.
          expect(hits.first.title(locale), title,
              reason: '「$title」 ranked ${hits.first.id} above ${g.id}');
        });

        // Nobody types a whole title. A few characters in, the guide has to be
        // in the list already (감사 05/034 S-3a) — anywhere in it, since exact
        // and prefix matches of other guides may rank above it.
        test('${g.id} is found by the start of its $lang title', () {
          final typed = title.length <= 4 ? title : title.substring(0, 4);
          expect(searchGuideItems(guides, typed), contains(g),
              reason: '「$typed」 (start of 「$title」) missed ${g.id}');
        });

        if (lang == 'zh' || lang == 'vi') {
          test('${g.id} is found by each of its $lang search aliases', () {
            final aliases = (g.i18n[lang]!['search_aliases'] as List?)
                    ?.cast<String>() ??
                const [];
            expect(aliases, isNotEmpty, reason: '${g.id} has no $lang aliases');
            for (final alias in aliases) {
              expect(searchGuideItems(guides, alias), contains(g),
                  reason: 'alias 「$alias」 missed ${g.id}');
            }
          });
        }

        if (lang == 'vi') {
          test('${g.id} is found with the tone marks left off', () {
            final typed = _plain(title);
            expect(searchGuideItems(guides, typed), contains(g),
                reason: '「$typed」 (for 「$title」) found nothing for ${g.id}');
          });

          test('${g.id} aliases are found with the tone marks left off', () {
            final aliases = (g.i18n['vi']!['search_aliases'] as List?)
                    ?.cast<String>() ??
                const [];
            for (final alias in aliases) {
              final typed = _plain(alias);
              expect(searchGuideItems(guides, typed), contains(g),
                  reason: 'untoned alias 「$typed」 (for 「$alias」) missed ${g.id}');
            }
          });
        }
      }
    });
  }

  test('a query in one language does not need the app to be in it', () {
    // The reader may type Korean while the app is in Chinese, or the reverse;
    // search looks at every language at once.
    final zh = guides.where((g) => g.i18n.containsKey('zh')).toList();
    expect(zh, isNotEmpty);
    for (final g in zh.take(3)) {
      expect(searchGuideItems(guides, g.title(const Locale('zh'))), contains(g));
      expect(searchGuideItems(guides, g.title(const Locale('ko'))), contains(g));
    }
  });

  test('a Vietnamese query typed with separate tone marks still matches', () {
    // The same word can arrive decomposed (NFD): `Thẻ cư trú` as
    // `The` + hook, `cu` + horn, `tru` + acute. A paste from a browser or some
    // keyboards produces this (B 03/054 SF-02).
    final arc = guides.firstWhere((g) => g.id == 'arc-issue');
    expect(arc.i18n['vi']?['title'], isNotNull);
    const decomposed = 'Thẻ cư trú';
    expect(searchGuideItems(guides, decomposed), contains(arc),
        reason: 'decomposed 「$decomposed」 missed arc-issue');
    // …and mixed: some marks separate, some precomposed.
    expect(searchGuideItems(guides, 'Thẻ cư trú'), contains(arc));
  });

  test('a slash separates alternatives, and a single Han character is allowed', () {
    // 「D-4/D-2」 is how a reader types what the guides write as 「D-4 → D-2」
    // (B 03/054 N-02).
    final change = guides.firstWhere((g) => g.id == 'status-change-d4-to-d2');
    expect(searchGuideItems(guides, 'D-4/D-2'), contains(change));
    expect(searchGuideItems(guides, 'D-4 / D-2'), contains(change));
    // …but a slash is not simply deleted, or 「3/4」 would become the query 「34」
    // (B 03/054 NEW-SF-02). The catalogue has no such title, so this is shown on
    // two made-up guides.
    final thirtyFour = AdminGuideItem.fromJson(const {
      'id': 'thirty-four',
      'categoryId': 'immigration',
      'title_ko': '34',
      'title_en': '34',
    });
    final threeOfFour = AdminGuideItem.fromJson(const {
      'id': 'three-of-four',
      'categoryId': 'immigration',
      'title_ko': '3/4 단계',
      'title_en': '3/4 steps',
    });
    final pair = [thirtyFour, threeOfFour];
    // 「34」 is an exact title match for the first guide, 「3/4」 for the second.
    // If the slash were simply deleted both queries would be the string 34 and
    // the first guide would win both times.
    expect(searchGuideItems(pair, '34').first, thirtyFour);
    expect(searchGuideItems(pair, '3/4').first, threeOfFour);

    // A single Han character stays searchable: unlike a lone Latin letter it is
    // a word, so it matches broadly on purpose. The policy is "allowed, broad"
    // (B 03/054 N-01); a second character narrows it.
    final oneChar = searchGuideItems(guides, '证');
    expect(oneChar.length, greaterThan(1));
    final twoChar = searchGuideItems(guides, '证明书');
    expect(twoChar.length, lessThan(oneChar.length));
    expect(twoChar, contains(guides.firstWhere((g) => g.id == 'certificate-issue')));
    // A lone Latin letter still only matches an exact title or alias.
    expect(searchGuideItems(guides, 'd'), isEmpty);
  });
}
