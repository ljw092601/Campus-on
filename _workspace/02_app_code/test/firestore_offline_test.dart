// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_on/data/firestore/firestore_read.dart';
import 'package:campus_on/data/firestore/firestore_facility_repository.dart';
import 'package:campus_on/data/firestore/firestore_guide_repository.dart';
import 'package:campus_on/data/firestore/firestore_dining_repository.dart';
import 'package:campus_on/data/firestore/firestore_academic_calendar_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
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

class _Db extends Fake implements FirebaseFirestore {
  bool offline = false;
  String? errorCode;
  final rows = <String, List<Map<String, dynamic>>>{};
  final reads = <(String, Source)>[];
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
    db.reads.add((path, source));
    if (source == Source.server && (db.offline || db.errorCode != null)) {
      throw FirebaseException(
          plugin: 'cloud_firestore', code: db.errorCode ?? 'unavailable');
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

void main() {
  late _Db db;
  final date = DateTime(2026, 9, 30);
  Map<String, dynamic> cafeteria(String id) =>
      {'id': id, 'name_ko': id, 'name_en': id, 'campus': 'seunghak'};
  setUp(() => db = _Db());

  test(
      'server-empty is authoritative; offline-empty facilities are unavailable',
      () async {
    final repo = FirestoreFacilityRepository(db);
    expect(await repo.getAll(), isEmpty);
    db.offline = true;
    await expectLater(repo.getAll(), throwsA(isA<OfflineDataUnavailable>()));
    expect(db.reads.last.$2, Source.cache);
  });
  test('offline-empty academic events cannot be mistaken for no schedule',
      () async {
    db.offline = true;
    await expectLater(FirestoreAcademicCalendarRepository(db).getEvents(),
        throwsA(isA<OfflineDataUnavailable>()));
  });
  test('offline cached cafeterias with no menus cannot be called unpublished',
      () async {
    db.offline = true;
    db.rows['cafeterias'] = [cafeteria('a')];
    await expectLater(FirestoreDiningRepository(db).getMenus(date),
        throwsA(isA<OfflineDataUnavailable>()));
  });
  test(
      'cached date with partial menus keeps known meals and marks missing menus unavailable',
      () async {
    db.offline = true;
    db.rows['cafeterias'] = [cafeteria('a'), cafeteria('b')];
    db.rows['dining_menus'] = [
      {
        'id': 'a_2026-09-30',
        'cafeteriaId': 'a',
        'date': '2026-09-30',
        'status': 'open',
        'meals': [
          {
            'type': 'lunch',
            'items': ['Rice']
          }
        ],
      }
    ];
    final menus = await FirestoreDiningRepository(db).getMenus(date);
    expect(isCachedRead(menus), isTrue);
    expect(menus.first.meals.single.items, ['Rice']);
    expect(menus.last.status, DiningAvailability.unavailable);
    expect(menus.last.isUnpublished, isFalse);
    expect(menus.last.isClosed, isFalse);
  });
  test('online no menu is unpublished; retry rereads cafeteria info too',
      () async {
    db.rows['cafeterias'] = [cafeteria('a')];
    final repo = FirestoreDiningRepository(db);
    expect((await repo.getMenus(date)).single.isUnpublished, isTrue);
    db.rows['cafeterias'] = [
      {...cafeteria('a'), 'hours_en': 'New hours'}
    ];
    expect((await repo.getMenus(date)).single.hoursEn, 'New hours');
    expect(db.reads.where((r) => r.$1 == 'cafeterias').length, 2);
  });
  test('cached facilities keep read provenance through search and ID filtering',
      () async {
    db.offline = true;
    db.rows['facilities'] = [
      {
        'id': 'a',
        'name_ko': 'Library',
        'name_en': 'Library',
        'buildingCode': 'S12',
        'category': 'building',
        'lat': 35.1,
        'lng': 129.0
      }
    ];
    final repo = FirestoreFacilityRepository(db);
    final found = await repo.search('library');
    expect(found, hasLength(1));
    expect(isCachedRead(found), isTrue);
    expect(isCachedRead(await repo.search('missing')), isTrue);
    expect(isCachedRead(await repo.getByIds(['a'])), isTrue);
    final byCode = await repo.search(' s12 ');
    expect(byCode.single.id, 'a');
    expect(isCachedRead(byCode), isTrue);
    expect((await repo.search('Lib rary')).single.id, 'a');
  });
  test('permission errors never fall back to cached content', () async {
    db.errorCode = 'permission-denied';
    await expectLater(FirestoreFacilityRepository(db).getAll(),
        throwsA(isA<FirebaseException>()));
    expect(db.reads, [('facilities', Source.server)]);
  });
  test('guide server errors propagate rather than becoming an empty search',
      () async {
    db.errorCode = 'permission-denied';
    await expectLater(FirestoreGuideRepository(db).search('visa'),
        throwsA(isA<FirebaseException>()));
  });
  test('server timeout is bounded and uses a marked cached result', () async {
    final pending = Completer<RepositoryList<int>>();
    final result = await readWithCache(
        server: () => pending.future,
        cache: () async => RepositoryList([1]),
        timeout: const Duration(milliseconds: 1));
    expect(result, [1]);
    expect(result.fromCache, isTrue);
    pending.complete(RepositoryList([2]));
    expect(result, [1]);
  });
  test('malformed menu is unavailable instead of unpublished or closed',
      () async {
    db.rows['cafeterias'] = [cafeteria('a')];
    db.rows['dining_menus'] = [
      {
        'id': 'a_date',
        'cafeteriaId': 'a',
        'date': '2026-09-30',
        'status': 'open',
        'meals': 'broken'
      }
    ];
    final menus = await FirestoreDiningRepository(db).getMenus(date);
    expect(menus.single.status, DiningAvailability.unavailable);
    expect(isIncompleteRead(menus), isTrue);
  });
}
