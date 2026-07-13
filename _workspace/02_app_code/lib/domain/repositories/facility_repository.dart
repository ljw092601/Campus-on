import '../entities/facility.dart';

/// Contract for facility data access.
///
/// Week 2 ships an in-memory mock ([MockFacilityRepository]). The
/// api-integrator swaps in a Firestore-backed implementation of THIS interface
/// (the swap point is the provider in `presentation/providers/repository_providers.dart`).
/// Screens depend only on this interface, never on the concrete class.
abstract interface class FacilityRepository {
  /// All campus facilities (campus-scale = small; load-all + client filter).
  /// Throws on failure so the presentation layer can render the Error state.
  Future<List<Facility>> getAll();

  /// Single facility by id. Returns null if not found.
  Future<Facility?> getById(String id);

  /// Facilities whose id is in [ids] (used by the map deep-link fitBounds).
  Future<List<Facility>> getByIds(List<String> ids);

  /// Client-side search over name_ko/name_en (S8). Case-insensitive contains.
  Future<List<Facility>> search(String query);
}
