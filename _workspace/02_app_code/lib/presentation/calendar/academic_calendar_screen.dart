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
import '../../core/layout/flexible_text_layout.dart';

/// 학사일정 — shows ONLY the current academic year (학년도, Mar–Feb),
/// grouped by month. Other years' rows may exist in Firestore (the admin
/// registers next year's schedule ahead of time, and past rows linger until
/// the sheet is cleaned), but they are meaningless to students, so the app
/// filters them out — no year switcher by design.
/// Lives under the home branch (`/home/calendar`) so back returns home.
class AcademicCalendarScreen extends ConsumerWidget {
  const AcademicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final async = ref.watch(academicEventsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.home_card_calendar_title)),
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
          final monthFmt = DateFormat.yMMMM(locale.toLanguageTag());

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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  child: Column(
                    children: [
                      for (var i = 0; i < entry.value.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16),
                        _EventRow(event: entry.value[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
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

    // At 320dp with 200 % text the date chip and the badge take the whole row
    // and the title — the part that says what the event is — is squeezed to a
    // character or two. Past the default text size the row folds into two lines instead
    // (감사 05/038 SF-1).
    final large = prefersFlexibleLayout(context);

    final date = Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _dateLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
    );

    final title = Text(
      event.title(locale),
      // Folded layout gives the title a line of its own, so it needs no cap; an
      // ellipsis with no cap would ellipsize at the first line.
      maxLines: large ? null : 2,
      overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, height: 1.35),
    );

    final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _categoryLabel(l),
              // Folded, the badge has room to wrap; clipping it would drop the
              // only words that say what kind of entry this is.
              maxLines: large ? null : 1,
              overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: badgeFg),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap, not Row: at 320dp with 200 % text the date chip can
                // take most of the width, and a badge that wraps inside a Row
                // still overflows it by its longest word. Here the badge simply
                // drops to its own line when it no longer fits beside the date.
                Wrap(spacing: 8, runSpacing: 6, children: [date, badge]),
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
                // Flexible so the row cannot overflow while the text scale and
                // the layout disagree for a frame (changing the system text
                // size rebuilds one before the other).
                Flexible(child: badge),
              ],
            ),
    );
  }
}
