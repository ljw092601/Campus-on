// M-25: `.family` providers are autoDispose. Network-backed ones keep their
// value for a TTL (ProviderCache.cacheFor); bundle-derived ones are plain
// autoDispose and go away as soon as nobody watches them.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/repositories/dining_repository.dart';
import 'package:campus_on/presentation/providers/classroom_providers.dart';
import 'package:campus_on/presentation/providers/dining_providers.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';
import 'package:campus_on/presentation/providers/guide_providers.dart';
import 'package:campus_on/presentation/providers/provider_cache.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';

/// Counts repository hits so a cache hit vs. a refetch is observable.
class _CountingDiningRepository implements DiningRepository {
  int calls = 0;

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    calls++;
    return const [];
  }
}

/// Lets the Riverpod scheduler run its pending dispose pass.
Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  // floorplans.json is read from the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  const shortTtl = Duration(milliseconds: 60);
  final day = diningDateKey(DateTime(2026, 9, 1));

  group('network family providers: autoDispose + TTL', () {
    late _CountingDiningRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _CountingDiningRepository();
      container = ProviderContainer(overrides: [
        diningRepositoryProvider.overrideWithValue(repo),
        providerCacheTtlProvider.overrideWithValue(shortTtl),
      ]);
      addTearDown(container.dispose);
    });

    test('before the TTL the same instance is reused (no refetch)', () async {
      final first = await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 1);

      // No listener was ever attached: the dispose pass must be a no-op while
      // the keep-alive link is open.
      await pump();
      expect(container.exists(diningMenusProvider(day)), isTrue);

      final again = await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 1, reason: 'cached value must be served');
      expect(identical(first, again), isTrue);
      expect(container.read(diningMenusProvider(day)).value, same(first));
    });

    test('after the TTL the provider is rebuilt (refetch)', () async {
      await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 1);

      await Future<void>.delayed(shortTtl * 3);
      expect(container.exists(diningMenusProvider(day)), isFalse,
          reason: 'TTL elapsed with no listener -> disposed');

      await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 2);
    });

    test('a watcher past the TTL holds the value; leaving then disposes',
        () async {
      final sub = container.listen(diningMenusProvider(day), (_, __) {});
      await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 1);

      await Future<void>.delayed(shortTtl * 3);
      expect(container.exists(diningMenusProvider(day)), isTrue,
          reason: 'still watched -> kept despite the TTL');
      expect(repo.calls, 1);

      sub.close();
      await pump();
      expect(container.exists(diningMenusProvider(day)), isFalse,
          reason: 'TTL already spent -> disposed once unwatched');
    });

    test('each date key is cached independently and all expire', () async {
      final other = diningDateKey(DateTime(2026, 9, 2));
      await container.read(diningMenusProvider(day).future);
      await container.read(diningMenusProvider(other).future);
      expect(repo.calls, 2);

      await Future<void>.delayed(shortTtl * 3);
      expect(container.exists(diningMenusProvider(day)), isFalse);
      expect(container.exists(diningMenusProvider(other)), isFalse);
    });

    test('invalidate refetches and restarts the TTL', () async {
      await container.read(diningMenusProvider(day).future);
      container.invalidate(diningMenusProvider(day));
      await container.read(diningMenusProvider(day).future);
      expect(repo.calls, 2);

      await pump();
      expect(container.exists(diningMenusProvider(day)), isTrue);
    });

    test('TTL of zero disables the cache (plain autoDispose, no timer)',
        () async {
      final c = ProviderContainer(overrides: [
        diningRepositoryProvider.overrideWithValue(repo),
        providerCacheTtlProvider.overrideWithValue(Duration.zero),
      ]);
      addTearDown(c.dispose);

      await c.read(diningMenusProvider(day).future);
      await pump();
      expect(c.exists(diningMenusProvider(day)), isFalse);
    });

    test('other network families use the same TTL cache', () async {
      // Mock repositories (flags off) back these and simulate up to 350ms of
      // latency, so this test gets a TTL comfortably above that. Only the
      // lifecycle is asserted.
      const ttl = Duration(milliseconds: 700);
      final c = ProviderContainer(
          overrides: [providerCacheTtlProvider.overrideWithValue(ttl)]);
      addTearDown(c.dispose);

      final facility = facilityByIdProvider('s04');
      final floors = buildingFloorsProvider('s04');
      final guides = guideItemsByCategoryProvider(GuideCategory.values.first);
      final guide = guideByIdProvider('no-such-id');

      await Future.wait<Object?>([
        c.read(facility.future),
        c.read(floors.future),
        c.read(guides.future),
        c.read(guide.future),
      ]);
      await pump();
      for (final p in [facility, floors, guides, guide]) {
        expect(c.exists(p), isTrue, reason: '$p kept within TTL');
      }

      await Future<void>.delayed(ttl * 2);
      for (final p in [facility, floors, guides, guide]) {
        expect(c.exists(p), isFalse, reason: '$p disposed after TTL');
      }
    });
  });

  group('bundle-derived family providers: plain autoDispose', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('disposed as soon as the last listener goes away', () async {
      final plans = buildingFloorPlansProvider('S04');
      final lookup = roomLookupProvider(('S04', '0306-1'));
      final location = roomLocationProvider(('S04', '0306-1'));
      final entries = classroomEntriesProvider(('s04', 'S04'));

      final subs = [
        container.listen(plans, (_, __) {}),
        container.listen(lookup, (_, __) {}),
        container.listen(location, (_, __) {}),
        container.listen(entries, (_, __) {}),
      ];
      expect((await container.read(location.future))?.plan.floorLabel, '3F');
      expect(await container.read(entries.future), isNotEmpty);
      await pump();
      for (final p in [plans, lookup, location, entries]) {
        expect(container.exists(p), isTrue, reason: '$p alive while watched');
      }

      for (final s in subs) {
        s.close();
      }
      await pump();
      for (final p in [plans, lookup, location, entries]) {
        expect(container.exists(p), isFalse, reason: '$p disposed');
      }
      // The one-time bundle load itself stays cached.
      expect(container.exists(floorPlansProvider), isTrue);
    });

    test('read without a listener still resolves and does not linger',
        () async {
      // classroom_search_screen does `ref.read(roomLookupProvider(..).future)`.
      final lookup = roomLookupProvider(('S04', '0306-1'));
      final result = await container.read(lookup.future);
      expect(result.status, RoomLookupStatus.found);

      await pump();
      expect(container.exists(lookup), isFalse);
      expect(container.exists(floorPlansProvider), isTrue);
    });
  });
}
