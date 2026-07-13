import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/favorite_ref.dart';
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
