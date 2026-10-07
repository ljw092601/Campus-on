import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dining_menu.dart';
import '../../domain/repositories/dining_repository.dart';
import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';
import 'repository_exceptions.dart';

/// Reads `cafeterias` (static info, 8 docs) + that day's `dining_menus`
/// (`where date == yyyy-MM-dd`) and joins them into one [CafeteriaMenu] per
/// cafeteria. Field shapes: see [FirestorePaths.cafeterias] /
/// [FirestorePaths.diningMenus]; the join itself is [cafeteriaMenuFromData].
///
/// Result order is the display order: campus group (승학 → 구덕·부민), then the
/// cafeteria's `order` field inside its group, then id as a stable tiebreak.
class FirestoreDiningRepository implements DiningRepository {
  FirestoreDiningRepository(this._db);
  final FirebaseFirestore _db;

  /// Same ordering as the mock so both data sources render identically.
  static int compareForDisplay(CafeteriaMenu a, CafeteriaMenu b) {
    final group = a.campusGroup.index.compareTo(b.campusGroup.index);
    if (group != 0) return group;
    final order = a.order.compareTo(b.order);
    return order != 0 ? order : a.id.compareTo(b.id);
  }

  static String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    // Provider caching avoids redundant reads; retry must reread BOTH collections.
    final cafeterias = await readQuery(_db.collection(FirestorePaths.cafeterias),
        limit: FirestoreListLimits.cafeterias);
    if (cafeterias.isEmpty) return RepositoryList(const []);
    final menuDocs = await readQuery(
        _db
            .collection(FirestorePaths.diningMenus)
            .where('date', isEqualTo: _ymd(date)),
        limit: FirestoreListLimits.diningMenus);
    final byId = <String, Map<String, dynamic>>{};
    // A page that filled its list limit may be missing cafeterias or menus.
    var incomplete = cafeterias.incomplete || menuDocs.incomplete;
    for (final doc in menuDocs) {
      final data = doc.data();
      if (data['cafeteriaId'] is String) {
        byId[data['cafeteriaId'] as String] = data;
      } else {
        incomplete = true;
      }
    }
    final menus = <CafeteriaMenu>[];
    for (final cafeteria in cafeterias) {
      final data = byId[cafeteria.id];
      // A missing entry in a partial cache does not mean "unpublished".
      final unknown = (data == null && menuDocs.fromCache) ||
          (data != null &&
              !const ['open', 'closed', 'unpublished']
                  .contains(data['status']));
      try {
        final base = cafeteriaMenuFromDocs(cafeteria, unknown ? null : data);
        menus.add(unknown
            ? CafeteriaMenu.fromJson(
                {...base.toJson(), 'status': 'unavailable'})
            : base);
        incomplete |= unknown;
      } catch (_) {
        incomplete = true;
        try {
          final base = cafeteriaMenuFromDocs(cafeteria, null);
          menus.add(CafeteriaMenu.fromJson(
              {...base.toJson(), 'status': 'unavailable'}));
        } catch (_) {/* The cafeteria itself is malformed. */}
      }
    }
    if (menus.isEmpty) {
      throw const DataRepositoryException('No readable cafeterias');
    }
    menus.sort(compareForDisplay);
    return RepositoryList(menus,
        fromCache: cafeterias.fromCache || menuDocs.fromCache,
        incomplete: incomplete);
  }
}
