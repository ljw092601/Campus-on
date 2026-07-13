import '../../domain/entities/admin_guide.dart';
import '../../domain/repositories/guide_repository.dart';
import '../mock/mock_data.dart';

/// In-memory guide repository (week 2). Only search-index needs are exercised
/// now; full detail flows land in week 3 on the same interface.
class MockGuideRepository implements GuideRepository {
  MockGuideRepository({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;
  List<AdminGuideItem> get _data => MockData.guideItems;

  @override
  Future<List<AdminGuideItem>> getAllItems() async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(_data);
  }

  @override
  Future<AdminGuideItem?> getById(String id) async {
    await Future<void>.delayed(latency);
    for (final g in _data) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  Future<List<AdminGuideItem>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _data
        .where((g) =>
            g.titleKo.toLowerCase().contains(q) ||
            g.titleEn.toLowerCase().contains(q))
        .toList();
  }
}
