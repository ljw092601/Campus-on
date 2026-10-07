import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/building_floors.dart';
import '../../domain/repositories/floor_guide_repository.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreFloorGuideRepository implements FloorGuideRepository {
  FirestoreFloorGuideRepository(this._db);
  final FirebaseFirestore _db;
  @override
  Future<BuildingFloors?> getByFacilityId(String facilityId) async {
    final doc = await readDocument(
        _db.collection(FirestorePaths.buildingFloors).doc(facilityId));
    // A malformed or unavailable document is an error, not "no floor guide":
    // a parse failure surfaces as MalformedDocumentException (L-23).
    return mapSingleDocument(
        doc, FirestorePaths.buildingFloors, buildingFloorsFromDoc);
  }
}
