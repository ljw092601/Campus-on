import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Reads salvageable entries independently and keeps exact damaged originals.
/// A completely unreadable payload is never treated as an empty collection.
class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'favorites_v1';
  static const backupKey = 'favorites_v1_corrupt_backups';
  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _pending.then((_) => work());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _checkWrite(Future<bool> Function() write) async {
    try {
      if (!await write()) throw StateError('Favorites storage write failed');
    } catch (_) {
      // SharedPreferences updates its memory cache even if native writes fail.
      try {
        await _prefs.reload();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _backup(String raw) async {
    final backups =
        List<String>.from(_prefs.getStringList(backupKey) ?? const []);
    if (backups.contains(raw)) return;
    backups.add(raw);
    await _checkWrite(() => _prefs.setStringList(backupKey, backups));
  }

  Future<List<FavoriteRef>> _read() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {/* Preserve before reporting. */}
    if (decoded is! List) {
      await _backup(raw);
      throw const FormatException('Unreadable favorites; original preserved');
    }
    final entries = <String, FavoriteRef>{};
    var damaged = false;
    for (final item in decoded) {
      try {
        final ref = FavoriteRef.fromJson((item as Map).cast<String, dynamic>());
        entries.putIfAbsent(ref.key, () => ref);
      } catch (_) {
        damaged = true;
      }
    }
    if (damaged) {
      await _backup(raw);
      if (entries.isEmpty) {
        throw const FormatException(
            'No readable favorites; original preserved');
      }
    }
    return entries.values.toList();
  }

  Future<void> _write(List<FavoriteRef> items) => _checkWrite(() => _prefs
      .setString(_key, jsonEncode(items.map((e) => e.toJson()).toList())));

  @override
  Future<List<FavoriteRef>> getAll() => _serial(_read);
  @override
  Future<void> add(FavoriteRef ref) => _serial(() async {
        final items = await _read();
        if (items.any((e) => e.key == ref.key)) return;
        items.add(ref);
        await _write(items);
      });
  @override
  Future<void> remove(FavoriteType type, String id) => _serial(() async {
        final items = await _read();
        items.removeWhere((e) => e.type == type && e.id == id);
        await _write(items);
      });
  @override
  Future<bool> isFavorite(FavoriteType type, String id) async =>
      (await getAll()).any((e) => e.type == type && e.id == id);
}
