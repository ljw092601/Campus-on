import '../entities/academic_event.dart';

/// Academic-calendar events.
///
/// The real data will come from the official Dong-A academic calendar
/// (source TBD as of 2026-09-10). Until that lands the app ships
/// [MockAcademicCalendarRepository]; when the official schedule is confirmed,
/// add a real implementation and swap it in `repository_providers.dart` —
/// screens and providers stay untouched (same pattern as dining).
abstract interface class AcademicCalendarRepository {
  /// All known events, sorted by start date.
  Future<List<AcademicEvent>> getEvents();
}
