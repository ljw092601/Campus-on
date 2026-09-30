import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/facility.dart';
import '../../domain/repositories/facility_repository.dart';
import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreFacilityRepository implements FacilityRepository {
  FirestoreFacilityRepository(this._db);
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.facilities);

  Future<List<Facility>> _loadAll() async =>
      mapReadDocuments(await readQuery(_col), facilityFromDoc);

  @override
  Future<List<Facility>> getAll() => _loadAll();

  @override
  Future<Facility?> getById(String id) async {
    final doc = await readDocument(_col.doc(id));
    return doc.exists ? facilityFromDoc(doc) : null;
  }

  @override
  Future<List<Facility>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _loadAll();
    return preserveReadStatus(
        all,
        all.where((v) =>
            v.nameKo.toLowerCase().contains(q) ||
            v.nameEn.toLowerCase().contains(q)));
  }

  @override
  Future<List<Facility>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final wanted = ids.toSet();
    final all = await _loadAll();
    return preserveReadStatus(all, all.where((f) => wanted.contains(f.id)));
  }
}
