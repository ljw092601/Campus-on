// ignore_for_file: subtype_of_sealed_class

// Audit Low fixes owned by the data/settings team:
//  - L-23: lenient optional fields in Facility.fromJson; malformed single
//    documents surface as MalformedDocumentException + FirestoreReadLog.
//  - L-27: locale preference write failure is reported, not swallowed.
//  - L-18/L-30/L-31: home screen survives 200% font scale; the language
//    toggle and feature cards expose proper semantics; decorative images are
//    excluded.
//  - L-31: Settings shows the runtime package version.

import 'package:campus_on/data/firestore/firestore_facility_repository.dart';
import 'package:campus_on/data/firestore/firestore_floor_guide_repository.dart';
import 'package:campus_on/data/firestore/firestore_guide_repository.dart';
import 'package:campus_on/data/firestore/repository_exceptions.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/home/home_screen.dart';
import 'package:campus_on/presentation/providers/locale_provider.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/settings/app_version_provider.dart';
import 'package:campus_on/presentation/settings/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

// ---------------------------------------------------------------------------
// Firestore fakes: just enough for `collection(path).doc(id).get()`.
// ---------------------------------------------------------------------------

class _Metadata extends Fake implements SnapshotMetadata {
  @override
  bool get isFromCache => false;
}

class _DocSnap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _DocSnap(this.id, this.row);
  @override
  final String id;
  final Map<String, dynamic>? row;
  @override
  Map<String, dynamic>? data() => row;
  @override
  bool get exists => row != null;
  @override
  SnapshotMetadata get metadata => _Metadata();
}

class _DocRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  _DocRef(this.db, this.colPath, this.id);
  final _Db db;
  final String colPath;
  @override
  final String id;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _DocSnap(id, db.docs['$colPath/$id']);
}

class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Col(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _DocRef(db, path, id!);
}

class _Db extends Fake implements FirebaseFirestore {
  final docs = <String, Map<String, dynamic>?>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Col(this, path);
}

/// SharedPreferences store whose writes can be made to fail.
class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.empty();
  bool fail = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (fail) return false;
    return super.setValue(type, key, value);
  }
}

Future<SharedPreferences> _prefs(_Store store) async {
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesStorePlatform.instance = store;
  return SharedPreferences.getInstance();
}

