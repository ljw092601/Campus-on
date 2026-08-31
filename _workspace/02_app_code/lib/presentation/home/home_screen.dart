import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/locale_provider.dart';

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
            Text(
              l.appTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -0.5,
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
    final isKo = locale.languageCode == 'ko';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active =
        isDark ? Theme.of(context).colorScheme.primary : HomeScreen.brandNavy;
    final inactive = Theme.of(context).colorScheme.outline;

    TextStyle st(bool on) => TextStyle(
          fontSize: 15,
          fontWeight: on ? FontWeight.w800 : FontWeight.w500,
          color: on ? active : inactive,
        );

    return TextButton(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: 'KO', style: st(isKo)),
          TextSpan(text: '  |  ', style: st(false)),
          TextSpan(text: 'EN', style: st(!isKo)),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
        title: l.home_section_facilityCategory,
        description: l.home_card_facility_desc,
        asset: 'assets/home/illu_facility.png',
        onTap: () {
          ref.read(facilityCategoryFilterProvider.notifier).state = null;
          context.go('/map/list');
        },
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

    // Taller cells under large font scale so the description never overflows
    // (UX §6: no breakage at 200%).
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
              Text(
                data.description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Expanded(
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
                        height: double.infinity,
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
