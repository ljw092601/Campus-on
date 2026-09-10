import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../domain/repositories/dining_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [DiningRepository].
///
/// Two collections (design doc _workspace/06_admin_data_pipeline.md §7):
/// static `cafeterias` (cached in-memory for the repository's lifetime —
/// it changes rarely and re-fetching per day switch is wasted reads) and
/// per-day `dining_menus` queried by `date == yyyy-MM-dd` (single equality,
/// no composite index needed). A cafeteria with no menu doc that day is
/// returned as [DiningAvailability.unpublished] — NOT closed — so an admin's
/// missing input is never announced as a closure (D1).
class FirestoreDiningRepository implements DiningRepository {
  FirestoreDiningRepository(this._db);

  final FirebaseFirestore _db;

  /// Session cache for the static cafeteria list. Invalidated on failure so
  /// a transient error doesn't pin an empty list.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>>? _cafeteriasFuture;

  static const _campusOrder = {
    Campus.seunghak: 0,
    Campus.gudeok: 1,
    Campus.bumin: 2,
  };

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _cafeterias() {
    return _cafeteriasFuture ??= _loadCafeterias().catchError((Object e) {
      _cafeteriasFuture = null; // retry next call instead of caching failure
      throw e;
    });
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
      _loadCafeterias() async {
    final col = _db.collection(FirestorePaths.cafeterias);
    try {
      final snap = await col.get();
      return snap.docs;
    } on FirebaseException catch (e) {
      try {
        final cached = await col.get(const GetOptions(source: Source.cache));
        if (cached.docs.isNotEmpty) return cached.docs;
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException('Failed to load cafeterias', e);
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _menusFor(String date) async {
    final query = _db
        .collection(FirestorePaths.diningMenus)
        .where('date', isEqualTo: date);
    try {
      return await query.get();
    } on FirebaseException catch (e) {
      try {
        // An empty cache result is indistinguishable from "nothing published
        // for this date", and both render as `unpublished` — safe to return.
        return await query.get(const GetOptions(source: Source.cache));
      } on FirebaseException {
        throw DataRepositoryException('Failed to load menus for $date', e);
      }
    }
  }

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    final ymd = _ymd(date);
    final cafeterias = await _cafeterias();
    final menuSnap = await _menusFor(ymd);

    final menuByCafeteria = <String, Map<String, dynamic>>{
      for (final doc in menuSnap.docs)
        if (doc.data()['cafeteriaId'] is String)
          doc.data()['cafeteriaId'] as String: doc.data(),
    };

    final menus = [
      for (final doc in cafeterias)
        cafeteriaMenuFromDocs(doc, menuByCafeteria[doc.id]),
    ];
    menus.sort((a, b) {
      final ca = _campusOrder[a.campus] ?? 9;
      final cb = _campusOrder[b.campus] ?? 9;
      if (ca != cb) return ca - cb;
      return a.id.compareTo(b.id);
    });
    return menus;
  }
}
