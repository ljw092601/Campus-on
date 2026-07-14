import '../entities/admin_guide.dart';

/// Contract for admin-guide data access.
///
/// Backs the guide screens S5 (categories) / S6 (item list) / S7 (detail) and
/// the S8 unified search index. The api-integrator provides the Firestore-backed
/// implementation; caching/offline fallback lives in that implementation.
abstract interface class GuideRepository {
  /// All guide items (small dataset) — unified search index + S5 category counts.
  Future<List<AdminGuideItem>> getAllItems();

  /// Items in one category, ordered for S6 (published first, then coming-soon).
  Future<List<AdminGuideItem>> getByCategory(GuideCategory category);

  /// Client-side search over title_ko/title_en (S8).
  Future<List<AdminGuideItem>> search(String query);

  /// Single item by id (S7 detail).
  Future<AdminGuideItem?> getById(String id);
}

/// Shared S6 ordering: published items first, then coming-soon; stable within
/// each group. Kept here so mock & Firestore impls stay consistent.
List<AdminGuideItem> orderGuideItems(Iterable<AdminGuideItem> items) {
  final published = <AdminGuideItem>[];
  final soon = <AdminGuideItem>[];
  for (final g in items) {
    (g.isComingSoon ? soon : published).add(g);
  }
  return [...published, ...soon];
}
