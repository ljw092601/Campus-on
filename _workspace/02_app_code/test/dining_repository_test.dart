import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';

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

  test('availability: unpublished != closed, legacy empty-meals = closed', () {
    // Explicit status from Firestore data wins.
    final unpublished = CafeteriaMenu.fromJson(const {
      'id': 'x',
      'campus': 'seunghak',
      'status': 'unpublished',
    });
    expect(unpublished.isUnpublished, isTrue);
    expect(unpublished.isClosed, isFalse);

    final closed = CafeteriaMenu.fromJson(const {
      'id': 'x',
      'campus': 'seunghak',
      'status': 'closed',
    });
    expect(closed.isClosed, isTrue);
    expect(closed.isUnpublished, isFalse);

    // Legacy rule (mock data): no status + empty meals reads as closed.
    final legacy = CafeteriaMenu.fromJson(const {
      'id': 'x',
      'campus': 'seunghak',
    });
    expect(legacy.status, DiningAvailability.closed);

    // toJson always carries the resolved status.
    expect(unpublished.toJson()['status'], 'unpublished');
  });

  test('meals are shown breakfast → lunch → dinner regardless of sheet order',
      () {
    // L-15: the admin sheet rows can arrive in any order; the entity owns
    // the display order and the sort is stable for same-slot duplicates.
    final menu = CafeteriaMenu.fromJson(const {
      'id': 'x',
      'campus': 'seunghak',
      'meals': [
        {'type': 'dinner', 'items': ['d']},
        {'type': 'lunch', 'items': ['l1']},
        {'type': 'breakfast', 'items': ['b']},
        {'type': 'lunch', 'items': ['l2']},
      ],
    });
    expect(menu.meals.map((m) => m.type).toList(),
        [MealType.breakfast, MealType.lunch, MealType.lunch, MealType.dinner]);
    expect(menu.meals.map((m) => m.items.single).toList(),
        ['b', 'l1', 'l2', 'd']);

    // A hand-built (const) menu is not re-ordered in place, but the display
    // accessor still yields slot order.
    const handBuilt = CafeteriaMenu(
      id: 'y',
      nameKo: '',
      nameEn: '',
      campus: Campus.bumin,
      meals: [
        Meal(type: MealType.dinner, items: ['d']),
        Meal(type: MealType.breakfast, items: ['b']),
      ],
    );
    expect(handBuilt.mealsInSlotOrder.map((m) => m.type).toList(),
        [MealType.breakfast, MealType.dinner]);
    expect(handBuilt.meals.first.type, MealType.dinner);
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
