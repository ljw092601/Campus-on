import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/data/firestore/firestore_dining_repository.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';

void main() {
  final repo = MockDiningRepository(latency: Duration.zero);

  const expectedOrder = [
    'seunghak-faculty',
    'seunghak-student',
    'seunghak-engineering',
    'seunghak-library',
    'bumin-international',
    'bumin-dorm',
    'gudeok-student',
    'bumin-staff',
  ];

  group('mock: 8 cafeterias with the canonical static info', () {
    test('ids, campus group order and `order` match the school list',
        () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 7)); // Monday
      expect(menus.map((m) => m.id).toList(), expectedOrder);

      // 승학 first, then 구덕·부민 as one group ordered by `order`.
      expect(menus.take(4).map((m) => m.campusGroup).toSet(),
          {CampusGroup.seunghak});
      expect(menus.skip(4).map((m) => m.campusGroup).toSet(),
          {CampusGroup.gudeokBumin});
      expect(menus.take(4).map((m) => m.order).toList(), [1, 2, 3, 4]);
      expect(menus.skip(4).map((m) => m.order).toList(), [1, 2, 3, 4]);

      // The mock list is already in the order the Firestore repository sorts
      // into, so both data sources render identically.
      final sorted = [...menus]
        ..shuffle()
        ..sort(FirestoreDiningRepository.compareForDisplay);
      expect(sorted.map((m) => m.id).toList(), expectedOrder);
    });

    test('names, campuses, map pins', () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 7));
      final byId = {for (final m in menus) m.id: m};
      expect(byId['seunghak-faculty']!.nameKo, '교수회관 식당');
      expect(byId['seunghak-faculty']!.nameEn, 'Faculty Hall Cafeteria');
      expect(byId['seunghak-faculty']!.facilityId, 's08');
      expect(byId['seunghak-student']!.facilityId, 's02');
      expect(byId['seunghak-engineering']!.facilityId, isNull);
      expect(byId['seunghak-library']!.facilityId, 's10');
      expect(byId['bumin-international']!.facilityId, 'b05');
      expect(byId['bumin-dorm']!.facilityId, 'b05');
      expect(byId['gudeok-student']!.campus, Campus.gudeok);
      expect(byId['gudeok-student']!.facilityId, 'g12');
      expect(byId['bumin-staff']!.campus, Campus.bumin);
      expect(byId['bumin-staff']!.facilityId, isNull);
      expect(byId['gudeok-student']!.nameKo, '구덕 제2캠퍼스 학생회관');
    });

    test('service hours: windows, breaks, and no-hours cafeterias', () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 7));
      final byId = {for (final m in menus) m.id: m};

      final student = byId['seunghak-student']!.hoursSummary!;
      expect(student.open, '09:00');
      expect(student.close, '16:30');
      expect(student.breaks, const [
        ServiceHours(open: '09:30', close: '10:00'),
        ServiceHours(open: '14:30', close: '15:00'),
      ]);

      final library = byId['seunghak-library']!.hoursSummary!;
      expect(library.breaks, hasLength(2));
      expect(byId['seunghak-faculty']!.serviceHours,
          const [ServiceHours(open: '11:40', close: '13:30')]);
      expect(byId['bumin-dorm']!.serviceHours,
          const [ServiceHours(open: '16:50', close: '18:40')]);
      expect(byId['bumin-staff']!.serviceHours,
          const [ServiceHours(open: '11:00', close: '13:50')]);

      for (final id in [
        'seunghak-engineering',
        'bumin-international',
        'gudeok-student'
      ]) {
        expect(byId[id]!.serviceHours, isEmpty, reason: id);
        expect(byId[id]!.hoursSummary, isNull, reason: id);
        expect(byId[id]!.hoursKo, isNotNull, reason: '$id keeps a note');
      }
      expect(byId['seunghak-student']!.hoursKo, '천원의아침밥 09:00부터 선착순');
      expect(byId['seunghak-student']!.hoursNote(const Locale('en')),
          contains('09:00'));
      for (final m in menus) {
        for (final h in m.serviceHours) {
          expect(h.isValid, isTrue, reason: '${m.id} $h');
        }
      }
    });
  });

  group('mock: weekday sections per cafeteria', () {
    late Map<String, CafeteriaMenu> byId;
    setUp(() async {
      final menus = await repo.getMenus(DateTime(2026, 9, 8)); // Tuesday
      byId = {for (final m in menus) m.id: m};
    });

    List<(MealSlot, MenuKind)> shape(CafeteriaMenu m) =>
        [for (final s in m.sectionsInOrder) (s.slot, s.kind)];

    test('교수회관: lunch set 7,000 with 국·메인·반찬 2·김치', () {
      final m = byId['seunghak-faculty']!;
      expect(m.status, DiningAvailability.open);
      expect(shape(m), [(MealSlot.lunch, MenuKind.set)]);
      final s = m.sections.single;
      expect(s.price, 7000);
      expect(s.items, hasLength(5));
      expect(s.items.every((i) => i.price == null), isTrue);
    });

    test('학생회관: ₩1,000 breakfast + all-day set / a-la-carte / snack', () {
      final m = byId['seunghak-student']!;
      expect(shape(m), [
        (MealSlot.breakfast, MenuKind.thousandWon),
        (MealSlot.allDay, MenuKind.set),
        (MealSlot.allDay, MenuKind.alacarte),
        (MealSlot.allDay, MenuKind.snack),
      ]);
      final sections = m.sectionsInOrder;
      final breakfast = sections[0];
      expect(breakfast.price, 1000);
      expect(breakfast.items.single.price, isNull);
      expect(breakfast.note, contains('선착순'));
      expect(sections[1].price, 6000);
      final alacarte = sections[2];
      expect(alacarte.price, isNull);
      expect(alacarte.items.every((i) => i.price != null), isTrue);
      expect(alacarte.items.map((i) => i.name), contains(contains('국밥')));
      final snack = sections[3];
      expect(snack.items.map((i) => i.name), contains(contains('김밥')));
      expect(snack.items.every((i) => i.price != null), isTrue);
    });

    test('공과대학: lunch a-la-carte on Tue/Thu, unpublished otherwise',
        () async {
      final tue = byId['seunghak-engineering']!;
      expect(tue.status, DiningAvailability.open);
      expect(shape(tue), [(MealSlot.lunch, MenuKind.alacarte)]);
      expect(tue.sections.single.items.length, inInclusiveRange(1, 2));

      for (final day in [
        DateTime(2026, 9, 7), // Mon
        DateTime(2026, 9, 9), // Wed
        DateTime(2026, 9, 11), // Fri
      ]) {
        final m = (await repo.getMenus(day))
            .firstWhere((m) => m.id == 'seunghak-engineering');
        expect(m.sections, isEmpty, reason: '$day');
        expect(m.status, DiningAvailability.unpublished, reason: '$day');
        expect(m.isClosed, isFalse, reason: '$day');
      }
      final thu = (await repo.getMenus(DateTime(2026, 9, 10)))
          .firstWhere((m) => m.id == 'seunghak-engineering');
      expect(thu.status, DiningAvailability.open);
    });

    test('도서관: all-day set 6,500 + 2 a-la-carte', () {
      final m = byId['seunghak-library']!;
      expect(shape(m), [
        (MealSlot.allDay, MenuKind.set),
        (MealSlot.allDay, MenuKind.alacarte),
      ]);
      expect(m.sectionsInOrder[0].price, 6500);
      expect(m.sectionsInOrder[1].items, hasLength(2));
    });

    test('국제관: lunch set 6,500 + 2–3 a-la-carte', () {
      final m = byId['bumin-international']!;
      expect(shape(m), [
        (MealSlot.lunch, MenuKind.set),
        (MealSlot.lunch, MenuKind.alacarte),
      ]);
      expect(m.sectionsInOrder[0].price, 6500);
      expect(m.sectionsInOrder[1].items.length, inInclusiveRange(2, 3));
    });

    test('국제관 기숙사: ₩1,000 breakfast + dinner set 5,500', () {
      final m = byId['bumin-dorm']!;
      expect(shape(m), [
        (MealSlot.breakfast, MenuKind.thousandWon),
        (MealSlot.dinner, MenuKind.set),
      ]);
      expect(m.sectionsInOrder[0].price, 1000);
      expect(m.sectionsInOrder[0].note, contains('09:20'));
      expect(m.sectionsInOrder[1].price, 5500);
    });

    test('구덕 학생회관: lunch rice bowls 5,500–6,500 + snack', () {
      final m = byId['gudeok-student']!;
      expect(shape(m), [
        (MealSlot.lunch, MenuKind.alacarte),
        (MealSlot.lunch, MenuKind.snack),
      ]);
      for (final i in m.sectionsInOrder[0].items) {
        expect(i.name, endsWith('덮밥'));
        expect(i.price, inInclusiveRange(5500, 6500));
      }
    });

    test('부민 교직원: lunch set 7,000', () {
      final m = byId['bumin-staff']!;
      expect(shape(m), [(MealSlot.lunch, MenuKind.set)]);
      expect(m.sections.single.price, 7000);
    });

    test('every open section has items; set prices sit on the section', () {
      for (final m in byId.values) {
        for (final s in m.sections) {
          expect(s.items, isNotEmpty, reason: '${m.id} ${s.slot} ${s.kind}');
          if (s.kind.hasSectionPrice) {
            expect(s.price, isNotNull, reason: '${m.id} ${s.kind}');
          } else {
            expect(s.price, isNull, reason: '${m.id} ${s.kind}');
          }
        }
      }
    });
  });

  group('mock: weekends', () {
    test('Sunday: every cafeteria closed, no sections', () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 6));
      expect(menus, hasLength(8));
      for (final m in menus) {
        expect(m.status, DiningAvailability.closed, reason: m.id);
        expect(m.sections, isEmpty, reason: m.id);
      }
    });

    test('Saturday: closed except 학생회관 lunch a-la-carte', () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 5));
      for (final m in menus) {
        if (m.id == 'seunghak-student') {
          expect(m.status, DiningAvailability.open);
          expect(m.sections.single.slot, MealSlot.lunch);
          expect(m.sections.single.kind, MenuKind.alacarte);
        } else {
          expect(m.isClosed, isTrue, reason: m.id);
        }
      }
    });
  });

  group('mock: rotation', () {
    String dump(CafeteriaMenu m) => [
          for (final s in m.sectionsInOrder)
            '${s.slot.name}/${s.kind.name}:'
                '${s.items.map((i) => '${i.name}=${i.price}').join(',')}'
        ].join('|');

    test('same date → same menu; adjacent weekdays differ', () async {
      final a = await repo.getMenus(DateTime(2026, 9, 1));
      final a2 = await repo.getMenus(DateTime(2026, 9, 1));
      final b = await repo.getMenus(DateTime(2026, 9, 2));
      for (var i = 0; i < a.length; i++) {
        expect(dump(a[i]), dump(a2[i]), reason: a[i].id);
        if (a[i].sections.isNotEmpty && b[i].sections.isNotEmpty) {
          expect(dump(a[i]), isNot(dump(b[i])), reason: a[i].id);
        }
      }
    });

    test('each cafeteria shows at least 5 distinct menus over 2 weeks',
        () async {
      final seen = <String, Set<String>>{};
      final start = DateTime(2026, 9, 7); // Monday
      for (var d = 0; d < 14; d++) {
        final day = start.add(Duration(days: d));
        if (day.weekday > DateTime.friday) continue;
        for (final m in await repo.getMenus(day)) {
          if (m.sections.isEmpty) continue;
          seen.putIfAbsent(m.id, () => {}).add(dump(m));
        }
      }
      expect(seen.keys, containsAll(expectedOrder));
      for (final e in seen.entries) {
        final minimum = e.key == 'seunghak-engineering' ? 4 : 5;
        expect(e.value.length, greaterThanOrEqualTo(minimum),
            reason: '${e.key} repeats too soon');
      }
    });

    test('dates before the rotation epoch still resolve', () async {
      final menus = await repo.getMenus(DateTime(2025, 3, 3)); // Monday
      expect(menus, hasLength(8));
      expect(menus.first.sections, isNotEmpty);
    });
  });

  group('entity', () {
    test('availability: unpublished != closed, legacy empty = closed', () {
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

      // Legacy rule: no status + no sections reads as closed.
      final legacy = CafeteriaMenu.fromJson(const {
        'id': 'x',
        'campus': 'seunghak',
      });
      expect(legacy.status, DiningAvailability.closed);
      expect(unpublished.toJson()['status'], 'unpublished');
    });

    test('sections sort slot → kind regardless of sheet order, stable', () {
      final menu = CafeteriaMenu.fromJson(const {
        'id': 'x',
        'campus': 'seunghak',
        'sections': [
          {
            'slot': 'allDay',
            'kind': 'snack',
            'items': [
              {'name': 'snack'}
            ]
          },
          {
            'slot': 'lunch',
            'kind': 'alacarte',
            'items': [
              {'name': 'l-ala'}
            ]
          },
          {
            'slot': 'breakfast',
            'kind': 'thousandWon',
            'price': 1000,
            'items': [
              {'name': 'b'}
            ]
          },
          {
            'slot': 'lunch',
            'kind': 'set',
            'price': 7000,
            'items': [
              {'name': 'l-set-1'}
            ]
          },
          {
            'slot': 'lunch',
            'kind': 'set',
            'price': 7000,
            'items': [
              {'name': 'l-set-2'}
            ]
          },
          // Unknown slot/kind are dropped, not relabelled.
          {'slot': 'brunch', 'kind': 'set', 'items': []},
          {'slot': 'lunch', 'kind': 'buffet', 'items': []},
        ],
      });
      expect(menu.sections.map((s) => s.items.single.name).toList(),
          ['b', 'l-set-1', 'l-set-2', 'l-ala', 'snack']);

      const handBuilt = CafeteriaMenu(
        id: 'y',
        nameKo: '',
        nameEn: '',
        campus: Campus.bumin,
        sections: [
          MenuSection(
              slot: MealSlot.dinner,
              kind: MenuKind.set,
              items: [MenuItem(name: 'd')]),
          MenuSection(
              slot: MealSlot.breakfast,
              kind: MenuKind.thousandWon,
              items: [MenuItem(name: 'b')]),
        ],
      );
      expect(handBuilt.sectionsInOrder.map((s) => s.slot).toList(),
          [MealSlot.breakfast, MealSlot.dinner]);
      expect(handBuilt.sections.first.slot, MealSlot.dinner);
    });

    test('legacy meals document → one set section per meal', () {
      final menu = CafeteriaMenu.fromJson(const {
        'id': 'x',
        'campus': 'seunghak',
        'status': 'open',
        'meals': [
          {
            'type': 'dinner',
            'items': ['d'],
            'price': 5000
          },
          {
            'type': 'lunch',
            'items': ['l1', 'l2'],
            'price': 5500
          },
        ],
      });
      expect(menu.sections.map((s) => (s.slot, s.kind, s.price)).toList(), [
        (MealSlot.lunch, MenuKind.set, 5500),
        (MealSlot.dinner, MenuKind.set, 5000),
      ]);
      expect(menu.sections.first.items.map((i) => i.name), ['l1', 'l2']);
      expect(menu.sections.first.items.every((i) => i.price == null), isTrue);
    });

    test('hours: malformed windows are skipped, valid ones kept', () {
      final menu = CafeteriaMenu.fromJson(const {
        'id': 'x',
        'campus': 'seunghak',
        'hours': [
          {'open': '09:00', 'close': '09:30'},
          {'open': '10:00', 'close': '09:00'}, // close before open
          {'open': '9:00', 'close': '10:00'}, // not HH:mm
          {'open': '10:00', 'close': '24:00'}, // out of range
          {'open': '10:00'}, // missing close
          'noon', // wrong type
          {'open': '15:00', 'close': '16:30'},
        ],
      });
      expect(menu.serviceHours, const [
        ServiceHours(open: '09:00', close: '09:30'),
        ServiceHours(open: '15:00', close: '16:30'),
      ]);
      expect(menu.hoursSummary!.breaks,
          const [ServiceHours(open: '09:30', close: '15:00')]);
      expect(menu.toJson()['hours'], hasLength(2));
    });

    test('toJson round-trips a mock day', () async {
      final menus = await repo.getMenus(DateTime(2026, 9, 8));
      for (final m in menus) {
        final back = CafeteriaMenu.fromJson(m.toJson());
        expect(back.id, m.id);
        expect(back.status, m.status);
        expect(back.order, m.order);
        expect(back.serviceHours, m.serviceHours);
        expect(back.sections.length, m.sections.length);
        for (var i = 0; i < m.sections.length; i++) {
          final a = m.sectionsInOrder[i];
          final b = back.sections[i];
          expect((b.slot, b.kind, b.price, b.note), (a.slot, a.kind, a.price, a.note));
          expect(b.items.map((x) => (x.name, x.price)),
              a.items.map((x) => (x.name, x.price)));
        }
      }
    });
  });
}
