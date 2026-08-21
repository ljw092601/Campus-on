import '../../domain/entities/building_floors.dart';
import '../../domain/repositories/floor_guide_repository.dart';
import '../mock/mock_data.dart';

/// In-memory [FloorGuideRepository] over the generated building data —
/// the default (offline) data source, same pattern as the other mock repos.
class MockFloorGuideRepository implements FloorGuideRepository {
  MockFloorGuideRepository({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;

  @override
  Future<BuildingFloors?> getByFacilityId(String facilityId) async {
    await Future<void>.delayed(latency);
    for (final b in MockData.buildingFloors) {
      if (b.facilityId == facilityId) return b;
    }
    return null;
  }
}
