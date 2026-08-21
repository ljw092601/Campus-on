import '../entities/building_floors.dart';

/// Contract for building floor-guide data access.
///
/// One document per building, keyed by facility id. Loaded lazily when a map
/// pin / facility detail needs it (the floors payload is ~10× the facility
/// list, so it is deliberately NOT part of `FacilityRepository.getAll`).
abstract interface class FloorGuideRepository {
  /// Floors for one building, or null when none exist ("층별 정보 미등록" —
  /// mirrors `Facility.hasFloorInfo == false`).
  Future<BuildingFloors?> getByFacilityId(String facilityId);
}
