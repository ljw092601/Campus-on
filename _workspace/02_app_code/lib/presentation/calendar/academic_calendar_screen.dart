import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreCalendar;
import '../../core/util/campus_clock.dart';
import '../../domain/entities/academic_event.dart';
import '../../domain/repositories/read_result.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/academic_calendar_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';

/// Compact, locale-aware numeric date label for an event (L-13c):
/// en `10/20–26`, `12/21–1/13`; ko `10. 20.–26.`, `12. 21.–1. 13.`.
/// Same-month ranges repeat only the end day. Pure so it is unit-testable;
/// [localeTag] must be a locale whose date symbols are loaded (the app's
/// localization delegates do that for the active locale).
String formatEventDateRange(DateTime start, DateTime? end, String localeTag) {
  final md = DateFormat.Md(localeTag);
  final s = md.format(start);
  if (end == null) return s;
  final sameMonth = end.year == start.year && end.month == start.month;
  final e = sameMonth ? DateFormat.d(localeTag).format(end) : md.format(end);
  return '$s–$e';
}

/// 학사일정 — shows ONLY the current academic year (학년도, Mar–Feb),
/// grouped by month. Other years' rows may exist in Firestore (the admin
/// registers next year's schedule ahead of time, and past rows linger until
/// the sheet is cleaned), but they are meaningless to students, so the app
/// filters them out — no year switcher by design.
/// Lives under the home branch (`/home/calendar`) so back returns home.
///
/// "Current" is judged on the campus date ([CampusClock.today], Asia/Seoul),
/// not the device zone (L-14). Rows that include today are highlighted with a
/// "Today" badge — or, when none does, the next upcoming event gets an
/// "Up next" badge — and the list opens scrolled to that row (L-13a/b).
class AcademicCalendarScreen extends ConsumerWidget {
  const AcademicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(academicEventsProvider);
    final today = CampusClock.today();
    final currentYear = AcademicEvent.academicYearOf(today);

    return Scaffold(
      appBar: AppBar(title: Text(l.home_card_calendar_title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: readErrorMessage(e, l, l.calendar_error_loadFailed),
          retryLabel: l.common_retry,
          onRetry: () => ref.invalidate(academicEventsProvider),
        ),
        data: (events) {
          final thisYear =
              events.where((e) => e.academicYear == currentYear).toList();
          return ReadStatusContent(
            data: preserveReadStatus(events, thisYear),
            onRetry: () => ref.invalidate(academicEventsProvider),
            child: thisYear.isEmpty
                ? Center(
                    child: Text(
                      l.calendar_empty,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _CalendarList(events: thisYear, today: today),
          );
        },
      ),
    );
  }
}

/// Which emphasis a row gets relative to the campus date.
enum _Emphasis { none, today, upNext }

/// The month-grouped list. Stateful only to own the one-time auto-scroll to
/// the focused row (L-13b); a refresh that rebuilds with new data keeps the
/// user's scroll position instead of jumping again.
class _CalendarList extends ConsumerStatefulWidget {
  const _CalendarList({required this.events, required this.today});

  /// Current-year events, start-sorted.
  final List<AcademicEvent> events;
  final DateTime today;

  @override
  ConsumerState<_CalendarList> createState() => _CalendarListState();
}

class _CalendarListState extends ConsumerState<_CalendarList> {
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // All rows are built up front (non-lazy scroll view), so the focused
    // row's context exists after the first frame and ensureVisible can
    // target it without guessing offsets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _focusKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.08,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Rows that include today get [_Emphasis.today]; if there is none, the
  /// earliest event that starts after today gets [_Emphasis.upNext]. Returns
  /// the emphasis per event id plus the id to scroll to (null when every
  /// event is already in the past).
  (Map<String, _Emphasis>, String?) _emphasis() {
    final map = <String, _Emphasis>{};
    String? focus;
    for (final e in widget.events) {
      if (e.containsDay(widget.today)) {
        map[e.id] = _Emphasis.today;
        focus ??= e.id;
      }
    }
    if (focus == null) {
      for (final e in widget.events) {
        if (e.startsAfter(widget.today)) {
          map[e.id] = _Emphasis.upNext;
          focus = e.id;
          break;
        }
      }
    }
    return (map, focus);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final monthFmt = DateFormat.yMMMM(locale.toLanguageTag());
    final (emphasis, focusId) = _emphasis();

    // Group by start month (events arrive start-sorted, so insertion order
    // keeps months chronological).
    final months = <DateTime, List<AcademicEvent>>{};
    for (final e in widget.events) {
      months
          .putIfAbsent(DateTime(e.start.year, e.start.month), () => [])
          .add(e);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sample-data disclaimer is for mock mode only; Firestore mode
          // shows real admin-entered schedule.
          if (!useFirestoreCalendar)
            _NoticeBanner(text: l.calendar_placeholder_notice),
          for (final entry in months.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Text(
                monthFmt.format(entry.key),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _EventRow(
                      key: entry.value[i].id == focusId ? _focusKey : null,
                      event: entry.value[i],
                      emphasis: emphasis[entry.value[i].id] ?? _Emphasis.none,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Symbols.info, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({super.key, required this.event, required this.emphasis});
  final AcademicEvent event;
  final _Emphasis emphasis;

  String _categoryLabel(AppLocalizations l) => switch (event.category) {
        AcademicEventCategory.semester => l.calendar_cat_semester,
        AcademicEventCategory.registration => l.calendar_cat_registration,
        AcademicEventCategory.exam => l.calendar_cat_exam,
        AcademicEventCategory.holiday => l.calendar_cat_holiday,
        AcademicEventCategory.graduation => l.calendar_cat_graduation,
      };

  (Color, Color) _categoryColors(ColorScheme scheme) =>
      switch (event.category) {
        AcademicEventCategory.semester => (
            scheme.secondaryContainer,
            scheme.onSecondaryContainer
          ),
        AcademicEventCategory.registration => (
            scheme.primaryContainer,
            scheme.onPrimaryContainer
          ),
        AcademicEventCategory.exam => (
            scheme.errorContainer,
            scheme.onErrorContainer
          ),
        AcademicEventCategory.holiday => (
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer
          ),
        AcademicEventCategory.graduation => (
            scheme.primaryContainer,
            scheme.onPrimaryContainer
          ),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final (badgeBg, badgeFg) = _categoryColors(scheme);
    final emphasized = emphasis != _Emphasis.none;
    final emphasisLabel = switch (emphasis) {
      _Emphasis.today => l.calendar_today,
      _Emphasis.upNext => l.calendar_upNext,
      _Emphasis.none => null,
    };

    // Layout is overflow-proof at large text scales (L-18): the date box is
    // width-capped and wraps, the title is the only Expanded child, and the
    // badges live in a Wrap that drops to a new line instead of pushing the
    // row past its bounds.
    return Semantics(
      selected: emphasized,
      child: Container(
        color: emphasized
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, maxWidth: 128),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emphasis == _Emphasis.today
                      ? scheme.primary
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatEventDateRange(
                      event.start, event.end, locale.toLanguageTag()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: emphasis == _Emphasis.today
                        ? scheme.onPrimary
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    event.title(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: emphasized ? FontWeight.w700 : null,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (emphasisLabel != null)
                        _Badge(
                          label: emphasisLabel,
                          background: scheme.primary,
                          foreground: scheme.onPrimary,
                        ),
                      _Badge(
                        label: _categoryLabel(l),
                        background: badgeBg,
                        foreground: badgeFg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
