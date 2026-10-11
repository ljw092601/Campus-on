import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/i18n/guide_translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app reads only the generated `guide_translations.g.dart`; the translators
/// edit only the JSON. If someone forgets `python tool/i18n/i18n_tool.py gen`,
/// every other test still passes while the app shows yesterday's wording
/// (감사 05/034 S-4). This compares the two and fails until `gen` is run.
///
/// It compares path by path, not just the set of strings: moving a sentence from
/// `sections[0].notes[0].lines` to `sections[1].notes[0].lines` without
/// regenerating would otherwise pass, and the app would then show that sentence
/// under a different heading (감사 05/035 SF-2).

/// Turns the generated tree back into the flat paths the JSON uses — the
/// inverse of `_nest` in `i18n_tool.py`. A list of strings is a leaf; a list of
/// maps is an indexed child.
void _flatten(Object? node, String prefix, Map<String, Object?> out) {
  if (node is Map) {
    node.forEach((key, value) {
      final path = prefix.isEmpty ? '$key' : '$prefix.$key';
      if (value is List && value.every((e) => e is String)) {
        out[path] = List<String>.from(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          _flatten(value[i], '$prefix${prefix.isEmpty ? '' : '.'}$key[$i]', out);
        }
      } else if (value is Map) {
        _flatten(value, path, out);
      } else {
        out[path] = value;
      }
    });
  }
}

void main() {
  for (final lang in guideTranslationsByLanguage.keys) {
    group(lang, () {
      final json = (jsonDecode(File('lib/data/i18n/guides_$lang.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
      final generated = guideTranslationsByLanguage[lang]!;

      test('the generated file covers the same guides as the JSON', () {
        expect(generated.keys.toSet(), json.keys.toSet(),
            reason: 'run: python tool/i18n/i18n_tool.py gen');
      });

      test('every field sits at the same path, with the same text', () {
        for (final id in json.keys) {
          final flat = <String, Object?>{};
          _flatten(generated[id], '', flat);
          final fromJson = (json[id] as Map).cast<String, dynamic>();

          expect(flat.keys.toSet(), fromJson.keys.toSet(),
              reason: '$lang/$id: field paths differ — the generated file is '
                  'out of date, run: python tool/i18n/i18n_tool.py gen');
          for (final path in fromJson.keys) {
            final want = fromJson[path];
            final got = flat[path];
            if (want is List) {
              expect(got, want, reason: '$lang/$id/$path differs — run gen');
            } else {
              expect(got, want, reason: '$lang/$id/$path differs — run gen');
            }
          }
        }
      });
    });
  }
}
