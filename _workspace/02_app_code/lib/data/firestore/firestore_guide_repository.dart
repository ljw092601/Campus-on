import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<List<AdminGuideItem>> _loadAll() async {
    try {
      final snap = await _col.get();
      return snap.docs.map(guideFromDoc).toList(growable: false);
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
      return snap.docs.map(guideFromDoc).toList(growable: false);
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

  @override
  Future<AdminGuideItem?> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      return doc.exists ? guideFromDoc(doc) : null;
    } on FirebaseException catch (e) {
      try {
        final cached =
            await _col.doc(id).get(const GetOptions(source: Source.cache));
        if (cached.exists) return guideFromDoc(cached);
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException('Failed to load guide item "$id"', e);
    }
  }

  @override
  Future<List<AdminGuideItem>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _loadAll();
    return all
        .where((g) =>
            g.titleKo.toLowerCase().contains(q) ||
            g.titleEn.toLowerCase().contains(q))
        .toList(growable: false);
  }
}
