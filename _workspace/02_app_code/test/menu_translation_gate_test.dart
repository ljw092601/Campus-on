import 'package:campus_on/data/i18n/place_translations.g.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/facility.dart' show Campus;
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/repositories/dining_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// A menu line served without a translation shows in Korean to everyone.
///
/// This is the gate, and it lives here because `flutter test` only runs what is
/// under `test/` — in `tool/` it passed for weeks without anyone running it
/// (감사 05/042 SF-4). The scan that *writes* the to-do list is a tool, not a
/// test: `python tool/i18n/menu_scan.dart` via `flutter test` on demand.
///
/// The gate takes a repository, so the real menu can be put under it later. It
/// will take more than swapping one line, though: this scan asks for a fixed
/// 28 days from a date in the sample data, and a real repository that answers
/// those days with nothing would make the gate pass while today's untranslated
/// menu went out in Korean (B 03/078 SF-04). Connecting the API means choosing
/// the window with it, and failing when the window comes back empty.
void main() {
  const days = 28;
  final start = DateTime(2026, 9, 7);

  Future<Set<String>> untranslated(DiningRepository repo) async {
    final gaps = <String>{};
    for (var d = 0; d < days; d++) {
      for (final c in await repo.getMenus(start.add(Duration(days: d)))) {
        for (final m in c.meals) {
          for (final item in m.items) {
            final row = menuItemI18n[item];
            for (final lang in const ['en', 'zh', 'vi']) {
              if ((row?[lang] ?? '').trim().isEmpty) gaps.add('$item ($lang)');
            }
          }
        }
      }
    }
    return gaps;
  }

  test('every menu line served is translated into all three languages',
      () async {
    expect(await untranslated(MockDiningRepository()), isEmpty,
        reason: 'these lines have no translation and will show in Korean. '
            'Run: flutter test --no-pub tool/i18n/menu_scan_test.dart, fill '
            'place_{en,zh,vi}.json, then '
            'python tool/i18n/i18n_tool.py place-gen');
  });

  test('the gate can fail — an untranslated dish is reported', () async {
    // Proof that the check is load-bearing. Asserting that an unknown dish is
    // missing from the table said nothing about the gate: `untranslated` was
    // never called, so it could have returned an empty set for ever and both
    // tests would still have passed (감사 05/044 SF-1). This runs the gate.
    final gaps = await untranslated(_OneDayRepository('내일의새로운메뉴'));
    expect(gaps, containsAll(const [
      '내일의새로운메뉴 (en)',
      '내일의새로운메뉴 (zh)',
      '내일의새로운메뉴 (vi)',
    ]));
  });
}

/// Serves one cafeteria, one lunch, one line — whatever it is handed.
class _OneDayRepository implements DiningRepository {
  _OneDayRepository(this.line);

  final String line;

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async => [
        CafeteriaMenu(
          id: 'test-cafeteria',
          nameKo: '시험용 식당',
          nameEn: 'Test cafeteria',
          campus: Campus.seunghak,
          meals: [Meal(type: MealType.lunch, items: [line])],
          status: DiningAvailability.open,
        ),
      ];
}
