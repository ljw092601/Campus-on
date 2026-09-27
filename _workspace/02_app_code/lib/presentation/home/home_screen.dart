import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/app_languages.dart';
import '../../core/layout/flexible_text_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/academic_event.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/academic_calendar_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/ui_kit.dart';

/// S1 — Home hub, restyled after DONG-A-MATE_UI mockup: emblem + wordmark
/// header with the language pill, date chip + greeting, bright-blue classroom-search
/// hero with a fake search field, a 2×2 grid of icon-tile feature cards and
/// the next few academic events.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        // The language button shows a two-letter code beside a caret; in a 56px
        // toolbar it lost its bottom at 200 % text, so the bar grows with the
        // text instead of the label shrinking.
        toolbarHeight:
            56 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6),
        backgroundColor: bg,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/home/app_emblem.png',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 10),
            // Flexible + scaleDown: on a 360dp phone the actions leave the
            // title box narrow, so the wordmark shrinks instead of overflowing.
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _Wordmark(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Symbols.search, color: headingColor(context), size: 26),
            tooltip: l.home_searchBar_hint,
            onPressed: () => context.push('/search'),
          ),
          const _LangToggle(),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: const [
          _Greeting(),
          SizedBox(height: 18),
          _HeroSearchCard(),
          SizedBox(height: 16),
          _FeatureGrid(),
          _UpcomingEvents(),
        ],
      ),
    );
  }
}

