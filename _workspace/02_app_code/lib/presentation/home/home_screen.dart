import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/app_languages.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../../core/layout/flexible_text_layout.dart';

/// S1 — Home hub, restyled after design_template.png: navy hero banner with
/// campus photo + in-banner search, then a 2×2 feature-card grid with the 3D
/// illustrations cropped from the template.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Design-template palette (light mode; hero stays navy in both modes).
  static const heroTop = Color(0xFF0C2A68);
  static const heroBottom = Color(0xFF2A4E8F);
  static const highlightYellow = Color(0xFFFFD44F);
  static const brandNavy = Color(0xFF16337F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF6F7FA);
    final titleColor =
        isDark ? Theme.of(context).colorScheme.primary : brandNavy;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        // The language button shows a two-letter code beside a caret; in a 56px
        // toolbar it lost its bottom at 200 % text, so the bar grows with the
        // text instead of the label shrinking.
        toolbarHeight:
            56 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6),
        backgroundColor: bg,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/home/app_emblem.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            // Flexible + scaleDown: on a 360dp phone the actions leave the
            // title box ~108dp, so the wordmark shrinks instead of overflowing.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l.appTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Symbols.search, color: titleColor, size: 26),
            tooltip: l.home_searchBar_hint,
            onPressed: () => context.push('/search'),
          ),
          const _LangToggle(),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _HeroBanner(),
          const SizedBox(height: 16),
          _FeatureGrid(),
        ],
      ),
    );
  }
}

class _LangToggle extends ConsumerWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active =
        isDark ? Theme.of(context).colorScheme.primary : HomeScreen.brandNavy;

    // Four languages no longer fit a KO|EN toggle, so the button shows the
    // current language and opens the list; Settings has the same list.
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).settings_language_title,
      initialValue: locale.languageCode,
      onSelected: (code) async {
        final messenger = ScaffoldMessenger.of(context);
        // Same as the settings list: say on screen when the choice could not be
        // remembered (감사 05/035 NIT-2).
        if (!await ref.read(localeProvider.notifier).setLocale(Locale(code))) {
          if (!context.mounted) return;
          messenger
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              // Two sentences in a second language need more than the default
              // four seconds (감사 05/037 SF-3).
              duration: const Duration(seconds: 10),
              content: Text(
                  AppLocalizations.of(context).settings_language_save_failed),
            ));
        }
      },
      itemBuilder: (context) => [
        for (final code in appLanguageCodes)
          PopupMenuItem<String>(
            value: code,
            child: Text(appLanguageNames[code]!, locale: Locale(code)),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            appLanguageShortNames[locale.languageCode] ?? locale.languageCode,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: active),
          ),
          Icon(Symbols.arrow_drop_down, size: 20, color: active),
        ]),
      ),
    );
  }
}

/// Navy gradient "classroom search" tile: campus photo on the right (left/
/// bottom edges of the PNG are pre-faded to transparent so it melts into the
/// gradient), halftone dots bottom-left. Tapping anywhere on the tile opens
/// the classroom search screen.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l.classroom_search_title,
      child: GestureDetector(
        onTap: () => context.push('/classroom-search'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [HomeScreen.heroTop, HomeScreen.heroBottom],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Image.asset(
                  'assets/home/hero_photo.png',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerRight,
                ),
              ),
              // Navy wash over the left half so the headline stays readable where
              // the photo's fade begins (matches the template's gradient).
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.35, 0.72],
                      colors: [
                        Color(0xD90C2A68),
                        Color(0x730E2E70),
                        Color(0x000C2A68),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child:
                    IgnorePointer(child: CustomPaint(painter: _DotsPainter())),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 235),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.classroom_search_title,
                        // The banner has a minimum height and grows, so at large
                        // text the heading can take the lines it needs instead of
                        // being cut — and an ellipsis with no limit would
                        // ellipsize at the first line (measured).
                        maxLines: prefersFlexibleLayout(context)
                            ? null
                            : 2,
                        overflow: prefersFlexibleLayout(context)
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Symbols.chevron_right,
                        color: Colors.white, size: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halftone dot texture in the hero's bottom-left corner (design template).
