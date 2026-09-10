import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/entities/building_floors.dart';
import '../../domain/repositories/floor_guide_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [FloorGuideRepository]. Single-doc reads with the same
/// `Source.cache` fallback policy as the other Firestore repositories, so a
/// once-viewed building's floors stay available offline. A malformed document
/// is treated as "no floor guide" (logged, returns null) instead of an error
/// screen — same skip policy as `FirestoreAcademicCalendarRepository`, applied
/// to a single-doc read.
class FirestoreFloorGuideRepository implements FloorGuideRepository {
  FirestoreFloorGuideRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.buildingFloors);

  BuildingFloors? _tryMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return buildingFloorsFromDoc(doc);
    } catch (e) {
      debugPrint(
          '${FirestorePaths.buildingFloors}/${doc.id}: '
          'skipped malformed doc ($e)');
      return null;
    }
  }

  @override
  Future<BuildingFloors?> getByFacilityId(String facilityId) async {
    try {
      final doc = await _col.doc(facilityId).get();
      return doc.exists ? _tryMap(doc) : null;
    } on FirebaseException catch (e) {
      try {
        final cached = await _col
            .doc(facilityId)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists) return _tryMap(cached);
      } on FirebaseException {
        // fall through to throw
      }
      throw DataRepositoryException(
          'Failed to load floors for "$facilityId"', e);
    }
  }
}
