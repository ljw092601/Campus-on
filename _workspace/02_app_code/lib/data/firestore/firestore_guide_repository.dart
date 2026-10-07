import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/admin_guide.dart';
import '../../domain/repositories/guide_repository.dart';
import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreGuideRepository implements GuideRepository {
  FirestoreGuideRepository(this._db);
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.guideItems);

  Future<List<AdminGuideItem>> _loadAll() async =>
      mapReadDocuments(
          await readQuery(_col, limit: FirestoreListLimits.guideItems),
          guideFromDoc);

  @override
  Future<List<AdminGuideItem>> getAllItems() => _loadAll();

  @override
  Future<AdminGuideItem?> getById(String id) async {
    final doc = await readDocument(_col.doc(id));
    return doc.exists ? guideFromDoc(doc) : null;
  }

  @override
  Future<List<AdminGuideItem>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _loadAll();
    return preserveReadStatus(
        all,
        all.where((v) =>
            v.titleKo.toLowerCase().contains(q) ||
            v.titleEn.toLowerCase().contains(q)));
  }

  @override
  Future<List<AdminGuideItem>> getByCategory(GuideCategory category) async {
    final all = await _loadAll();
    return preserveReadStatus(
        all, orderGuideItems(all.where((g) => g.categoryId == category)));
  }
}
