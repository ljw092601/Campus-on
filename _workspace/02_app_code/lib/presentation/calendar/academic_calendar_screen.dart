import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreCalendar;
import '../../core/layout/flexible_text_layout.dart';
import '../../core/util/campus_clock.dart';
import '../../domain/entities/academic_event.dart';
import '../../domain/repositories/read_result.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/academic_calendar_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';
import '../shared/widgets/ui_kit.dart';

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
/// The "This month" action scrolls back to the current month's header, and
/// pull-to-refresh (also on the empty state) re-fetches, so events published
/// via the admin sheet show up without restarting the app.
class AcademicCalendarScreen extends ConsumerStatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  ConsumerState<AcademicCalendarScreen> createState() =>
      _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState
    extends ConsumerState<AcademicCalendarScreen> {
  final _listKey = GlobalKey<_CalendarListState>();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(academicEventsProvider);
    final today = CampusClock.today();
    final currentYear = AcademicEvent.academicYearOf(today);
    void jump() => _listKey.currentState?.jumpToThisMonth();

    // Pull-to-refresh re-fetches, so events published via the admin sheet
    // show up without restarting the app.
    Future<void> refresh() => ref.refresh(academicEventsProvider.future);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.home_card_calendar_title),
        actions: [
          // The labelled blue pill takes ~120px of a toolbar; at large text or
          // on a narrow phone that came out of the title, which then lost its
          // whole tail ('Academic calendar' down to a few letters, '학사일정'
          // cut in Korean). There the action collapses to a filled icon
          // button with the same label as its tooltip / semantics, so the
          // title keeps the width the layout tests record for it.
          if (prefersFlexibleLayout(context))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filled(
                onPressed: async.hasValue ? jump : null,
                tooltip: l.calendar_thisMonth,
                icon: const Icon(Symbols.calendar_today, size: 20),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: async.hasValue ? jump : null,
                icon: const Icon(Symbols.calendar_today, size: 18),
                label: Text(l.calendar_thisMonth),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
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
                ? RefreshIndicator(
                    onRefresh: refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              l.calendar_empty,
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _CalendarList(
                    key: _listKey,
                    events: thisYear,
                    today: today,
                    onRefresh: refresh,
                  ),
          );
        },
      ),
    );
  }
}

/// Which emphasis a row gets relative to the campus date.
enum _Emphasis { none, today, upNext }

/// The month-grouped list. Stateful to own the one-time auto-scroll to the
/// focused row (L-13b) and the month header keys the "This month" action
/// scrolls to; a refresh that rebuilds with new data keeps the user's scroll
/// position instead of jumping again.
class _CalendarList extends ConsumerStatefulWidget {
  const _CalendarList({
    super.key,
    required this.events,
    required this.today,
    required this.onRefresh,
  });

  /// Current-year events, start-sorted.
  final List<AcademicEvent> events;
  final DateTime today;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_CalendarList> createState() => _CalendarListState();
}

class _CalendarListState extends ConsumerState<_CalendarList> {
  final _focusKey = GlobalKey();

  /// One key per rendered month header, so "This month" can scroll to it.
  final Map<DateTime, GlobalKey> _monthKeys = {};

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

