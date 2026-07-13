import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/facility.dart';
import '../../domain/repositories/facility_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [FacilityRepository].
///
/// Drop-in replacement for `MockFacilityRepository` — same interface, swapped
/// in `presentation/providers/repository_providers.dart` behind the
/// `USE_FIRESTORE` flag. Screens and providers are untouched.
///
/// Offline: relies on Firestore's built-in local persistence (enabled in
/// `core/config/firebase_init.dart`). A normal `.get()` already serves the last
/// synced snapshot when the device is offline; on top of that, every read has an
/// explicit `Source.cache` fallback so a transient server error still yields the
/// last-successful data instead of an error screen. See `03_api_integration.md`
/// for why a separate Hive/Isar cache was deliberately NOT added.
class FirestoreFacilityRepository implements FacilityRepository {
  FirestoreFacilityRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.facilities);

  /// Loads the whole (campus-scale, small) collection once. `getByIds`/`search`
  /// filter over this in memory — one query, cache-friendly, matches the UX
  /// decision to keep search client-side and minimize Firestore reads.
  Future<List<Facility>> _loadAll() async {
    try {
      final snap = await _col.get();
      return snap.docs.map(facilityFromDoc).toList(growable: false);
    } on FirebaseException catch (e) {
      final cached = await _tryCacheAll();
      if (cached != null) return cached;
      throw DataRepositoryException('Failed to load facilities', e);
    }
  }

  Future<List<Facility>?> _tryCacheAll() async {
    try {
      final snap = await _col.get(const GetOptions(source: Source.cache));
      if (snap.docs.isEmpty) return null;
      return snap.docs.map(facilityFromDoc).toList(growable: false);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<List<Facility>> getAll() => _loadAll();

  @override
  Future<Facility?> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      return doc.exists ? facilityFromDoc(doc) : null;
    } on FirebaseException catch (e) {
      try {
        final cached =
            await _col.doc(id).get(const GetOptions(source: Source.cache));
        if (cached.exists) return facilityFromDoc(cached);
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException('Failed to load facility "$id"', e);
    }
  }

  @override
  Future<List<Facility>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final wanted = ids.toSet();
    final all = await _loadAll();
    return all.where((f) => wanted.contains(f.id)).toList(growable: false);
  }

  @override
  Future<List<Facility>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _loadAll();
    return all
        .where((f) =>
            f.nameKo.toLowerCase().contains(q) ||
            f.nameEn.toLowerCase().contains(q))
        .toList(growable: false);
  }
}
