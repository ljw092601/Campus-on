import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/i18n/guide_translations.g.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/firestore_seed/guide_seed_codec.dart';

/// Guide text is painted as plain text. Nothing renders Markdown, so a `**`
/// left in the wording shows up on the screen as two asterisks around the word.
///
/// That is exactly what happened to the four guides added on 2026-09-26: the
/// Korean and English were written with `**...**` for emphasis, the Chinese and
/// Vietnamese translations copied the markers faithfully, and every reader saw
/// `重要的是**顺序**。` on the guide screen. No test caught it — the JSON was
/// valid, the field counts matched, and the strings were genuinely translated.
/// Found by looking at a browser screenshot at 320dp (리드 2026-09-27).
///
/// The rule this pins: emphasis belongs in the sentence, not in markup.
const _markup = [
  '**', // bold
  '__', // bold, the other spelling
  '- [ ]', // task list
  '](http', // inline link
];

Iterable<String> _strings(Object? node) sync* {
  if (node is String) {
    yield node;
  } else if (node is List) {
    for (final e in node) {
      yield* _strings(e);
    }
  } else if (node is Map) {
    for (final e in node.values) {
      yield* _strings(e);
    }
  }
}

void _check(String where, Iterable<String> texts) {
  final bad = <String>[];
  for (final t in texts) {
    for (final m in _markup) {
      if (t.contains(m)) {
        bad.add('$m in: ${t.length > 60 ? '${t.substring(0, 60)}…' : t}');
      }
    }
  }
  expect(bad, isEmpty, reason: '$where carries markup the app never renders');
}

void main() {
  test('the Korean and English guide text carries no markup', () {
    // Through the seed serializer, so a field added later is covered without
    // anyone remembering to list it here.
    _check('MockData.guideItems',
        _strings(guideSeedDocuments(MockData.guideItems)));
  });

  test('the extracted source the translators read carries no markup', () {
    // The source files are what `i18n_tool.py source` writes and translators
    // work from. Cleaning only the app data would have let the markers come
    // back through the next extraction (B 03/078 SF-01).
    final dir = Directory('tool/i18n/source');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    expect(files, isNotEmpty, reason: 'no source files found to check');
    for (final f in files) {
      _check(f.path, _strings(jsonDecode(f.readAsStringSync())));
    }
  });

  for (final lang in guideTranslationsByLanguage.keys) {
    test('the $lang guide file carries no markup', () {
      final json = jsonDecode(
          File('lib/data/i18n/guides_$lang.json').readAsStringSync());
      _check('guides_$lang.json', _strings(json));
    });

    test('the generated $lang table carries no markup', () {
      _check('guide_translations.g.dart ($lang)',
          _strings(guideTranslationsByLanguage[lang]));
    });
  }
}