  /// Scrolls to the current campus month's header, or — if this month has no
  /// events — the next month that does (falling back to the last one).
  void jumpToThisMonth() {
    if (_monthKeys.isEmpty) return;
    final today = CampusClock.today();
    final thisMonth = DateTime(today.year, today.month);
    final months = _monthKeys.keys.toList()..sort();
    final target = months.firstWhere(
      (m) => !m.isBefore(thisMonth),
      orElse: () => months.last,
    );
    final ctx = _monthKeys[target]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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
    final tag = locale.toLanguageTag();
    final monthFmt = DateFormat.MMMM(tag);
    final yearFmt = DateFormat.y(tag);
    final (emphasis, focusId) = _emphasis();

    // Group by start month (events arrive start-sorted, so insertion order
    // keeps months chronological).
    final months = <DateTime, List<AcademicEvent>>{};
    for (final e in widget.events) {
      months
          .putIfAbsent(DateTime(e.start.year, e.start.month), () => [])
          .add(e);
    }
    _monthKeys.removeWhere((m, _) => !months.containsKey(m));

    // A year's schedule is short, so a non-lazy column keeps every row and
    // month header built and reachable by Scrollable.ensureVisible.
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sample-data disclaimer is for mock mode only; Firestore mode
            // shows real admin-entered schedule.
            if (!useFirestoreCalendar)
              InfoBanner(text: l.calendar_placeholder_notice),
            for (final entry in months.entries) ...[
              _MonthHeader(
                key: _monthKeys.putIfAbsent(entry.key, GlobalKey.new),
                month: monthFmt.format(entry.key),
                year: yearFmt.format(entry.key),
              ),
              // Rows pad themselves so a highlighted row tints edge to edge.
              GroupCard(
                padding: EdgeInsets.zero,
                dividerIndent: 16,
                children: [
                  for (final e in entry.value)
                    _EventRow(
                      key: e.id == focusId ? _focusKey : null,
                      event: e,
                      emphasis: emphasis[e.id] ?? _Emphasis.none,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "9월 2026" — big navy month with a small gray year beside it.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({super.key, required this.month, required this.year});
  final String month;
  final String year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      // One paragraph instead of a Row of two Texts: the spans still share a
      // baseline, but a long month name at large text ('September' at 200 %
      // on 320dp) lets the year wrap to the next line instead of overflowing.
      child: Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: month,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
              const TextSpan(text: '  '),
              TextSpan(
                text: year,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
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

  Tone get _categoryTone => switch (event.category) {
        AcademicEventCategory.semester => Tone.navy,
        AcademicEventCategory.registration => Tone.blue,
        AcademicEventCategory.exam => Tone.red,
        AcademicEventCategory.holiday => Tone.yellow,
        AcademicEventCategory.graduation => Tone.purple,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final emphasized = emphasis != _Emphasis.none;
    final isToday = emphasis == _Emphasis.today;
    final accent = Tone.blue.fg(context);
    final emphasisLabel = switch (emphasis) {
      _Emphasis.today => l.calendar_today,
      _Emphasis.upNext => l.calendar_upNext,
      _Emphasis.none => null,
    };

    // At 320dp with 200 % text the date chip and the badge take the whole row
    // and the title — the part that says what the event is — is squeezed to a
    // character or two. Past the default text size the row folds into two
    // lines instead (감사 05/038 SF-1, L-18).
    final large = prefersFlexibleLayout(context);

    final date = Container(
      // Fixed-width pill in the one-line row; folded, it may grow with the
      // text instead of shrinking it to fit.
      constraints: large
          ? const BoxConstraints(minWidth: 84)
          : const BoxConstraints.tightFor(width: 84),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: isToday ? accent : Tone.neutral.bg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      // Long cross-month ranges ("12/21–1/13") shrink to fit the fixed-width
      // pill instead of wrapping.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          formatEventDateRange(event.start, event.end, locale.toLanguageTag()),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isToday ? scheme.surface : headingColor(context),
          ),
        ),
      ),
    );

    final title = Text(
      event.title(locale),
      // Folded layout gives the title a line of its own, so it needs no cap;
      // an ellipsis with no cap would ellipsize at the first line.
      maxLines: large ? null : 2,
      overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
      ),
    );

    // Same look as [ToneBadge], but folded the label may wrap: clipping it
    // would drop the only words that say what kind of entry this is.
    Widget pill(String text, Color bg, Color fg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: large ? null : 1,
            overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        );

    final tone = _categoryTone;
    final badges = [
      if (emphasisLabel != null) pill(emphasisLabel, accent, scheme.surface),
      pill(_categoryLabel(l), tone.bg(context), tone.fg(context)),
    ];

    return Semantics(
      selected: emphasized,
      child: Container(
        color: emphasized ? Tone.blue.bg(context).withValues(alpha: 0.6) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: large
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap, not Row: at 320dp with 200 % text the date chip can
                  // take most of the width, and a badge that wraps inside a
                  // Row still overflows it by its longest word. Here the
                  // badges simply drop to their own line when they no longer
                  // fit beside the date.
                  Wrap(
                      spacing: 8, runSpacing: 6, children: [date, ...badges]),
                  const SizedBox(height: 6),
                  title,
                ],
              )
            : Row(
                children: [
                  date,
                  const SizedBox(width: 12),
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  // Flexible so the row cannot overflow while the text scale
                  // and the layout disagree for a frame (changing the system
                  // text size rebuilds one before the other).
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 4,
                      children: badges,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
