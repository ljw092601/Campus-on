import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/building_floors.dart';
import '../../domain/entities/facility.dart';
import 'repository_providers.dart';

/// All facilities (S2/S3 load-all + client filter strategy).
final allFacilitiesProvider = FutureProvider<List<Facility>>((ref) {
  return ref.watch(facilityRepositoryProvider).getAll();
});

/// Single facility for S4. `.family` on id.
final facilityByIdProvider =
    FutureProvider.family<Facility?, String>((ref, id) {
  return ref.watch(facilityRepositoryProvider).getById(id);
});

/// Currently selected category filter (null = All). Shared by S2 & S3.
final facilityCategoryFilterProvider =
    StateProvider<FacilityCategory?>((ref) => null);

/// Facilities after applying the category filter. Rebuilds when the underlying
/// list or the filter changes.
final filteredFacilitiesProvider = Provider<AsyncValue<List<Facility>>>((ref) {
  final async = ref.watch(allFacilitiesProvider);
  final filter = ref.watch(facilityCategoryFilterProvider);
  return async.whenData((list) {
    if (filter == null) return list;
    return list.where((f) => f.category == filter).toList();
  });
});

/// Which campus the map (S2) is showing. Map-only — the list (S3) and search
/// keep showing every campus. The three campuses are km apart, so the map
/// renders one at a time (plan §9-2⑤).
final mapCampusProvider = StateProvider<Campus>((ref) => Campus.seunghak);

/// Map markers: category filter ∩ selected campus. Facilities without a campus
/// (legacy data) stay visible on every campus rather than vanishing.
final mapFacilitiesProvider = Provider<AsyncValue<List<Facility>>>((ref) {
  final async = ref.watch(filteredFacilitiesProvider);
  final campus = ref.watch(mapCampusProvider);
  return async.whenData((list) =>
      list.where((f) => f.campus == null || f.campus == campus).toList());
});

/// Floor guide for one building (pin tap / S4 detail). `.family` on facility
/// id; null = the building has no registered floor info.
final buildingFloorsProvider =
    FutureProvider.family<BuildingFloors?, String>((ref, facilityId) {
  return ref.watch(floorGuideRepositoryProvider).getByFacilityId(facilityId);
});
