import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/entities/admin_guide.dart';
import '../../domain/repositories/guide_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [GuideRepository].
///
/// Week 2 only exercises the search index (S8) and single-item lookup; full
/// sectioned guide content (S5–S7) lands in week 3 on the SAME documents — the
/// schema already reserves those fields (see `03_api_integration.md`). Items may
/// carry `status: comingSoon` while content is a placeholder; the loading path
/// is complete regardless.
class FirestoreGuideRepository implements GuideRepository {
  FirestoreGuideRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.guideItems);

  /// A malformed document is skipped (logged) instead of failing the whole
  /// list — same policy as `FirestoreAcademicCalendarRepository`.
  Future<List<AdminGuideItem>> _loadAll() async {
    try {
      final snap = await _col.get();
      return mapDocsSkippingMalformed(
          orderByCatalogue(
              snap.docs, (d) => (d.data() ?? const {})[guideSortOrderField]),
          FirestorePaths.guideItems,
          guideFromDoc);
    } on FirebaseException catch (e) {
      final cached = await _tryCacheAll();
      if (cached != null) return cached;
      throw DataRepositoryException('Failed to load guide items', e);
    }
  }

  Future<List<AdminGuideItem>?> _tryCacheAll() async {
    try {
      final snap = await _col.get(const GetOptions(source: Source.cache));
      if (snap.docs.isEmpty) return null;
      return mapDocsSkippingMalformed(
          orderByCatalogue(
              snap.docs, (d) => (d.data() ?? const {})[guideSortOrderField]),
          FirestorePaths.guideItems,
          guideFromDoc);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<List<AdminGuideItem>> getAllItems() => _loadAll();

  @override
  Future<List<AdminGuideItem>> getByCategory(GuideCategory category) async {
    // Filter client-side off the (cache-friendly) full load: the dataset is
    // campus-small, and reusing _loadAll keeps the same offline fallback path.
    final all = await _loadAll();
    return orderGuideItems(all.where((g) => g.categoryId == category));
  }

  /// Same policy as the list and as `FirestoreFloorGuideRepository`: a document
  /// that cannot be parsed is logged and treated as missing, so a favourite or a
  /// related link pointing at a hand-edited document opens an empty state
  /// instead of throwing out of the screen (B 03/060 SF-02).
  AdminGuideItem? _tryMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return guideFromDoc(doc);
    } catch (e) {
      debugPrint('${FirestorePaths.guideItems}/${doc.id}: '
          'skipped malformed doc ($e)');
      return null;
    }
  }

  @override
  Future<AdminGuideItem?> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      return doc.exists ? _tryMap(doc) : null;
    } on FirebaseException catch (e) {
      try {
        final cached =
            await _col.doc(id).get(const GetOptions(source: Source.cache));
        if (cached.exists) return _tryMap(cached);
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException('Failed to load guide item "$id"', e);
    }
  }

  @override
  Future<List<AdminGuideItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final all = await _loadAll();
    return List.unmodifiable(searchGuideItems(all, query));
  }
}

/// Seed field holding a guide's position in the curated catalogue
/// (`MockData.guideItems`), written by the seed exporter.
const guideSortOrderField = 'sort_order';

/// Firestore returns documents ordered by id, while the mock data — and so the
/// category lists and search ties the app shows — follow the curated catalogue
/// order. Sorts [docs] by their `sort_order` value; documents without one
/// (uploaded before the field existed) keep their relative order after the
/// ordered ones. Stable, so equal values keep the incoming order.
List<T> orderByCatalogue<T>(Iterable<T> docs, Object? Function(T) sortOrderOf) {
  final indexed = [
    for (final (i, d) in docs.indexed)
      (i, d, switch (sortOrderOf(d)) { final num n => n, _ => null }),
  ];
  indexed.sort((a, b) {
    final (ai, _, ao) = a;
    final (bi, _, bo) = b;
    if (ao != null && bo != null && ao != bo) return ao.compareTo(bo);
    if ((ao == null) != (bo == null)) return ao == null ? 1 : -1;
    return ai.compareTo(bi);
  });
  return [for (final (_, d, _) in indexed) d];
}
