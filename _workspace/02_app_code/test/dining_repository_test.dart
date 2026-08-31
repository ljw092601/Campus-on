import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';

void main() {
  final repo = MockDiningRepository();

  test('weekday menus: 3 cafeterias, meals in slot order with items', () async {
    final monday = DateTime(2026, 8, 31); // a Monday
    final menus = await repo.getMenus(monday);

    expect(menus, hasLength(3));
    for (final c in menus) {
      expect(c.isClosed, isFalse);
      for (final m in c.meals) {
        expect(m.items, isNotEmpty);
      }
      // Slot order breakfast → dinner is preserved.
      final order = [for (final m in c.meals) m.type.index];
      expect(order, List.of(order)..sort());
    }
    // Seunghak serves all three meals in the placeholder data.
    final seunghak = menus.firstWhere((c) => c.id == 'seunghak-student');
    expect(seunghak.meals.map((m) => m.type),
        [MealType.breakfast, MealType.lunch, MealType.dinner]);
  });

  test('weekend: cafeterias returned but closed', () async {
    final sunday = DateTime(2026, 8, 30);
    final menus = await repo.getMenus(sunday);
    expect(menus, hasLength(3));
    expect(menus.every((c) => c.isClosed), isTrue);
  });

  test('menus rotate by date (deterministic)', () async {
    final a = await repo.getMenus(DateTime(2026, 9, 1));
    final b = await repo.getMenus(DateTime(2026, 9, 2));
    final a2 = await repo.getMenus(DateTime(2026, 9, 1));
    String lunch(List<CafeteriaMenu> l) => l.first.meals
        .firstWhere((m) => m.type == MealType.lunch)
        .items
        .join(',');
    expect(lunch(a), lunch(a2)); // same day → same menu
    expect(lunch(a), isNot(lunch(b))); // adjacent days differ
  });
}
