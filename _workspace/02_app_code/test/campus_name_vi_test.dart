import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vietnamese campus notation, the same rule as Chinese (감사 05/034 N-3):
/// one form, `cơ sở Seunghak` (capitalised at the start of a sentence or a
/// label), with the Korean name in brackets once per guide at the first
/// mention — `cơ sở Bumin (부민캠퍼스)` — so a reader can show it to staff.
///
/// A hall or an address that merely contains the name (`Seunghak 1`,
/// `Gudeok-ro`, a list label standing alone) is not a campus mention and
/// carries no gloss, which is why the pattern requires `cơ sở` in front.
void main() {
  final raw = File('lib/data/i18n/guides_vi.json').readAsStringSync();

  Iterable<String> strings(Object? value) {
    if (value is String) return [value];
    if (value is Map) return value.values.expand(strings);
    if (value is Iterable) return value.expand(strings);
    return const [];
  }

  final guides = (jsonDecode(raw) as Map)
      .map((id, fields) => MapEntry(id as String, strings(fields).join('\n')));

  const campuses = {
    'Seunghak': '승학캠퍼스',
    'Bumin': '부민캠퍼스',
    'Gudeok': '구덕캠퍼스',
  };

  RegExp named(String name) => RegExp('cơ sở ${RegExp.escape(name)}',
      caseSensitive: false);
  RegExp glossed(String name, String korean) => RegExp(
      'cơ sở ${RegExp.escape(name)} \\(${RegExp.escape(korean)}\\)',
      caseSensitive: false);

  test('a campus is always written as cơ sở <name>', () {
    // `khuôn viên` is fine as a common noun ("outside the campus") but not as
    // the campus name itself; `campus` and `phân hiệu` are the other two ways
    // this drifts (감사 05/035 SF-1).
    for (final guide in guides.entries) {
      for (final wrong in ['khuôn viên', 'campus', 'phân hiệu']) {
        for (final name in campuses.keys) {
          expect(
              RegExp('${RegExp.escape(wrong)} ${RegExp.escape(name)}',
                      caseSensitive: false)
                  .hasMatch(guide.value),
              isFalse,
              reason: '${guide.key} writes $wrong $name; use cơ sở $name');
        }
      }
    }
  });

  test('every name after cơ sở is one of the three campuses', () {
    // `cơ sở` is also an everyday phrase ("cơ sở giáo dục"), so only a
    // capitalised word after it is a place name — but a name written in
    // lowercase is a mistake we still want to see, so the comparison itself
    // ignores case (감사 05/035 SF-1).
    final known = {for (final n in campuses.keys) n.toLowerCase()};
    for (final guide in guides.entries) {
      for (final m
          in RegExp(r'[Cc]ơ sở ([A-Za-z]+)').allMatches(guide.value)) {
        final word = m.group(1)!;
        if (word == word.toLowerCase() && !known.contains(word.toLowerCase())) {
          continue; // an ordinary Vietnamese word, e.g. cơ sở giáo dục
        }
        expect(known, contains(word.toLowerCase()),
            reason: '${guide.key} writes ${m.group(0)}');
        expect(campuses.keys, contains(word),
            reason: '${guide.key} writes ${m.group(0)} in lowercase; the campus '
                'name is capitalised');
      }
    }
  });

  test('each guide glosses a campus in Korean exactly once, at the first mention',
      () {
    for (final guide in guides.entries) {
      for (final campus in campuses.entries) {
        final mentions = named(campus.key).allMatches(guide.value).length;
        final glosses =
            glossed(campus.key, campus.value).allMatches(guide.value).toList();
        if (mentions == 0) {
          expect(glosses, isEmpty, reason: '${guide.key} / ${campus.key}');
          continue;
        }
        expect(glosses.length, 1,
            reason: '${guide.key} names cơ sở ${campus.key} $mentions time(s) '
                'but glosses it ${glosses.length} time(s)');
        expect(glosses.single.start, named(campus.key).firstMatch(guide.value)!.start,
            reason: '${guide.key} glosses cơ sở ${campus.key} at a later '
                'mention, not the first one');
      }
    }
  });
}
