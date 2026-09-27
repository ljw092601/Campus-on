import 'dart:convert';
import 'dart:io';

import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped language must define the same UI strings with the same
/// placeholders. A missing key silently falls back to English at build time,
/// which is fine for a half-finished translation but must never hide a typo in
/// a key name or a dropped {count} placeholder.

Map<String, dynamic> _arb(String lang) => (jsonDecode(
        File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map)
    .cast<String, dynamic>();

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String value) => RegExp(r'\{(\w+)\}')
    .allMatches(value)
    .map((m) => m.group(1)!)
    .toSet();

void main() {
  final template = _arb('en');
  final templateKeys = _keys(template);

  test('every language ships the same key set', () {
    for (final lang in appLanguageCodes) {
      final keys = _keys(_arb(lang));
      expect(keys.difference(templateKeys), isEmpty,
          reason: '$lang has keys English does not');
      expect(templateKeys.difference(keys), isEmpty,
          reason: '$lang is missing keys');
    }
  });

  test('placeholders and non-empty values match the template', () {
    for (final lang in appLanguageCodes) {
      final arb = _arb(lang);
      for (final key in templateKeys) {
        final value = arb[key];
        expect(value, isA<String>(), reason: '$lang/$key');
        expect((value as String).trim(), isNotEmpty, reason: '$lang/$key');
        expect(_placeholders(value), _placeholders(template[key] as String),
            reason: '$lang/$key placeholders');
      }
    }
  });
}
