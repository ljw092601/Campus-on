import '../entities/admin_guide.dart';

/// Contract for admin-guide data access.
///
/// Week 2 only needs enough for the S8 unified search index. Full category/item/
/// detail methods (S5–S7) are added in week 3. The api-integrator provides the
/// Firestore-backed implementation.
abstract interface class GuideRepository {
  /// All guide items (small dataset) — used by the unified search index.
  Future<List<AdminGuideItem>> getAllItems();

  /// Client-side search over title_ko/title_en (S8).
  Future<List<AdminGuideItem>> search(String query);

  /// Single item by id (week-3 detail; declared now for the contract).
  Future<AdminGuideItem?> getById(String id);
}
