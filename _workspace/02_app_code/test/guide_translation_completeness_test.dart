import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// B 03/110 S-1: `i18n_tool.py validate` only walks the fields a translation
/// file ALREADY has, so a path that never got translated is not an error — it
/// silently falls back to English on screen. That is how 16 values shipped
/// missing (`bank-account` 7 paths in both languages, `incident-response`
/// `links[8]` in vi) behind `validate` 0 problems and a passing generated-file
/// check.
///
/// `TRANSLATION_GUIDE.md` deliberately allows partial translations while a
/// language is being drafted, so `validate` keeps its behaviour. This test is
/// the release gate instead: zh and vi are shipping languages now, so every
/// path in the Korean source must exist in both.
///
/// If this fails after adding Korean text, the overlay needs the same paths —
/// not a weaker assertion.
void main() {
  final sourceDir = Directory('tool/i18n/source');

  Map<String, Set<String>> sourcePaths() {
    final out = <String, Set<String>>{};
    for (final f in sourceDir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.endsWith('.json') || name == '_index.json') continue;
      final fields =
          (jsonDecode(f.readAsStringSync()) as Map)['fields'] as Map;
      out[name.substring(0, name.length - 5)] = fields.keys.cast<String>().toSet();
    }
    return out;
  }

  Map<String, Set<String>> overlayPaths(String lang) {
    final raw =
        jsonDecode(File('lib/data/i18n/guides_$lang.json').readAsStringSync())
            as Map;
    return {
      for (final e in raw.entries)
        e.key as String: (e.value as Map).keys.cast<String>().toSet(),
    };
  }

  test('source has 41 guides', () {
    // r23: 38 + 대학원 길잡이 · 운전면허·전동킥보드 · 재난 대비.
    expect(sourcePaths(), hasLength(41));
  });

  for (final lang in const ['zh', 'vi']) {
    test('$lang 번역이 한국어 원문의 모든 경로를 덮는다', () {
      final src = sourcePaths();
      final have = overlayPaths(lang);
      final missing = <String, List<String>>{};
      for (final e in src.entries) {
        final gap = e.value.difference(have[e.key] ?? <String>{}).toList()
          ..sort();
        if (gap.isNotEmpty) missing[e.key] = gap;
      }
      expect(missing, isEmpty,
          reason: '$lang 에 없는 경로 — 화면에서 영어로 폴백한다:\n'
              '${missing.entries.map((e) => '  ${e.key}: ${e.value.join(', ')}').join('\n')}');
    });

    // 감사 05/062 S-1: 경로만 보면 `""` 와 `[]` 가 양쪽을 통과한다 — 경로는
    // 있으니 누락도 아니고 고아도 아니지만, 화면에는 빈 자리가 나온다.
    test('$lang 의 값이 비어 있지 않다', () {
      final empty = <String>[];
      overlayPaths(lang); // 파일 형식 확인
      final raw =
          jsonDecode(File('lib/data/i18n/guides_$lang.json').readAsStringSync())
              as Map;
      raw.forEach((gid, fields) {
        (fields as Map).forEach((path, v) {
          if (v is String && v.trim().isEmpty) empty.add('$gid/$path');
          if (v is List) {
            if (v.isEmpty) empty.add('$gid/$path (빈 배열)');
            for (var i = 0; i < v.length; i++) {
              if (v[i] is! String || (v[i] as String).trim().isEmpty) {
                empty.add('$gid/$path[$i]');
              }
            }
          }
        });
      });
      expect(empty, isEmpty, reason: '$lang 의 빈 값: ${empty.take(20)}');
    });

    test('$lang 에 원문에 없는 경로가 남아 있지 않다', () {
      // 섹션을 지우거나 재배치한 뒤 남은 고아 키를 잡는다. 고아 키는 화면에
      // 나오지 않으므로 조용히 쌓이고, 다음 재배치 때 엉뚱한 자리에 붙는다.
      final src = sourcePaths();
      final orphans = <String, List<String>>{};
      overlayPaths(lang).forEach((gid, keys) {
        final gap = keys.difference(src[gid] ?? <String>{}).toList()..sort();
        if (gap.isNotEmpty) orphans[gid] = gap;
      });
      expect(orphans, isEmpty, reason: '$lang 의 고아 키: $orphans');
    });
  }
}
