// ignore_for_file: subtype_of_sealed_class

// Audit M-26: every collection `list` the app issues must carry `.limit(n)`
// (firestore.rules rejects a query with no `request.query.limit`), a page
// that fills its limit is reported `incomplete`, and the rules' caps must be
// at least the app-side constants.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_on/data/firestore/firestore_academic_calendar_repository.dart';
import 'package:campus_on/data/firestore/firestore_dining_repository.dart';
import 'package:campus_on/data/firestore/firestore_facility_repository.dart';
import 'package:campus_on/data/firestore/firestore_guide_repository.dart';
import 'package:campus_on/data/firestore/firestore_paths.dart';
import 'package:campus_on/data/firestore/firestore_read.dart';
import 'package:campus_on/domain/repositories/read_result.dart';

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.isFromCache);
  @override
  final bool isFromCache;
}

class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Doc(this.row, this.cached);
  final Map<String, dynamic> row;
  final bool cached;
  @override
  String get id => row['id'] as String;
  @override
  Map<String, dynamic> data() => row;
  @override
  bool get exists => true;
  @override
  SnapshotMetadata get metadata => _Metadata(cached);
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(List<Map<String, dynamic>> rows, bool cached)
      : docs = [for (final row in rows) _Doc(row, cached)],
        metadata = _Metadata(cached);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  final SnapshotMetadata metadata;
}

/// Records, per collection path, the `.limit()` each executed query carried
/// (`null` when `get` ran on a query that never had `.limit()` applied,
/// which is exactly what the rules would reject).
class _Db extends Fake implements FirebaseFirestore {
  bool offline = false;
  final rows = <String, List<Map<String, dynamic>>>{};
  final executedLimits = <String, List<int?>>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Query(this, path);
}

class _Query extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Query(this.db, this.path, [this.date, this.limitCount]);
  final _Db db;
  @override
  final String path;
  final Object? date;
  final int? limitCount;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final source = options?.source ?? Source.serverAndCache;
    db.executedLimits.putIfAbsent(path, () => []).add(limitCount);
    if (source == Source.server && db.offline) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    var rows = (db.rows[path] ?? [])
        .where((r) => date == null || r['date'] == date)
        .toList();
    if (limitCount != null) rows = rows.take(limitCount!).toList();
    return _Snapshot(rows, source == Source.cache);
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) =>
      _Query(db, path, date, limit);

  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #where) {
      return _Query(db, path, i.namedArguments[#isEqualTo], limitCount);
    }
    if (i.memberName == #orderBy) return this;
    return super.noSuchMethod(i);
  }
}

Map<String, dynamic> _facility(int i) => {
      'id': 'f$i',
      'name_ko': 'Facility $i',
      'name_en': 'Facility $i',
      'buildingCode': 'S${i.toString().padLeft(2, '0')}',
      'category': 'building',
      'lat': 35.1,
      'lng': 129.0,
    };

Map<String, dynamic> _cafeteria(String id) =>
    {'id': id, 'name_ko': id, 'name_en': id, 'campus': 'seunghak'};

