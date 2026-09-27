// Finds menu lines that have no translation yet, and writes them where a
// translator can pick them up.
//
//   flutter test --no-pub tool/i18n/menu_scan_test.dart
//
// The cafeteria menu is rewritten every day. This scan reads
// MockDiningRepository — sample data, and the screen says so. It does **not**
// read the school API: swapping the source means injecting a repository here
// (감사 05/042 SF-4). The gate that fails on an untranslated line lives in
// test/menu_translation_gate_test.dart, where `flutter test` runs it.
//
// The loop:
//
//   1. scan a stretch of days for the lines actually served
//   2. write the ones with no translation to tool/i18n/menu_todo.json
//   3. a translator fills them into place_{zh,vi,en}.json
//   4. `python tool/i18n/i18n_tool.py place-gen` + `place-check`
//
// Nothing here guesses at a translation, and nothing here reads ingredients
// out of a dish name: a menu line is a name, not a recipe.
import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/i18n/place_translations.g.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// How many days ahead of the start date to look.
const scanDays = 28;

void main() {
  test('scan the served menu for lines with no translation', () async {
    final repo = MockDiningRepository();
    final start = DateTime(2026, 9, 7);

    final seen = <String, int>{};          // line -> how many times served
    var open = 0, closed = 0, unpublished = 0;
    for (var d = 0; d < scanDays; d++) {
      final day = start.add(Duration(days: d));
      for (final c in await repo.getMenus(day)) {
        switch (c.status) {
          case DiningAvailability.open:
            open++;
          case DiningAvailability.closed:
            closed++;
          case DiningAvailability.unpublished:
            unpublished++;
        }
        for (final m in c.meals) {
          for (final item in m.items) {
            seen[item] = (seen[item] ?? 0) + 1;
          }
        }
      }
    }

    final missing = <String, Map<String, dynamic>>{};
    for (final entry in seen.entries) {
      final row = menuItemI18n[entry.key];
      final gaps = [
        for (final lang in const ['en', 'zh', 'vi'])
          if ((row?[lang] ?? '').trim().isEmpty) lang,
      ];
      if (gaps.isNotEmpty) {
        missing[entry.key] = {'served': entry.value, 'missing': gaps};
      }
    }

    final doc = {
      '_what': '번역이 없는 학식 메뉴 줄. 번역자가 place_{en,zh,vi}.json의 menu_items에 채운다.',
      '_generated_by': 'flutter test --no-pub tool/i18n/menu_scan_test.dart',
      '_source': 'MockDiningRepository (샘플 식단 — 화면에도 예시라고 안내한다). '
          '학교 API가 붙으면 같은 스캔이 실제 식단을 읽는다.',
      '_after_filling': 'python tool/i18n/i18n_tool.py place-gen && place-check',
      'scanned': {
        'from': start.toIso8601String().substring(0, 10),
        'days': scanDays,
        'cafeteria_days_open': open,
        'cafeteria_days_closed': closed,
        'cafeteria_days_unpublished': unpublished,
        'distinct_lines': seen.length,
      },
      'missing': missing,
    };
    File('tool/i18n/menu_todo.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(doc)}\n');

    // ignore: avoid_print
    print('scanned $scanDays days from ${doc['scanned']}'
        ' → ${seen.length} distinct lines, ${missing.length} untranslated');

    // The scan itself must keep working even when nothing is missing.
    expect(seen, isNotEmpty, reason: 'the scan found no menu at all');
    expect(open, greaterThan(0), reason: 'no day was open in the window');
  });

}
