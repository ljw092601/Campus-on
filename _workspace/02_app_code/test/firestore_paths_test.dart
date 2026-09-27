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
    const cafeteria = {
      'id': 'seunghak-student',
      'name_ko': '승학캠퍼스 학생식당',
      'name_en': 'Seunghak Student Cafeteria',
      'campus': 'seunghak',
    };

    test('no menu doc for the day → unpublished with no meals', () {
      final menu = cafeteriaMenuFromData(cafeteria, null);
      expect(menu.id, 'seunghak-student');
      expect(menu.status, DiningAvailability.unpublished);
      expect(menu.meals, isEmpty);
      expect(menu.isClosed, isFalse);
    });

    test('menu doc missing status → unpublished, never open', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'cafeteriaId': 'seunghak-student',
        'date': '2026-09-10',
        // no 'status', no 'meals'
      });
      expect(menu.status, DiningAvailability.unpublished);
      // Regression guard: the old `?? 'open'` fallback announced "open" here,
      // and empty meals would otherwise legacy-fall to "closed".
      expect(menu.isClosed, isFalse);
    });

    test('menu doc with typo status → unpublished, not closed (D1)', () {
      final menu = cafeteriaMenuFromData(cafeteria, const {
        'status': 'opne', // admin typo
        'meals': [],
      });
      expect(menu.status, DiningAvailability.unpublished);
      expect(menu.isClosed, isFalse);
    });

    test('valid open menu doc parses meals; explicit closed stays closed', () {
      final open = cafeteriaMenuFromData(cafeteria, const {
        'status': 'open',
        'meals': [
          {
            'type': 'lunch',
            'items': ['제육볶음', '미역국'],
            'price': 5500,
          },
        ],
      });
      expect(open.status, DiningAvailability.open);
      expect(open.meals, hasLength(1));
      expect(open.meals.first.type, MealType.lunch);
      expect(open.meals.first.items, ['제육볶음', '미역국']);

      final closed =
          cafeteriaMenuFromData(cafeteria, const {'status': 'closed'});
      expect(closed.status, DiningAvailability.closed);
      expect(closed.isClosed, isTrue);
    });
  });

  group('cafeteriaMenuFromDocs (doc wrapper)', () {
    test('injects doc id, normalizes Timestamp, coerces unknown status', () {
      final doc = _FakeDoc('bumin-student', {
        'name_ko': '부민캠퍼스 학생식당',
        'campus': 'bumin',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 1)),
      });
      final menu = cafeteriaMenuFromDocs(doc, const {'status': 'holiday'});
      expect(menu.id, 'bumin-student');
      expect(menu.campus, Campus.bumin);
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