void main() {
  late _Db db;
  final date = DateTime(2026, 9, 30);
  setUp(() => db = _Db());

  group('every list query carries its collection limit', () {
    test('facilities', () async {
      await FirestoreFacilityRepository(db).getAll();
      expect(db.executedLimits[FirestorePaths.facilities],
          [FirestoreListLimits.facilities]);
    });
    test('guide_items', () async {
      await FirestoreGuideRepository(db).getAllItems();
      expect(db.executedLimits[FirestorePaths.guideItems],
          [FirestoreListLimits.guideItems]);
    });
    test('academic_events (ordered query keeps the limit)', () async {
      await FirestoreAcademicCalendarRepository(db).getEvents();
      expect(db.executedLimits[FirestorePaths.academicEvents],
          [FirestoreListLimits.academicEvents]);
    });
    test('cafeterias + dining_menus (filtered query keeps the limit)',
        () async {
      db.rows[FirestorePaths.cafeterias] = [_cafeteria('a')];
      await FirestoreDiningRepository(db).getMenus(date);
      expect(db.executedLimits[FirestorePaths.cafeterias],
          [FirestoreListLimits.cafeterias]);
      expect(db.executedLimits[FirestorePaths.diningMenus],
          [FirestoreListLimits.diningMenus]);
    });
    test('the cache fallback query is limited too', () async {
      db.offline = true;
      db.rows[FirestorePaths.facilities] = [_facility(1)];
      await FirestoreFacilityRepository(db).getAll();
      // Server attempt, then cache attempt: both limited.
      expect(db.executedLimits[FirestorePaths.facilities],
          [FirestoreListLimits.facilities, FirestoreListLimits.facilities]);
    });
    test('no executed query ever lacks a limit', () async {
      db.rows[FirestorePaths.cafeterias] = [_cafeteria('a')];
      await FirestoreFacilityRepository(db).search('x');
      await FirestoreGuideRepository(db).search('x');
      await FirestoreAcademicCalendarRepository(db).getEvents();
      await FirestoreDiningRepository(db).getMenus(date);
      final limits = db.executedLimits.values.expand((l) => l).toList();
      expect(limits, hasLength(5));
      expect(limits, everyElement(isNotNull));
      expect(limits, everyElement(greaterThan(0)));
    });
  });

  group('a page that fills its limit is reported incomplete', () {
    test('readQuery below the limit is complete', () async {
      final docs = await readQuery(db.collection('facilities'), limit: 3);
      expect(docs.incomplete, isFalse);
      db.rows['facilities'] = [_facility(1), _facility(2)];
      final two = await readQuery(db.collection('facilities'), limit: 3);
      expect(two, hasLength(2));
      expect(two.incomplete, isFalse);
    });
    test('readQuery at the limit is incomplete (server and cache)', () async {
      db.rows['facilities'] = [_facility(1), _facility(2), _facility(3)];
      final full = await readQuery(db.collection('facilities'), limit: 3);
      expect(full, hasLength(3));
      expect(full.incomplete, isTrue);
      expect(full.fromCache, isFalse);
      db.offline = true;
      final cached = await readQuery(db.collection('facilities'), limit: 2);
      expect(cached, hasLength(2));
      expect(cached.fromCache, isTrue);
      expect(cached.incomplete, isTrue);
    });
    test('facility repository surfaces truncation through the read status',
        () async {
      db.rows[FirestorePaths.facilities] = [
        for (var i = 0; i < FirestoreListLimits.facilities + 5; i++)
          _facility(i)
      ];
      final repo = FirestoreFacilityRepository(db);
      final all = await repo.getAll();
      expect(all, hasLength(FirestoreListLimits.facilities));
      expect(isIncompleteRead(all), isTrue);
      // Filtering preserves the truncation flag so the banner still shows.
      expect(isIncompleteRead(await repo.search('facility 1')), isTrue);
      expect(isIncompleteRead(await repo.getByIds(['f1'])), isTrue);
    });
    test('dining menus propagate a truncated cafeteria page', () async {
      db.rows[FirestorePaths.cafeterias] = [
        for (var i = 0; i < FirestoreListLimits.cafeterias + 1; i++)
          _cafeteria('c$i')
      ];
      final menus = await FirestoreDiningRepository(db).getMenus(date);
      expect(menus, hasLength(FirestoreListLimits.cafeterias));
      expect(isIncompleteRead(menus), isTrue);
    });
  });

  group('firestore.rules caps match the app constants', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('no public collection still uses an unbounded `allow read`', () {
      expect(rules.contains('allow read: if true'), isFalse,
          reason: 'public collections must split get/list (M-26)');
    });

    for (final entry in FirestoreListLimits.byCollection.entries) {
      test('${entry.key}: list cap >= ${entry.value}', () {
        final block = RegExp('match /${entry.key}/\\{[A-Za-z]+\\} \\{([^}]*)\\}')
            .firstMatch(rules);
        expect(block, isNotNull, reason: 'missing rule for ${entry.key}');
        final body = block!.group(1)!;
        expect(body, contains('allow get: if true;'));
        final cap =
            RegExp(r'allow list: if boundedList\((\d+)\);').firstMatch(body);
        expect(cap, isNotNull, reason: 'list not bounded for ${entry.key}');
        expect(int.parse(cap!.group(1)!), greaterThanOrEqualTo(entry.value));
        expect(body, isNot(contains('allow write: if true')));
      });
    }

    test('boundedList compares request.query.limit', () {
      expect(rules, contains('return request.query.limit <= max;'));
    });
  });
}
