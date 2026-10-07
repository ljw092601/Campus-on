import '../entities/dining_menu.dart';

/// Daily cafeteria menus.
///
/// A school dining API was confirmed unavailable (2026-09), so production
/// data flows admin sheet → Firestore (`cafeterias` static info + one
/// `dining_menus` doc per cafeteria per day; see
/// _workspace/06_admin_data_pipeline.md). `FirestoreDiningRepository` is
/// swapped in by `--dart-define=USE_FIRESTORE_DINING=true`
/// (`repository_providers.dart`); `MockDiningRepository` is the dev default
/// and ships the same 8 cafeterias with a fake rotating week of menus.
abstract interface class DiningRepository {
  /// Menus for every cafeteria on [date] (local time; time-of-day ignored).
  ///
  /// Every cafeteria is always returned, in display order (campus group
  /// 승학 → 구덕·부민, then `order`, then id). A cafeteria that does not serve
  /// that day still comes back with no sections and a [CafeteriaMenu.status]
  /// of `closed` (explicit closure) or `unpublished` (menu not entered);
  /// a Firestore read that could not establish the day's menu returns
  /// `unavailable`.
  Future<List<CafeteriaMenu>> getMenus(DateTime date);
}
