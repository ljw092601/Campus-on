import 'dart:convert';
import 'package:campus_on/data/repositories/local_favorites_repository.dart';
import 'package:campus_on/domain/entities/favorite_ref.dart';
import 'package:campus_on/presentation/providers/favorites_provider.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store(super.data) : super.withData();
  bool fail = false;
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (fail) return false;
    writes++;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FavoriteRef item(String id) =>
      FavoriteRef(type: FavoriteType.facility, id: id, savedAt: DateTime(2026));
  Future<SharedPreferences> prefs(Map<String, Object> data) async {
    SharedPreferences.setMockInitialValues(data);
    return SharedPreferences.getInstance();
  }

  test(
      'partial corruption salvages valid entries and retains exact original on edit',
      () async {
    final raw = jsonEncode([
      item('a').toJson(),
      {'type': 'unknown', 'id': 'b'},
      42
    ]);
    final p = await prefs({'favorites_v1': raw});
    final repo = LocalFavoritesRepository(p);
    expect((await repo.getAll()).map((e) => e.id), ['a']);
    expect(p.getString('favorites_v1'), raw);
    await repo.add(item('c'));
    expect((await repo.getAll()).map((e) => e.id), ['a', 'c']);
    expect(p.getStringList(LocalFavoritesRepository.backupKey), [raw]);
  });
  test('unreadable payload blocks edits without overwriting the original',
      () async {
    for (final raw in ['{broken', '{}', '', '[42]']) {
      final p = await prefs({'favorites_v1': raw});
      final repo = LocalFavoritesRepository(p);
      await expectLater(repo.add(item('b')), throwsFormatException);
      expect(p.getString('favorites_v1'), raw);
      expect(p.getStringList(LocalFavoritesRepository.backupKey), [raw]);
    }
  });
  test('concurrent additions are serialized and neither favorite is lost',
      () async {
    final p = await prefs({});
    final repo = LocalFavoritesRepository(p);
    await Future.wait([repo.add(item('a')), repo.add(item('b'))]);
    expect((await repo.getAll()).map((e) => e.id), ['a', 'b']);
  });
  test(
      'false native write is a failure and does not poison the preferences cache',
      () async {
    SharedPreferences.resetStatic();
    final store = _Store({
      'flutter.favorites_v1': jsonEncode([item('a').toJson()])
    });
    SharedPreferencesStorePlatform.instance = store;
    final p = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(p)]);
    addTearDown(container.dispose);
    await container.read(favoritesProvider.future);
    store.fail = true;
    expect(
        await container
            .read(favoritesProvider.notifier)
            .toggle(FavoriteType.facility, 'b'),
        isFalse);
    expect(container.read(favoritesProvider).requireValue, {'facility:a'});
    expect(jsonDecode(p.getString('favorites_v1')!), hasLength(1));
    store.fail = false;
    expect(
        await container
            .read(favoritesProvider.notifier)
            .toggle(FavoriteType.facility, 'b'),
        isTrue);
    expect(container.read(favoritesProvider).requireValue,
        {'facility:a', 'facility:b'});
  });
  test('backup failure prevents overwriting partially damaged favorites',
      () async {
    SharedPreferences.resetStatic();
    final raw = jsonEncode([item('a').toJson(), 42]);
    final store = _Store({'flutter.favorites_v1': raw})..fail = true;
    SharedPreferencesStorePlatform.instance = store;
    final p = await SharedPreferences.getInstance();
    await expectLater(
        LocalFavoritesRepository(p).add(item('b')), throwsStateError);
    expect(p.getString('favorites_v1'), raw);
  });

  group('legacy id migration (M-20)', () {
    Future<(ProviderContainer, SharedPreferences, _Store)> load(
        List<FavoriteRef> items) async {
      SharedPreferences.resetStatic();
      final store = _Store({
        'flutter.favorites_v1':
            jsonEncode(items.map((e) => e.toJson()).toList())
      });
      SharedPreferencesStorePlatform.instance = store;
      final p = await SharedPreferences.getInstance();
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(p)]);
      addTearDown(container.dispose);
      await container.read(favoritesProvider.future);
      return (container, p, store);
    }

    List<String> storedIds(SharedPreferences p) => [
          for (final e in jsonDecode(p.getString('favorites_v1')!) as List)
            (e as Map)['id'] as String
        ];

    test('p4 alone is served as s12 and the store is rewritten', () async {
      final (container, p, _) = await load([item('p4')]);
      expect(container.read(favoritesProvider).requireValue, {'facility:s12'});
      expect(storedIds(p), ['s12']);
      expect(
          await LocalFavoritesRepository(p)
              .isFavorite(FavoriteType.facility, 'p4'),
          isFalse);
    });
    test('p4 and s12 together collapse to a single s12', () async {
      final (container, p, _) = await load([item('p4'), item('s12')]);
      expect(container.read(favoritesProvider).requireValue, {'facility:s12'});
      expect(storedIds(p), ['s12']);
    });
    test('no legacy ids means no store write', () async {
      final (container, p, store) = await load([item('a'), item('s12')]);
      expect(container.read(favoritesProvider).requireValue,
          {'facility:a', 'facility:s12'});
      expect(store.writes, 0);
      expect(storedIds(p), ['a', 's12']);
    });
    test('unknown ids are kept untouched alongside the migrated one', () async {
      final (container, p, _) = await load([item('zzz'), item('p4')]);
      expect(container.read(favoritesProvider).requireValue,
          {'facility:zzz', 'facility:s12'});
      expect(storedIds(p), ['zzz', 's12']);
    });
    test('failed write keeps the mapped key in memory and the old entry on disk',
        () async {
      SharedPreferences.resetStatic();
      final raw = jsonEncode([item('p4').toJson()]);
      final store = _Store({'flutter.favorites_v1': raw})..fail = true;
      SharedPreferencesStorePlatform.instance = store;
      final p = await SharedPreferences.getInstance();
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(p)]);
      addTearDown(container.dispose);
      expect(await container.read(favoritesProvider.future), {'facility:s12'});
      expect(p.getString('favorites_v1'), raw);
    });
  });
}
