import '../../domain/entities/facility.dart';
import '../../domain/repositories/facility_repository.dart';
import '../mock/mock_data.dart';

/// In-memory implementation used during week-2 development.
/// api-integrator replaces this with a Firestore-backed class implementing the
/// same [FacilityRepository] interface.
class MockFacilityRepository implements FacilityRepository {
  MockFacilityRepository({this.latency = const Duration(milliseconds: 350)});

  final Duration latency;
  List<Facility> get _data => MockData.facilities;

  @override
  Future<List<Facility>> getAll() async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(_data);
  }

  @override
  Future<Facility?> getById(String id) async {
    await Future<void>.delayed(latency);
    for (final f in _data) {
      if (f.id == id) return f;
    }
    return null;
  }

  @override
  Future<List<Facility>> getByIds(List<String> ids) async {
    await Future<void>.delayed(latency);
    final set = ids.toSet();
    return _data.where((f) => set.contains(f.id)).toList();
  }

  @override
  Future<List<Facility>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _data
        .where((f) =>
            f.nameKo.toLowerCase().contains(q) ||
            f.nameEn.toLowerCase().contains(q))
        .toList();
  }
}
