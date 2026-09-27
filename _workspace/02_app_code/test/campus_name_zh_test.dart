import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Campus names in the Chinese files follow one notation (감사 05/033 S-1,
/// 조사 04/014 ZH-S2): the romanised name, plus the Korean name in brackets
/// once per guide the first time that campus appears, e.g.
/// `Seunghak校区(승학캠퍼스)`. Hanzi spellings are guesses at an official name
/// that was never confirmed, so none may come back.
///
/// The map chips (`map_campus_*`) carry the romanised name alone — the Korean
/// gloss would double the chip width on the three-way toggle.
void main() {
  final arb = File('lib/l10n/app_zh.arb').readAsStringSync();
  final guidesRaw = File('lib/data/i18n/guides_zh.json').readAsStringSync();
  // A field is either a string or a list of strings (`…lines`, `checklist`,
  // `tips`), so the list items have to be counted too.
  Iterable<String> strings(Object? value) {
    if (value is String) return [value];
    if (value is Map) return value.values.expand(strings);
    if (value is Iterable) return value.expand(strings);
    return const [];
  }
  final guides = (jsonDecode(guidesRaw) as Map).map((id, fields) =>
      MapEntry(id as String, strings(fields).join('\n')));

  const campuses = {
    'Seunghak': '승학캠퍼스',
    'Bumin': '부민캠퍼스',
    'Gudeok': '구덕캠퍼스',
  };

  test('no guessed hanzi campus spelling comes back', () {
    // Everything that came up as a candidate while the official spelling was
    // unconfirmed: 富民/釜民/九德 from the first drafts, and 承学·昇鶴·乘鶴 (and their
    // simplified forms) for 승학 from the two Wikipedias (감사 05/034 S-2).
    const guesses = ['釜民', '富民', '九德', '承学', '承鹤', '承鶴',
                     '昇鶴', '昇鹤', '乘鶴', '乘鹤'];
    for (final name in guesses) {
      for (final file in {'app_zh.arb': arb, 'guides_zh.json': guidesRaw}.entries) {
        expect(file.value.contains(name), isFalse,
            reason: '${file.key} still spells a campus as $name');
      }
    }
  });

  test('every romanised name in front of 校区 is one of the three', () {
    // A banned list only catches the spellings we thought of; this catches any
    // new hanzi or misspelt roman name in that position (감사 05/034 S-2).
    for (final guide in guides.entries) {
      for (final m in RegExp(r'([A-Za-z]+)校区').allMatches(guide.value)) {
        expect(campuses.keys, contains(m.group(1)),
            reason: '${guide.key} writes ${m.group(0)}');
      }
    }
  });

  test('nothing but an ordinary word may sit in front of 校区 in hanzi', () {
    // The rule above only sees a roman prefix, so a brand-new hanzi name such as
    // `釜山校区` would slip past both it and the banned list (감사 05/035 SF-1).
    // These are the characters that legitimately precede 校区 today — all of
    // them ordinary words ("其他校区", "位于…校区"), never a name.
    const ordinary = '、个于他及各同在开按有用的认请';
    for (final guide in guides.entries) {
      for (final m in RegExp(r'(.?)校区').allMatches(guide.value)) {
        final before = m.group(1)!;
        if (before.isEmpty || RegExp(r'[A-Za-z]').hasMatch(before)) continue;
        expect(ordinary.contains(before), isTrue,
            reason: '${guide.key} writes 「$before校区」. If that is a campus '
                'name, write it as Seunghak/Bumin/Gudeok校区; if it is an '
                'ordinary word, add "$before" to this list.');
      }
    }
  });

  test('the map chips use the romanised names', () {
    final arbJson = (jsonDecode(arb) as Map).cast<String, dynamic>();
    for (final entry in campuses.entries) {
      final key = 'map_campus_${entry.key.toLowerCase()}';
      expect(arbJson[key], entry.key, reason: key);
    }
  });

  // A hall that sits outside the campuses, such as `Gudeok馆`, is a building
  // name and carries no gloss; the rule applies to `…校区`.
  test('each guide that names a campus glosses it in Korean exactly once', () {
    for (final guide in guides.entries) {
      for (final campus in campuses.entries) {
        final named = RegExp('${RegExp.escape(campus.key)}校区')
            .allMatches(guide.value)
            .length;
        final glossed = RegExp('${RegExp.escape(campus.key)}校区'
                '\\(${RegExp.escape(campus.value)}\\)')
            .allMatches(guide.value)
            .length;
        if (named == 0) {
          expect(glossed, 0, reason: '${guide.key} / ${campus.key}');
          continue;
        }
        expect(glossed, 1,
            reason: '${guide.key} names ${campus.key}校区 $named time(s) but '
                'glosses it $glossed time(s); the rule is once, at the first '
                'mention, as ${campus.key}校区(${campus.value})');

        // …and it has to be the FIRST mention, not just any one of them
        // (감사 05/034 S-1). The text is joined in field order, which is the
        // order the generator writes and roughly the order the screen renders.
        final first = RegExp('${RegExp.escape(campus.key)}校区')
            .firstMatch(guide.value)!
            .start;
        final glossAt = RegExp('${RegExp.escape(campus.key)}校区'
                '\\(${RegExp.escape(campus.value)}\\)')
            .firstMatch(guide.value)!
            .start;
        expect(glossAt, first,
            reason: '${guide.key} glosses ${campus.key}校区 at a later mention, '
                'not the first one');
      }
    }
  });
}
