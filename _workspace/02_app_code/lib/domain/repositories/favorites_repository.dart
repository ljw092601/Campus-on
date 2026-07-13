import '../entities/favorite_ref.dart';

/// Contract for local favorites (device-only; no server — UX doc §8).
/// Week 2 ships a SharedPreferences implementation; no api-integrator work
/// needed here (kept in the domain layer for consistency).
abstract interface class FavoritesRepository {
  Future<List<FavoriteRef>> getAll();
  Future<void> add(FavoriteRef ref);
  Future<void> remove(FavoriteType type, String id);
  Future<bool> isFavorite(FavoriteType type, String id);
}
