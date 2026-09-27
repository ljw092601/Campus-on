import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreCalendar;
import '../../domain/entities/academic_event.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/academic_calendar_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/ui_kit.dart';

/// 학사일정 — shows ONLY the current academic year (학년도, Mar–Feb),
/// grouped by month. Other years' rows may exist in Firestore (the admin
/// registers next year's schedule ahead of time, and past rows linger until
/// the sheet is cleaned), but they are meaningless to students, so the app
/// filters them out — no year switcher by design.
/// Lives under the home branch (`/home/calendar`) so back returns home.
class AcademicCalendarScreen extends ConsumerStatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  ConsumerState<AcademicCalendarScreen> createState() =>
      _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState
    extends ConsumerState<AcademicCalendarScreen> {
  /// One key per rendered month header, so "이번 달" can scroll to it.
  final Map<DateTime, GlobalKey> _monthKeys = {};

  /// Scrolls to the current month's section, or — if this month has no
  /// events — the next month that does (falling back to the last one).
  void _jumpToThisMonth() {
    if (_monthKeys.isEmpty) return;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final async = ref.watch(academicEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.home_card_calendar_title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: async.hasValue ? _jumpToThisMonth : null,
              icon: const Icon(Symbols.calendar_today, size: 18),
              label: Text(l.calendar_thisMonth),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: l.calendar_error_loadFailed,
          retryLabel: l.common_retry,
          onRetry: () => ref.invalidate(academicEventsProvider),
        ),
        data: (events) {
          final currentYear = AcademicEvent.academicYearOf(DateTime.now());

          // Group this year's events by start month (events arrive
          // start-sorted, so insertion order keeps months chronological).
          final months = <DateTime, List<AcademicEvent>>{};
          for (final e in events) {
            if (e.academicYear != currentYear) continue;
            months
                .putIfAbsent(DateTime(e.start.year, e.start.month), () => [])
                .add(e);
          }
          final tag = locale.toLanguageTag();
          final monthFmt = DateFormat.MMMM(tag);
          final yearFmt = DateFormat.y(tag);
          _monthKeys.removeWhere((m, _) => !months.containsKey(m));

          if (months.isEmpty) {
            return Center(
              child: Text(
                l.calendar_empty,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          // A year's schedule is short, so a non-lazy column keeps every
          // month header built and reachable by Scrollable.ensureVisible.
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sample-data disclaimer is for mock mode only; Firestore
                // mode shows real admin-entered schedule.
                if (!useFirestoreCalendar)
                  InfoBanner(text: l.calendar_placeholder_notice),
                for (final entry in months.entries) ...[
                  _MonthHeader(
                    key: _monthKeys.putIfAbsent(entry.key, GlobalKey.new),
                    month: monthFmt.format(entry.key),
                    year: yearFmt.format(entry.key),
                  ),
                  GroupCard(
                    children: [
                      for (final e in entry.value) _EventRow(event: e),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            month,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: headingColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            year,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event});
  final AcademicEvent event;

  /// Compact numeric date label: `9.1`, `10.20–26`, `12.21–1.13`.
  String _dateLabel() {
    final s = event.start;
    final e = event.end;
    if (e == null) return '${s.month}.${s.day}';
    if (e.year == s.year && e.month == s.month) {
      return '${s.month}.${s.day}–${e.day}';
    }
    return '${s.month}.${s.day}–${e.month}.${e.day}';
  }

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 84,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              color: Tone.neutral.bg(context),
              borderRadius: BorderRadius.circular(999),
            ),
            // Long cross-month ranges ("12.21–1.13") shrink to fit the
            // fixed-width pill instead of wrapping.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _dateLabel(),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title(locale),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ToneBadge(_categoryLabel(l), tone: _categoryTone),
        ],
      ),
    );
  }
}
