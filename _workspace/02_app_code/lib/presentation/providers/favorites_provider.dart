import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../domain/repositories/favorites_repository.dart';
import 'facility_providers.dart';
import 'guide_providers.dart';
import 'repository_providers.dart';

/// Holds the set of favorite keys ("facility:id" / "guide:id") for fast lookup
/// and serialized toggling. Backed by [FavoritesRepository] (local).
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repo = ref.watch(favoritesRepositoryProvider);
    final all = await repo.getAll();
    final keys = <String>{};
    final legacy = <FavoriteRef>[];
    for (final e in all) {
      final current = resolveLegacyFavoriteId(e.type, e.id);
      keys.add('${e.type.name}:$current');
      if (current != e.id) legacy.add(e);
    }
    await _migrateLegacy(repo, legacy);
    return keys;
  }

  /// Rewrites renamed ids (M-20, [legacyFavoriteIdMap]) so the migration runs
  /// once. Add before remove: a failed write can only leave the old entry
  /// behind for the next launch, never drop the favorite. Write failures are
  /// swallowed — the mapped keys are still served from memory.
  Future<void> _migrateLegacy(
      FavoritesRepository repo, List<FavoriteRef> legacy) async {
    for (final old in legacy) {
      try {
        await repo.add(FavoriteRef(
          type: old.type,
          id: resolveLegacyFavoriteId(old.type, old.id),
          savedAt: old.savedAt,
        ));
        await repo.remove(old.type, old.id);
      } catch (_) {
        // Memory-only migration; retried on the next load.
      }
    }
  }

  bool contains(FavoriteType type, String id) =>
      state.valueOrNull?.contains('${type.name}:$id') ?? false;

  Future<void> _pending = Future.value();

  Future<bool> toggle(FavoriteType type, String id) {
    final result = _pending.then((_) async {
      try {
        final previous = Set<String>.from(await future);
        final repo = ref.read(favoritesRepositoryProvider);
        final key = '${type.name}:$id';
        if (previous.contains(key)) {
          await repo.remove(type, id);
          previous.remove(key);
        } else {
          await repo
              .add(FavoriteRef(type: type, id: id, savedAt: DateTime.now()));
          previous.add(key);
        }
        // Publish only after persistence succeeds; failed writes keep old state.
        state = AsyncData(previous);
        return true;
      } catch (_) {
        return false;
      }
    });
    _pending = result.then<void>((_) {});
    return result;
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
    FavoritesNotifier.new);

/// Saved facilities for S10 — resolves favorite keys against the facility list.
/// Rebuilds when favorites toggle or the underlying data changes.
final favoriteFacilitiesProvider = Provider<AsyncValue<List<Facility>>>((ref) {
  final keys = ref.watch(favoritesProvider);
  final all = ref.watch(allFacilitiesProvider);
  return keys.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (favKeys) => all.whenData((list) => [
          for (final f in list)
            if (favKeys.contains('${FavoriteType.facility.name}:${f.id}')) f,
        ]),
  );
});

/// Saved guide items for S10.
final favoriteGuideItemsProvider =
    Provider<AsyncValue<List<AdminGuideItem>>>((ref) {
  final keys = ref.watch(favoritesProvider);
  final all = ref.watch(allGuideItemsProvider);
  return keys.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (favKeys) => all.whenData((list) => [
          for (final g in list)
            if (favKeys.contains('${FavoriteType.guide.name}:${g.id}')) g,
        ]),
  );
});
