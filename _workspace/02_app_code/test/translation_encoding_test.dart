import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Text that lost its diacritics on the way into a file.
///
/// Four Vietnamese guides shipped into the build with `ứng phó khẩn cấp`
/// written as `?ng ph? kh?n c?p` — 2,375 question marks wedged inside words.
/// Nothing caught it: the JSON was valid, the field counts matched, and the
/// screen simply showed the question marks. A `?` inside a word is never
/// punctuation, so it is a reliable tell.
void main() {
  // A question mark *followed* by a letter is the tell: `?ng ph? kh?n`. A
  // question mark after a word is ordinary punctuation — counting those made
  // the check mean 'no guide asks more than four questions' rather than 'no
  // text is damaged' (감사 05/042 NIT-1). More than one in a single string is
  // the second signal.
  final startsWord = RegExp(r'\?(?=[A-Za-zÀ-ỹ])');

  int damage(Object? value) {
    if (value is String) {
      final hits = startsWord.allMatches(value).length;
      return hits > 0 ? hits : (value.split('?').length - 1 >= 2 ? 1 : 0);
    }
    if (value is List) return value.fold(0, (n, v) => n + damage(v));
    if (value is Map) return value.values.fold(0, (n, v) => n + damage(v));
    return 0;
  }

  for (final file in const [
    'lib/data/i18n/guides_vi.json',
    'lib/data/i18n/guides_zh.json',
    'tool/i18n/place_vi.json',
    'tool/i18n/place_zh.json',
    'tool/i18n/place_en.json',
    'tool/i18n/calendar_vi.json',
    'tool/i18n/calendar_zh.json',
    'lib/l10n/app_vi.arb',
    'lib/l10n/app_zh.arb',
  ]) {
    test('$file carries no half-written text', () {
      final doc = jsonDecode(File(file).readAsStringSync());
      final worst = <String, int>{};
      (doc as Map).forEach((key, value) {
        final n = damage(value);
        // One is enough now that the signal is specific.
        if (n >= 1) worst[key.toString()] = n;
      });
      expect(worst, isEmpty,
          reason: 'question marks inside words — the text lost its diacritics '
              'somewhere between the translator and this file. Rewrite those '
              'entries as UTF-8; do not pipe them through a console.');
    });
  }
}