class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    const step = 15.0;
    final origin = Offset(0, size.height);
    final maxDist = size.shortestSide * 0.75;
    for (double x = 6; x < size.width * 0.45; x += step) {
      for (double y = size.height * 0.55; y < size.height; y += step) {
        final d = (Offset(x, y) - origin).distance;
        if (d >= maxDist) continue;
        final r = 3.2 * (1 - d / maxDist);
        if (r < 0.6) continue;
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => false;
}

class _FeatureGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    final cards = <_FeatureCardData>[
      _FeatureCardData(
        title: l.home_section_guide,
        description: l.home_card_guide_desc,
        asset: 'assets/home/illu_guide.png',
        onTap: () => context.go('/guide'),
      ),
      _FeatureCardData(
        title: l.home_card_calendar_title,
        description: l.home_card_calendar_desc,
        asset: 'assets/home/illu_calendar.png',
        onTap: () => context.go('/home/calendar'),
      ),
      _FeatureCardData(
        title: l.home_card_map_title,
        description: l.home_card_map_desc,
        asset: 'assets/home/illu_map.png',
        onTap: () => context.go('/map'),
      ),
      _FeatureCardData(
        title: l.home_card_dining_title,
        description: l.home_card_dining_desc,
        asset: 'assets/home/illu_food.png',
        onTap: () => context.go('/home/dining'),
      ),
    ];

    // Two fixed-ratio columns work at ordinary text sizes. Past the default text size they cannot
    // hold a card title at all — on a 320dp phone each cell is ~137px wide,
    // which left two characters — so the cards become full-width and, more
    // importantly, stop being ratio-sized: each one is as tall as its own text
    // needs, which is what makes a long title in Vietnamese or English readable
    // instead of ellipsized (감사 05/036 SF-2). The home body already scrolls.
    // The cards and the thing that lays them out have to agree: a card that
    // sizes itself inside a fixed-ratio cell overflows it (173px, measured at
    // 320dp with default text).
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (prefersFlexibleLayout(context)) {
      return Column(
        children: [
          for (final c in cards) ...[
            _FeatureCard(data: c),
            if (c != cards.last) const SizedBox(height: 14),
          ],
        ],
      );
    }

    final aspect = (0.86 / textScale).clamp(0.55, 0.86);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: aspect,
      children: [for (final c in cards) _FeatureCard(data: c)],
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.title,
    required this.description,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final String description;
  final String asset;
  final VoidCallback onTap;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});
  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    final large = prefersFlexibleLayout(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? scheme.primary : HomeScreen.brandNavy;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      // Two lines and a scaled size: on a 320dp phone at 200 %
                      // text the title slot is ~85px, so one hard-coded 18px
                      // line left 2 characters in Korean or Chinese and about 5
                      // in Latin — every card read the same (감사 05/036 SF-2).
                      // No cap at large text: the card is full width and grows
                      // with its content there, so the whole title is shown
                      // rather than cut (감사 05/036 SF-2).
                      maxLines: large ? null : 2,
                      // An ellipsis with no line limit makes Flutter ellipsize at the
                      // first line, so unlimited lines must drop it (measured).
                      overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ) ??
                          TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  Icon(Symbols.chevron_right, size: 22, color: titleColor),
                ],
              ),
              const SizedBox(height: 8),
              // At ordinary sizes the card is a fixed-ratio cell, so the teaser
              // takes what is left and ellipsizes there. At large text the card
              // sizes itself to its content: the teaser is shown in full and
              // must not be flexible, because a self-sizing column has no
              // leftover height to hand out.
              _maybeFlexible(
                flexible: !large,
                child: Text(
                  data.description,
                  maxLines: large ? null : 3,
                  overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              _maybeExpanded(
                expanded: !large,
                // At large text the illustration keeps a fixed height instead of
                // taking the leftover space; the text above is what needs the
                // room.
                // 96px added a screenful of scrolling with no information
                // (감사 05/037 SF-4).
                height: 56,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    // Rounded clip so the illustration's white backdrop reads
                    // as a deliberate plate on dark surfaces.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        data.asset,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: large ? 56 : double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// `Flexible` only when the parent has a height to divide.
Widget _maybeFlexible({required bool flexible, required Widget child}) =>
    flexible ? Flexible(child: child) : child;

/// `Expanded` when the parent has leftover height, a fixed box when it does not.
Widget _maybeExpanded(
        {required bool expanded, required double height, required Widget child}) =>
    expanded ? Expanded(child: child) : SizedBox(height: height, child: child);