/// "DONG-A-MATE" wordmark: heavy navy letters with yellow hyphens. Read out
/// to screen readers as the localized app title.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ink = headingColor(context);
    final letters = TextStyle(color: ink);
    const dash = TextStyle(color: AppColors.yellow);
    return Semantics(
      label: l.appTitle,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
          children: [
            TextSpan(text: 'DONG', style: letters),
            const TextSpan(text: '-', style: dash),
            TextSpan(text: 'A', style: letters),
            const TextSpan(text: '-', style: dash),
            TextSpan(text: 'MATE', style: letters),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// White bordered pill showing the current language's short code in a filled
/// blue pill plus a caret. Four languages no longer fit a KO|EN toggle, so it
/// opens the language list; Settings has the same list.
class _LangToggle extends ConsumerWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final code = ref.watch(localeProvider).languageCode;
    final pillColor = Tone.blue.fg(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: scheme.surface,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        tooltip: l.settings_language_title,
        initialValue: code,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (code) async {
          final messenger = ScaffoldMessenger.of(context);
          // Same as the settings list: say on screen when the choice could not
          // be remembered (감사 05/035 NIT-2).
          if (!await ref
              .read(localeProvider.notifier)
              .setLocale(Locale(code))) {
            if (!context.mounted) return;
            messenger
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                // Two sentences in a second language need more than the
                // default four seconds (감사 05/037 SF-3).
                duration: const Duration(seconds: 10),
                content: Text(
                    AppLocalizations.of(context).settings_language_save_failed),
              ));
          }
        },
        itemBuilder: (context) => [
          // Each language is named in itself, with a locale hint so a screen
          // reader pronounces it in that language.
          for (final c in appLanguageCodes)
            PopupMenuItem<String>(
              value: c,
              child: Text(appLanguageNames[c]!, locale: Locale(c)),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  appLanguageShortNames[code] ?? code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? scheme.surface : Colors.white,
                  ),
                ),
              ),
              Icon(Symbols.arrow_drop_down,
                  size: 22, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date chip ("SUN · 9.27") + semester-week text, then the big greeting.
class _Greeting extends StatelessWidget {
  const _Greeting();

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  /// "2026년 2학기 4주차" style label. Semesters are approximated as 16-week
  /// terms starting Mar 2 (1학기) and Sep 1 (2학기), counted in Mon–Sun weeks;
  /// anything outside falls back to the summer / winter break label.
  static String semesterLabel(AppLocalizations l, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (final (term, start) in [
      (2, DateTime(today.year, 9, 1)),
      (1, DateTime(today.year, 3, 2)),
    ]) {
      if (today.isBefore(start)) continue;
      final weekStart = start.subtract(Duration(days: start.weekday - 1));
      final week = today.difference(weekStart).inDays ~/ 7 + 1;
      if (week <= 16) {
        return l.home_semesterWeek(today.year, term, week);
      }
      return term == 1
          ? l.home_break_summer(today.year)
          : l.home_break_winter(today.year);
    }
    // Jan / Feb: winter break of the previous academic year.
    return l.home_break_winter(today.year - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ToneBadge(
              '${_weekdays[now.weekday - 1]} · ${now.month}.${now.day}',
              tone: Tone.navy,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            Text(
              semesterLabel(l, now),
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.home_greeting,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Theme.of(context).brightness == Brightness.dark
                ? scheme.onSurface
                : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Bright-blue "classroom search" hero with the DM emblem peeking in from the
/// top-right and a white pill fake search field. Tapping anywhere on the card
/// opens the classroom search screen.
class _HeroSearchCard extends StatelessWidget {
  const _HeroSearchCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large = prefersFlexibleLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(28));

    return Semantics(
      button: true,
      label: l.classroom_search_title,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Material(
          color: AppColors.blue,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/classroom-search'),
            child: Stack(
              children: [
                // Decorative DM emblem, partly cropped by the card's edge.
                Positioned(
                  top: -6,
                  right: -22,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: 0.12,
                      child: Opacity(
                        opacity: 0.95,
                        child: Image.asset(
                          'assets/home/app_emblem.png',
                          width: 132,
                          height: 132,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 96),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.classroom_search_title,
                              // The card grows, so at large text the heading
                              // takes the lines it needs instead of being cut -
                              // and an ellipsis with no limit would ellipsize
                              // at the first line (measured).
                              maxLines: large ? null : 2,
                              overflow: large
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.home_classroom_subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Symbols.search,
                                size: 22, color: AppColors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.home_classroom_hint,
                                // One line in the pill at ordinary sizes; at
                                // large text / on a narrow phone the example
                                // wraps (the pill grows) instead of being cut
                                // to "예: 공과…", which hid the format it shows.
                                maxLines: large ? null : 1,
                                overflow: large
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final cards = <_FeatureCardData>[
      _FeatureCardData(
        title: l.home_section_guide,
        description: l.home_card_guide_desc,
        icon: Symbols.badge,
        tone: Tone.blue,
        onTap: () => context.go('/guide'),
      ),
      _FeatureCardData(
        title: l.home_card_calendar_title,
        description: l.home_card_calendar_desc,
        icon: Symbols.calendar_month,
        tone: Tone.yellow,
        onTap: () => context.go('/home/calendar'),
      ),
      _FeatureCardData(
        title: l.home_card_map_title,
        description: l.home_card_map_desc,
        icon: Symbols.location_on,
        tone: Tone.green,
        onTap: () => context.go('/map'),
      ),
      _FeatureCardData(
        title: l.home_card_dining_title,
        description: l.home_card_dining_desc,
        icon: Symbols.rice_bowl,
        tone: Tone.coral,
        onTap: () => context.go('/home/dining'),
      ),
    ];

    const gap = 14.0;
    // Two columns work at ordinary text sizes. Past the default text size (or
    // on a 320dp screen) they cannot hold a card title at all - each cell is
    // ~137px wide, which left two characters - so the cards become full-width,
    // each as tall as its own text needs, which is what makes a long title in
    // Vietnamese or English readable instead of ellipsized (감사 05/036 SF-2).
    // The home body already scrolls.
    if (prefersFlexibleLayout(context)) {
      return Column(
        children: [
          for (final c in cards) ...[
            _FeatureCard(data: c),
            const SizedBox(height: gap),
          ],
        ],
      );
    }

    // Rows of IntrinsicHeight pairs instead of a fixed-aspect grid: both cards
    // in a row share the taller one's height, so long copy grows the card
    // instead of overflowing it (UX §6).
    return Column(
      children: [
        for (var r = 0; r < cards.length; r += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _FeatureCard(data: cards[r])),
                const SizedBox(width: gap),
                Expanded(child: _FeatureCard(data: cards[r + 1])),
              ],
            ),
          ),
          const SizedBox(height: gap),
        ],
      ],
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Tone tone;
  final VoidCallback onTap;
}

/// White r24 feature card: tinted icon tile + gray chevron on top, bold title
/// and gray one-liner below.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});
  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    final large = prefersFlexibleLayout(context);
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppColors.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: softShadow(context),
      ),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: data.icon, tone: data.tone, size: 52),
                    const Spacer(),
                    Icon(Symbols.chevron_right,
                        size: 22, color: scheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  // Two lines side by side; no cap at large text, where the
                  // card is full width and grows with its content, so the
                  // whole title is shown rather than cut (감사 05/036 SF-2).
                  // An ellipsis with no line limit ellipsizes at the first
                  // line, so unlimited lines must drop it (measured).
                  maxLines: large ? null : 2,
                  overflow:
                      large ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? scheme.onSurface
                        : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  maxLines: large ? null : 3,
                  overflow:
                      large ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "다가오는 일정" — the next few academic events that haven't ended yet.
/// Hidden entirely while loading, on error, or when nothing is upcoming.
class _UpcomingEvents extends ConsumerWidget {
  const _UpcomingEvents();

  static const _maxItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final events = ref.watch(academicEventsProvider).valueOrNull;
    if (events == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = events
        .where((e) => !e.endDate.isBefore(today))
        .take(_maxItems)
        .toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l.home_upcoming_title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/home/calendar'),
              style: TextButton.styleFrom(
                foregroundColor: Tone.blue.fg(context),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              child: Text(l.home_viewAll),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GroupCard(
          children: [for (final e in upcoming) _UpcomingRow(event: e)],
        ),
      ],
    );
  }
}

class _UpcomingRow extends ConsumerWidget {
  const _UpcomingRow({required this.event});
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

  (String, Tone) _category(AppLocalizations l) => switch (event.category) {
        AcademicEventCategory.semester => (l.calendar_cat_semester, Tone.navy),
        AcademicEventCategory.registration => (
            l.calendar_cat_registration,
            Tone.blue
          ),
        AcademicEventCategory.exam => (l.calendar_cat_exam, Tone.red),
        AcademicEventCategory.holiday => (l.calendar_cat_holiday, Tone.yellow),
        AcademicEventCategory.graduation => (
            l.calendar_cat_graduation,
            Tone.purple
          ),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final (label, tone) = _category(l);

    // Past the default text size (or on a narrow screen) the two badges leave
    // the title a sliver of the row, so the badges go on their own line and
    // the title below takes the full width and the lines it needs — the same
    // fold the calendar list uses (감사 05/037 SF-1).
    if (prefersFlexibleLayout(context)) {
      return InkWell(
        onTap: () => context.go('/home/calendar'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ToneBadge(
                    _dateLabel(),
                    fontSize: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  ),
                  ToneBadge(label, tone: tone),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title(locale),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go('/home/calendar'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ToneBadge(
              _dateLabel(),
              minWidth: 80,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                event.title(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ToneBadge(label, tone: tone),
          ],
        ),
      ),
    );
  }
}
