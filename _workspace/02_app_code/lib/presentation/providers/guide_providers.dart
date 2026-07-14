import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_guide.dart';
import 'repository_providers.dart';

/// All guide items (small dataset) — backs S5 category counts + the search index.
final allGuideItemsProvider = FutureProvider<List<AdminGuideItem>>((ref) {
  return ref.watch(guideRepositoryProvider).getAllItems();
});

/// Per-category item counts for the S5 badges (derived from the single load
/// above so it shares the offline cache). Failure → provider errors and the
/// screen simply hides the badges.
final guideCategoryCountsProvider =
    FutureProvider<Map<GuideCategory, int>>((ref) async {
  final items = await ref.watch(allGuideItemsProvider.future);
  final counts = <GuideCategory, int>{};
  for (final g in items) {
    counts[g.categoryId] = (counts[g.categoryId] ?? 0) + 1;
  }
  return counts;
});

/// Items in one category, ordered for S6 (published first). `.family` on category.
final guideItemsByCategoryProvider =
    FutureProvider.family<List<AdminGuideItem>, GuideCategory>((ref, category) {
  return ref.watch(guideRepositoryProvider).getByCategory(category);
});

/// Single guide item for S7 detail. `.family` on id.
final guideByIdProvider =
    FutureProvider.family<AdminGuideItem?, String>((ref, id) {
  return ref.watch(guideRepositoryProvider).getById(id);
});
