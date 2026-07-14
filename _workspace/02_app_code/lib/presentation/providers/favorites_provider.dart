import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/favorite_ref.dart';
import 'facility_providers.dart';
import 'guide_providers.dart';
import 'repository_providers.dart';

/// Holds the set of favorite keys ("facility:id" / "guide:id") for fast lookup
/// and optimistic toggling. Backed by [FavoritesRepository] (local).
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final all = await ref.watch(favoritesRepositoryProvider).getAll();
    return all.map((e) => e.key).toSet();
  }

  bool contains(FavoriteType type, String id) =>
      state.valueOrNull?.contains('${type.name}:$id') ?? false;

  Future<void> toggle(FavoriteType type, String id) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final key = '${type.name}:$id';
    final current = Set<String>.from(state.valueOrNull ?? const {});
    if (current.contains(key)) {
      current.remove(key);
      state = AsyncData(current);
      await repo.remove(type, id);
    } else {
      current.add(key);
      state = AsyncData(current);
      await repo.add(FavoriteRef(type: type, id: id, savedAt: DateTime.now()));
    }
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

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
