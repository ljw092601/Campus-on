// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/data/firestore/firestore_paths.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';

/// Minimal in-memory [DocumentSnapshot] — only `id` and `data()` are used by
/// the mapping helpers under test; no Firestore instance is required.
class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this.id, this._data);

  @override
  final String id;

  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('normalizeDiningStatus', () {
    test('passes the three allowed values through unchanged', () {
      expect(normalizeDiningStatus('open'), 'open');
      expect(normalizeDiningStatus('closed'), 'closed');
      expect(normalizeDiningStatus('unpublished'), 'unpublished');
    });

    test('coerces missing/typo/wrong-type values to unpublished', () {
      expect(normalizeDiningStatus(null), 'unpublished'); // missing field
      expect(normalizeDiningStatus('opne'), 'unpublished'); // typo
      expect(normalizeDiningStatus('OPEN'), 'unpublished'); // wrong case
      expect(normalizeDiningStatus(''), 'unpublished');
      expect(normalizeDiningStatus(42), 'unpublished'); // wrong type
    });
  });

  group('cafeteriaMenuFromData (Firestore join, pure core)', () {
    // A `cafeterias` doc as the admin sheet "식당" tab writes it (id injected
    // from the doc key by _normalize).
    const cafeteria = {
      'id': 'seunghak-student',
      'name_ko': '학생회관 식당',
      'name_en': 'Student Union Cafeteria',
      'campus': 'seunghak',
      'hours': [
        {'open': '09:00', 'close': '09:30'},
        {'open': '10:00', 'close': '14:30'},
        {'open': '15:00', 'close': '16:30'},
      ],
      'hours_ko': '천원의아침밥 09:00부터 선착순',
      'hours_en': '₩1,000 breakfast from 09:00, first come first served',
      'facilityId': 's02',
      'order': 2,
    };

    test('no menu doc for the day → unpublished with no sections', () {
      final menu = cafeteriaMenuFromData(cafeteria, null);
      expect(menu.id, 'seunghak-student');
      expect(menu.status, DiningAvailability.unpublished);
      expect(menu.sections, isEmpty);
      expect(menu.isClosed, isFalse);
      // Static info survives the join.
      expect(menu.order, 2);
      expect(menu.facilityId, 's02');
      expect(menu.serviceHours, hasLength(3));
      expect(menu.hoursSummary!.open, '09:00');
      expect(menu.hoursSummary!.close, '16:30');
      expect(menu.hoursSummary!.breaks, hasLength(2));
      expect(menu.hoursKo, '천원의아침밥 09:00부터 선착순');
    });

    test('menu doc missing status → unpublished, never open', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'cafeteriaId': 'seunghak-student',
        'date': '2026-09-10',
        // no 'status', no 'sections'
      });
      expect(menu.status, DiningAvailability.unpublished);
      // Regression guard: the old `?? 'open'` fallback announced "open" here,
      // and empty sections would otherwise legacy-fall to "closed".
      expect(menu.isClosed, isFalse);
    });

    test('menu doc with typo status → unpublished, not closed (D1)', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'status': 'opne', // admin typo
        'sections': [],
      });
      expect(menu.status, DiningAvailability.unpublished);
      expect(menu.isClosed, isFalse);
    });

    test('open menu doc: sections parsed, sorted, item prices kept', () {
      final open = cafeteriaMenuFromData(cafeteria, const {
        'cafeteriaId': 'seunghak-student',
        'date': '2026-10-06',
        'status': 'open',
        'sections': [
          {
            'slot': 'allDay',
            'kind': 'alacarte',
            'items': [
              {'name': '돼지국밥', 'price': 6000},
              {'name': '등심돈까스', 'price': 7500},
            ],
          },
          {
            'slot': 'breakfast',
            'kind': 'thousandWon',
            'price': 1000,
            'note': '09:00부터 선착순',
            'items': [
              {'name': '훈제오리솥밥'}
            ],
          },
          {
            'slot': 'allDay',
            'kind': 'set',
            'price': 6000,
            'items': [
              {'name': '뚝배기불고기'},
              {'name': '쌀밥'},
            ],
          },
        ],
      });
      expect(open.status, DiningAvailability.open);
      expect(open.sections.map((s) => (s.slot, s.kind)).toList(), [
        (MealSlot.breakfast, MenuKind.thousandWon),
        (MealSlot.allDay, MenuKind.set),
        (MealSlot.allDay, MenuKind.alacarte),
      ]);
      expect(open.sections[0].price, 1000);
      expect(open.sections[0].note, '09:00부터 선착순');
      expect(open.sections[1].price, 6000);
      expect(open.sections[1].items.map((i) => i.name), ['뚝배기불고기', '쌀밥']);
      expect(open.sections[2].price, isNull);
      expect(open.sections[2].items.map((i) => i.price), [6000, 7500]);

      final closed =
          cafeteriaMenuFromData(cafeteria, const {'status': 'closed'});
      expect(closed.status, DiningAvailability.closed);
      expect(closed.isClosed, isTrue);
      expect(closed.sections, isEmpty);
    });

    test('legacy meals doc (pre-redesign) → set sections', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'status': 'open',
        'meals': [
          {
            'type': 'dinner',
            'items': ['순두부찌개', '쌀밥'],
            'price': 5000,
          },
          {
            'type': 'lunch',
            'items': ['제육볶음', '미역국'],
            'price': 5500,
          },
        ],
      });
      expect(menu.status, DiningAvailability.open);
      expect(menu.sections.map((s) => (s.slot, s.kind, s.price)).toList(), [
        (MealSlot.lunch, MenuKind.set, 5500),
        (MealSlot.dinner, MenuKind.set, 5000),
      ]);
      expect(menu.sections.first.items.map((i) => i.name), ['제육볶음', '미역국']);
    });

    test('a doc with both keys prefers sections over legacy meals', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'status': 'open',
        'sections': [
          {
            'slot': 'lunch',
            'kind': 'set',
            'price': 7000,
            'items': [
              {'name': 'new'}
            ],
          },
        ],
        'meals': [
          {
            'type': 'lunch',
            'items': ['old'],
          },
        ],
      });
      expect(menu.sections.single.items.single.name, 'new');
    });

    test('the static doc cannot smuggle sections/status into the join', () {
      final menu = cafeteriaMenuFromData({
        ...cafeteria,
        'status': 'open',
        'sections': [
          {
            'slot': 'lunch',
            'kind': 'set',
            'items': [
              {'name': 'stale'}
            ]
          }
        ],
      }, null);
      expect(menu.status, DiningAvailability.unpublished);
      expect(menu.sections, isEmpty);
    });

    test('wrong-typed sections/meals throw (repository marks unavailable)',
        () {
      expect(
          () => cafeteriaMenuFromData(
              cafeteria, const {'status': 'open', 'sections': 'broken'}),
          throwsA(anything));
      expect(
          () => cafeteriaMenuFromData(
              cafeteria, const {'status': 'open', 'meals': 'broken'}),
          throwsA(anything));
    });

    test('hours: malformed windows skipped, missing hours → empty', () {
      final menu = cafeteriaMenuFromData({
        ...cafeteria,
        'hours': [
          {'open': '11:40', 'close': '13:30'},
          {'open': '13:30', 'close': '11:40'}, // reversed
          {'open': '11:40', 'close': '1330'}, // bad format
          {'close': '13:30'}, // missing open
          42, // wrong type
        ],
      }, null);
      expect(menu.serviceHours,
          const [ServiceHours(open: '11:40', close: '13:30')]);

      final noHours = cafeteriaMenuFromData({
        'id': 'seunghak-engineering',
        'name_ko': '공과대학 식당',
        'campus': 'seunghak',
        'hours_ko': '운영시간 미표기',
        'order': 3,
      }, null);
      expect(noHours.serviceHours, isEmpty);
      expect(noHours.hoursSummary, isNull);
      expect(noHours.hoursKo, '운영시간 미표기');
      expect(noHours.order, 3);

      // `order` missing falls back to 0; sheet-typed strings are read
      // leniently ("2" → 2) and garbage degrades to 0 instead of dropping
      // the cafeteria from the list.
      final noOrder =
          cafeteriaMenuFromData({'id': 'x', 'campus': 'bumin'}, null);
      expect(noOrder.order, 0);
      expect(
          cafeteriaMenuFromData(
                  {'id': 'x', 'campus': 'bumin', 'order': '2'}, null)
              .order,
          2);
      expect(
          cafeteriaMenuFromData(
                  {'id': 'x', 'campus': 'bumin', 'order': 'two'}, null)
              .order,
          0);
    });
  });

  group('cafeteriaMenuFromDocs (doc wrapper)', () {
    test('injects doc id, normalizes Timestamp, coerces unknown status', () {
      final doc = _FakeDoc('bumin-staff', {
        'name_ko': '부민 교직원 식당',
        'campus': 'bumin',
        'order': 4,
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 1)),
      });
      final menu = cafeteriaMenuFromDocs(doc, const {'status': 'holiday'});
      expect(menu.id, 'bumin-staff');
      expect(menu.campus, Campus.bumin);
      expect(menu.order, 4);
      expect(menu.status, DiningAvailability.unpublished);
    });
  });

  group('mapDocsSkippingMalformed', () {
    const goodFacility = {
      'name_ko': '중앙도서관',
      'name_en': 'Central Library',
      'category': 'library',
      'lat': 35.116,
      'lng': 129.005,
      'campus': 'seunghak',
    };

    test('skips a malformed doc and keeps the rest, order preserved', () {
      final docs = [
        _FakeDoc('s01', goodFacility),
        _FakeDoc('bad', const {'lat': 'oops'}), // lat not a num → throws
        _FakeDoc('s02', goodFacility),
      ];
      final out = mapDocsSkippingMalformed(docs, 'facilities', facilityFromDoc);
      expect([for (final f in out) f.id], ['s01', 's02']);
    });

    test('all docs malformed → empty list, no throw', () {
      final docs = [
        _FakeDoc('a', const {'lat': 'oops'}),
        _FakeDoc('b', null),
      ];
      final out = mapDocsSkippingMalformed(docs, 'facilities', facilityFromDoc);
      expect(out, isEmpty);
    });
  });
}
