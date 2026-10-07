/// Campus-local "now" and "today" (L-14).
///
/// Dining menus and the academic year (학년도) are defined on the campus's
/// calendar — Asia/Seoul — not the device's. A student checking the app from
/// another time zone (or a phone whose zone drifted) must still see the same
/// day's menu as everyone on campus. Korea has no DST, so a fixed +09:00
/// offset applied to UTC is exact; no tz database is needed.
///
/// Everything date-related in the app should go through [CampusClock] instead
/// of `DateTime.now()`, which also makes screens testable: [override] lets a
/// test pin the clock to a known instant ([fix]/[reset] are shorthand).
library;

/// Korea Standard Time: UTC+9, no daylight saving.
const Duration kstOffset = Duration(hours: 9);

/// Source of the current instant; must return a UTC [DateTime] (any
/// non-UTC value is converted with `toUtc()`, which depends on the host zone).
typedef NowFn = DateTime Function();

abstract final class CampusClock {
  /// When non-null, replaces the system clock. Test-only; always [reset] in
  /// a tearDown so one test's pinned date never leaks into the next.
  static NowFn? override;

  /// Current instant in UTC.
  static DateTime nowUtc() => (override?.call() ?? DateTime.now()).toUtc();

  /// Current wall-clock time in Seoul, as a *local-flagged* [DateTime] whose
  /// fields (year…second) read as KST. Only the fields are meaningful; do not
  /// compare it against real local `DateTime.now()` instants.
  static DateTime nowInKorea() {
    final k = nowUtc().add(kstOffset);
    return DateTime(k.year, k.month, k.day, k.hour, k.minute, k.second,
        k.millisecond, k.microsecond);
  }

  /// Today's date in Korea, normalized to midnight (date-only key).
  /// Comparable with `DateTime(y, m, d)` keys used by repositories.
  static DateTime today() {
    final k = nowUtc().add(kstOffset);
    return DateTime(k.year, k.month, k.day);
  }

  /// Whether [d] (date part only) is today in Korea.
  static bool isToday(DateTime d) => isSameDay(d, today());

  /// Date-only equality, ignoring time of day and UTC flag.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Normalize to a date-only key (midnight, local-flagged).
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Pins the clock so that [kstWallClock]'s fields are what Korea reads
  /// right now, e.g. `CampusClock.fix(DateTime(2026, 10, 8, 23, 59))`.
  /// Test helper — pair with [reset].
  static void fix(DateTime kstWallClock) {
    final w = kstWallClock;
    final utc = DateTime.utc(w.year, w.month, w.day, w.hour, w.minute,
            w.second, w.millisecond, w.microsecond)
        .subtract(kstOffset);
    override = () => utc;
  }

  /// Restores the system clock.
  static void reset() => override = null;
}