const _goodFacility = <String, dynamic>{
  'name_ko': '중앙도서관',
  'name_en': 'Central Library',
  'category': 'library',
  'lat': 35.116,
  'lng': 129.005,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L-23 Facility.fromJson', () {
    test('optional fields with the wrong type degrade to null', () {
      final f = Facility.fromJson(const {
        'id': 's01',
        ..._goodFacility,
        'phone': 0519990000, // number instead of string
        'address_ko': {'street': 'x'},
        'address_en': ['a'],
        'hours_ko': 9,
        'hours_en': true,
        'description_ko': 1.5,
        'description_en': null,
        'imageUrl': 42,
        'building_ko': 3,
        'buildingCode': 12,
        'campus': 7,
        'hasFloorInfo': 'yes',
        'updatedAt': 'not-a-date',
      });
      expect(f.id, 's01');
      expect(f.nameEn, 'Central Library');
      expect(f.category, FacilityCategory.library);
      expect(f.lat, 35.116);
      expect(f.phone, isNull);
      expect(f.addressKo, isNull);
      expect(f.addressEn, isNull);
      expect(f.hoursKo, isNull);
      expect(f.hoursEn, isNull);
      expect(f.descriptionKo, isNull);
      expect(f.imageUrl, isNull);
      expect(f.buildingKo, isNull);
      expect(f.buildingCode, isNull);
      expect(f.campus, isNull);
      expect(f.hasFloorInfo, isFalse);
      expect(f.updatedAt, isNull);
    });

    test('well-typed optional fields still round-trip', () {
      final f = Facility.fromJson(const {
        'id': 's01',
        ..._goodFacility,
        'phone': '051-200-0000',
        'campus': 'bumin',
        'hasFloorInfo': true,
        'buildingCode': 'B04',
      });
      expect(f.phone, '051-200-0000');
      expect(f.campus, Campus.bumin);
      expect(f.hasFloorInfo, isTrue);
      expect(f.buildingCode, 'B04');
    });

    test('required fields remain strict', () {
      expect(
          () => Facility.fromJson(
              {'id': 'x', ..._goodFacility}..['lat'] = 'oops'),
          throwsA(isA<TypeError>()));
      expect(
          () => Facility.fromJson({'id': 'x', ..._goodFacility}..remove('lng')),
          throwsA(isA<TypeError>()));
      expect(() => Facility.fromJson(const {'id': 7, ..._goodFacility}),
          throwsA(isA<TypeError>()));
      expect(
          () => Facility.fromJson(
              {'id': 'x', ..._goodFacility}..['name_ko'] = 1),
          throwsA(isA<TypeError>()));
    });
  });

  group('L-23 single-document reads isolate malformed docs', () {
    late _Db db;
    setUp(() {
      db = _Db();
      FirestoreReadLog.clear();
    });

    test('facility: parse failure is a MalformedDocumentException + log entry',
        () async {
      db.docs['facilities/bad'] = {..._goodFacility, 'lat': 'oops'};
      await expectLater(
        FirestoreFacilityRepository(db).getById('bad'),
        throwsA(isA<MalformedDocumentException>()
            .having((e) => e.path, 'path', 'facilities/bad')
            .having((e) => e.cause, 'cause', isA<TypeError>())),
      );
      expect(FirestoreReadLog.records, hasLength(1));
      expect(FirestoreReadLog.records.single.path, 'facilities/bad');
      expect(FirestoreReadLog.records.single.error, isA<TypeError>());
    });

    test('facility: the typed exception is still a DataRepositoryException',
        () async {
      db.docs['facilities/bad'] = {..._goodFacility, 'lat': 'oops'};
      await expectLater(FirestoreFacilityRepository(db).getById('bad'),
          throwsA(isA<DataRepositoryException>()));
    });

    test('facility: a good doc parses; a missing doc is null, not an error',
        () async {
      db.docs['facilities/s01'] = {..._goodFacility, 'phone': 123};
      final repo = FirestoreFacilityRepository(db);
      final f = await repo.getById('s01');
      expect(f?.id, 's01');
      expect(f?.phone, isNull);
      expect(await repo.getById('nope'), isNull);
      expect(FirestoreReadLog.records, isEmpty);
    });

    test('guide: parse failure names guide_items/<id>', () async {
      db.docs['guide_items/bad'] = {'title_ko': 5};
      await expectLater(
        FirestoreGuideRepository(db).getById('bad'),
        throwsA(isA<MalformedDocumentException>()
            .having((e) => e.path, 'path', 'guide_items/bad')),
      );
      expect(FirestoreReadLog.records.single.path, 'guide_items/bad');
    });

    test('floor guide: parse failure names building_floors/<id>', () async {
      db.docs['building_floors/bad'] = {'floors': 'nope'};
      await expectLater(
        FirestoreFloorGuideRepository(db).getByFacilityId('bad'),
        throwsA(isA<MalformedDocumentException>()
            .having((e) => e.path, 'path', 'building_floors/bad')),
      );
      expect(FirestoreReadLog.records.single.path, 'building_floors/bad');
      expect(
          await FirestoreFloorGuideRepository(db).getByFacilityId('none'), isNull);
    });

    test('read log is bounded', () {
      for (var i = 0; i < FirestoreReadLog.capacity + 5; i++) {
        FirestoreReadLog.record('c', 'd$i', 'e');
      }
      expect(FirestoreReadLog.records, hasLength(FirestoreReadLog.capacity));
      expect(FirestoreReadLog.records.first.docId, 'd5');
      expect(FirestoreReadLog.records.last.docId,
          'd${FirestoreReadLog.capacity + 4}');
    });
  });

  group('L-27 locale preference write result', () {
    test('a failed write keeps the in-memory locale and returns false',
        () async {
      final store = _Store();
      final prefs = await _prefs(store);
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      final before = container.read(localeProvider);
      store.fail = true;
      expect(await container.read(localeProvider.notifier).toggle(), isFalse);
      final after = container.read(localeProvider);
      expect(after.languageCode, isNot(before.languageCode));
      // Nothing persisted: the cache was reloaded from the store.
      expect(prefs.getString('app_locale'), isNull);
    });

    test('a successful write returns true and persists', () async {
      final store = _Store();
      final prefs = await _prefs(store);
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      expect(await notifier.setLocale(const Locale('ko')), isTrue);
      expect(await notifier.setLocale(const Locale('en')), isTrue);
      expect(prefs.getString('app_locale'), 'en');
      // Setting the current locale again is a no-op success.
      expect(await notifier.setLocale(const Locale('en')), isTrue);
    });
  });

  group('home screen (L-18 / L-30 / L-31 / L-34)', () {
    Future<_Store> pumpHome(WidgetTester tester, {double scale = 1.0}) async {
      final store = _Store();
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      SharedPreferencesStorePlatform.instance = store;
      await store.setValue('String', 'flutter.app_locale', 'en');
      final prefs = await SharedPreferences.getInstance();
      // A narrow phone: the tightest layout the design targets.
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          // The app binds MaterialApp.locale to localeProvider; mirror that so
          // a toggle re-localizes the screen under test too.
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: ref.watch(localeProvider),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      return store;
    }

    testWidgets('renders without overflow at 100% and 200% font scale',
        (tester) async {
      await pumpHome(tester);
      expect(tester.takeException(), isNull);
      await pumpHome(tester, scale: 2.0);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Calendar'), findsOneWidget);
    });

    testWidgets('language toggle exposes label, value and toggled state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      final toggle = find.bySemanticsLabel('Switch language');
      expect(toggle, findsOneWidget);
      expect(
        tester.getSemantics(toggle),
        isSemantics(
          label: 'Switch language',
          value: 'English',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      // The raw "KO | EN" glyphs are not announced separately.
      expect(find.bySemanticsLabel(RegExp('KO')), findsNothing);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('언어 전환')),
        isSemantics(value: '한국어', isToggled: false),
      );
      handle.dispose();
    });

    testWidgets('a failed locale write shows a notice but still switches',
        (tester) async {
      final store = await pumpHome(tester);
      store.fail = true;
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      // Now in Korean (in memory) with the Korean warning text.
      expect(find.textContaining('언어 설정을 저장하지 못했어요'), findsOneWidget);
    });

    testWidgets('feature cards are buttons labeled with their title',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      for (final title in ['Calendar', 'Campus map', "Today's menu"]) {
        final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(title)}'));
        expect(card, findsOneWidget, reason: title);
        expect(tester.getSemantics(card),
            isSemantics(isButton: true, hasTapAction: true));
      }
      // The hero tile announces its title exactly once.
      expect(tester.getSemantics(find.bySemanticsLabel('Classroom search')),
          isSemantics(label: 'Classroom search', isButton: true));
      handle.dispose();
    });

    testWidgets('decorative images are excluded from semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      final images = find.byType(Image);
      // Emblem, hero photo and the four card illustrations.
      expect(images, findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        // An excluded image has no node of its own, so the nearest node is an
        // ancestor (card button / app bar) and never carries the image flag.
        final node = tester.getSemantics(images.at(i));
        expect(node.flagsCollection.isImage, isFalse, reason: 'image #$i');
      }
      handle.dispose();
    });
  });

  group('settings (L-27 / L-31)', () {
    Future<_Store> pumpSettings(WidgetTester tester) async {
      final store = _Store();
      final prefs = await _prefs(store);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appVersionProvider.overrideWith((_) async => PackageInfo(
                  appName: 'Dong-A Mate',
                  packageName: 'kr.ac.donga.campus_on',
                  version: '9.8.7',
                  buildNumber: '42',
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: ref.watch(localeProvider),
              home: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('shows the runtime package version, not an ARB constant',
        (tester) async {
      await pumpSettings(tester);
      // The version row is the last tile; the lazy ListView builds it on
      // scroll.
      await tester.scrollUntilVisible(find.text('9.8.7 (42)'), 200,
          scrollable: find.byType(Scrollable));
      expect(find.text('9.8.7 (42)'), findsOneWidget);
      expect(find.textContaining('MVP'), findsNothing);
    });

    testWidgets('a failed language write shows the save-failed notice',
        (tester) async {
      final store = await pumpSettings(tester);
      store.fail = true;
      await tester.tap(find.text('한국어'));
      await tester.pumpAndSettle();
      expect(find.textContaining('언어 설정을 저장하지 못했어요'), findsOneWidget);
    });
  });
}
