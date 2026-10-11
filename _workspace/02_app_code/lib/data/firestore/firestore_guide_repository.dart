import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/admin_guide.dart';
import '../../domain/repositories/guide_repository.dart';
import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreGuideRepository implements GuideRepository {
  FirestoreGuideRepository(this._db);
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.guideItems);

  /// Limited, cache-aware read (audit M-26); a malformed document is skipped,
  /// logged in `FirestoreReadLog` and the list marked incomplete. Documents
  /// are put in curated catalogue order (`sort_order`) before mapping, so the
  /// category lists and search ties match the mock data.
  Future<List<AdminGuideItem>> _loadAll() async {
    final docs = await readQuery(_col, limit: FirestoreListLimits.guideItems);
    final ordered = RepositoryList(
        orderByCatalogue(
            docs, (d) => d.data()[guideSortOrderField]),
        fromCache: docs.fromCache,
        incomplete: docs.incomplete);
    return mapReadDocuments(ordered, guideFromDoc,
        collection: FirestorePaths.guideItems);
  }

  @override
  Future<List<AdminGuideItem>> getAllItems() => _loadAll();

  @override
  Future<AdminGuideItem?> getById(String id) async {
    final doc = await readDocument(_col.doc(id));
    return mapSingleDocument(doc, FirestorePaths.guideItems, guideFromDoc);
  }

  @override
  Future<List<AdminGuideItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final all = await _loadAll();
    // Titles, aliases and every translated form (incl. folded Vietnamese).
    return preserveReadStatus(all, searchGuideItems(all, query));
  }

  @override
  Future<List<AdminGuideItem>> getByCategory(GuideCategory category) async {
    final all = await _loadAll();
    return preserveReadStatus(
        all, orderGuideItems(all.where((g) => g.categoryId == category)));
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
