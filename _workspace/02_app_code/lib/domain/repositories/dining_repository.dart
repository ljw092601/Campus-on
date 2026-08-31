import '../entities/dining_menu.dart';

/// Daily cafeteria menus.
///
/// The real data will come from a school-provided API (contract TBD as of
/// 2026-08-31). Until that lands the app ships [MockDiningRepository];
/// when the API spec arrives, add an `ApiDiningRepository` implementing this
/// interface and swap it in `repository_providers.dart` — screens and
/// providers stay untouched (same pattern as facilities/guides).
abstract interface class DiningRepository {
  /// Menus for every cafeteria on [date] (local time; time-of-day ignored).
  /// A cafeteria that is closed that day is still returned with empty meals.
  Future<List<CafeteriaMenu>> getMenus(DateTime date);
}
