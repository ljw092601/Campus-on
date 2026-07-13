import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/favorite_ref.dart';
import '../../domain/repositories/favorites_repository.dart';

/// SharedPreferences-backed favorites (device-only, fully offline).
class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'favorites_v1';

  List<FavoriteRef> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FavoriteRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<FavoriteRef> items) async {
    await _prefs.setString(
        _key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<FavoriteRef>> getAll() async => _read();

  @override
  Future<void> add(FavoriteRef ref) async {
    final items = _read();
    if (items.any((e) => e.key == ref.key)) return;
    items.add(ref);
    await _write(items);
  }

  @override
  Future<void> remove(FavoriteType type, String id) async {
    final items = _read()
      ..removeWhere((e) => e.type == type && e.id == id);
    await _write(items);
  }

  @override
  Future<bool> isFavorite(FavoriteType type, String id) async =>
      _read().any((e) => e.type == type && e.id == id);
}
