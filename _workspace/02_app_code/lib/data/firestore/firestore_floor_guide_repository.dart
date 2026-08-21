import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/building_floors.dart';
import '../../domain/repositories/floor_guide_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [FloorGuideRepository]. Single-doc reads with the same
/// `Source.cache` fallback policy as the other Firestore repositories, so a
/// once-viewed building's floors stay available offline.
class FirestoreFloorGuideRepository implements FloorGuideRepository {
  FirestoreFloorGuideRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.buildingFloors);

  @override
  Future<BuildingFloors?> getByFacilityId(String facilityId) async {
    try {
      final doc = await _col.doc(facilityId).get();
      return doc.exists ? buildingFloorsFromDoc(doc) : null;
    } on FirebaseException catch (e) {
      try {
        final cached = await _col
            .doc(facilityId)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists) return buildingFloorsFromDoc(cached);
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException(
          'Failed to load floors for "$facilityId"', e);
    }
  }
}
