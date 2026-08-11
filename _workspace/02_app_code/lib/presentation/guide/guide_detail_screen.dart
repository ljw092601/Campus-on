import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/favorites_provider.dart';
import '../providers/guide_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';

/// S7 — Guide Detail. Fixed section template (overview → checklist → steps →
/// tips → phrases → links/locations) rendered as scrollable cards, each headed
/// by the category accent color. Coming-soon items show the standard
/// placeholder (plus any related-location card so the deep link works).
class GuideDetailScreen extends ConsumerWidget {
  const GuideDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(guideByIdProvider(itemId));

    return Scaffold(
      appBar: AppBar(actions: [_FavoriteButton(itemId: itemId)]),
      body: async.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _errorView(context, ref, l),
        data: (item) => item == null
            ? _errorView(context, ref, l)
            : _DetailBody(item: item),
      ),
    );
  }

  Widget _errorView(BuildContext context, WidgetRef ref, AppLocalizations l) =>
      ErrorStateView(
        message: l.guide_detail_error,
        retryLabel: l.common_retry,
        onRetry: () => ref.invalidate(guideByIdProvider(itemId)),
      );
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final favs = ref.watch(favoritesProvider);
    final isFav =
        favs.valueOrNull?.contains('${FavoriteType.guide.name}:$itemId') ??
            false;
    return IconButton(
      icon: Icon(Symbols.star, fill: isFav ? 1 : 0),
      tooltip: isFav ? l.guide_favorite_remove : l.guide_favorite_add,
      onPressed: () =>
          ref.read(favoritesProvider.notifier).toggle(FavoriteType.guide, itemId),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.item});
  final AdminGuideItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final accent = accentFor(context, context.catColors.forGuide(item.categoryId));
    final d = context.dimens;
    final scheme = Theme.of(context).colorScheme;

    final overview = item.overview(locale);
    final checklist = item.checklist(locale);
    final checklistNote = item.checklistNote(locale);
    final steps = item.steps(locale);
    final tips = item.tips(locale);
    final hasLinksOrLocations =
        item.links.isNotEmpty || item.relatedFacilityIds.isNotEmpty;

    // Vertically scrollable body; every section below is its own card.
    return ListView(
      padding: EdgeInsets.only(bottom: d.spaceLg),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(d.spaceMd, d.spaceMd, d.spaceMd, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title(locale),
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: d.spaceSm),
              _MetaRow(item: item, color: accent),
            ],
          ),
        ),
        SizedBox(height: d.spaceMd),

        // Whole-screen coming-soon when there is no sectioned content at all.
        if (item.hasNoContent)
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: d.spaceMd, vertical: d.spaceLg),
            child: _ComingSoonCard(text: l.guide_detail_comingSoon_body),
          )
        else ...[
          if (overview != null)
            _Section(
              title: l.guide_section_overview,
              icon: Symbols.info,
              accent: accent,
              child:
                  Text(overview, style: Theme.of(context).textTheme.bodyLarge),
            ),
          if (checklist.isNotEmpty)
            _Section(
              title: l.guide_section_checklist,
              icon: Symbols.checklist,
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in checklist) _ChecklistRow(text: c),
                  if (checklistNote != null) ...[
                    SizedBox(height: d.spaceSm),
                    Text(
                      checklistNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          if (steps.isNotEmpty)
            _Section(
              title: l.guide_section_steps,
              icon: Symbols.format_list_numbered,
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    _StepRow(index: i + 1, text: steps[i], color: accent),
                ],
              ),
            ),
          if (tips.isNotEmpty)
            _Section(
              title: l.guide_section_tips,
              icon: Symbols.lightbulb,
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in tips) _TipRow(text: t, color: accent),
                ],
              ),
            ),
          if (item.phrases.isNotEmpty)
            _Section(
              title: l.guide_section_phrases,
              icon: Symbols.translate,
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in item.phrases)
                    _PhraseCard(phrase: p, color: accent),
                ],
              ),
            ),
        ],

        // Links + related locations (shown even for coming-soon items).
        if (hasLinksOrLocations)
          _Section(
            title: l.guide_section_links,
            icon: Symbols.link,
            accent: accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final link in item.links) _LinkRow(link: link),
                for (final fid in item.relatedFacilityIds)
                  _RelatedLocationCard(facilityId: fid),
              ],
            ),
          ),
      ],
    );
  }
}

/// Category accent adjusted for the current brightness.
///
/// The category tokens (§4.1) are single mid-tone values shared by both themes
/// — e.g. living = teal `#00838F`, which does not clear text contrast on the
/// dark surface. Light mode keeps the exact token; dark mode gets a lightened,
/// slightly desaturated variant so the dark palette itself stays unchanged.
Color accentFor(BuildContext context, Color base) {
  if (Theme.of(context).brightness == Brightness.light) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness + 0.32).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
      .toColor();
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item, required this.color});
  final AdminGuideItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final duration = item.duration(locale);
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (duration != null) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.schedule, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(duration, style: Theme.of(context).textTheme.bodySmall),
        ],
      ));
    }
    if (item.difficulty != null) {
      // Value is announced via Semantics; the dots are decorative (fill only).
      children.add(Semantics(
        label: '${l.guide_meta_difficulty} ${item.difficulty}/3',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l.guide_meta_difficulty} ',
                  style: Theme.of(context).textTheme.bodySmall),
              for (var i = 1; i <= 3; i++)
                Icon(Symbols.circle,
                    fill: i <= item.difficulty! ? 1 : 0,
                    size: 10,
                    color: color),
            ],
          ),
        ),
      ));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 16, runSpacing: 4, children: children);
  }
}

/// Section card — one card per template section, headed by an icon + title in
/// the category accent. Content is always visible (no accordion) so the whole
/// guide reads top-to-bottom in a single scroll.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = context.dimens;
    return Card(
      margin: EdgeInsets.fromLTRB(d.spaceMd, 0, d.spaceMd, d.spaceMd),
      child: Padding(
        padding: EdgeInsets.all(d.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                SizedBox(width: d.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: d.spaceSm),
            Divider(height: 1, thickness: 1, color: accent.withValues(alpha: 0.25)),
            SizedBox(height: d.spaceMd),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bullet row for the "good to know" section.
class _TipRow extends StatelessWidget {
  const _TipRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = context.dimens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: d.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: d.spaceSm),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: d.spaceSm + 2),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Korean sentence + its English meaning, tinted with the category accent.
/// Both lines always render — the Korean line is the one to show at a counter.
class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.phrase, required this.color});
  final GuidePhrase phrase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.dimens;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget line(String label, String value, TextStyle? style) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(label,
                  style: text.labelLarge?.copyWith(color: color)),
            ),
            SizedBox(width: d.spaceSm),
            Expanded(child: Text(value, style: style)),
          ],
        );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: d.spaceXs),
      child: Container(
        padding: EdgeInsets.all(d.spaceMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: d.brSm,
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(l.settings_language_ko, phrase.ko,
                text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: d.spaceSm),
            line(
              l.settings_language_en,
              phrase.en,
              text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.check_box_outline_blank,
              size: 20, color: scheme.onSurfaceVariant),
          SizedBox(width: context.dimens.spaceSm),
          Expanded(
              child:
                  Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text, required this.color});
  final int index;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text('$index',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: context.dimens.spaceSm),
          Expanded(
              child:
                  Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});
  final GuideLink link;

  Future<void> _open() async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: context.dimens.spaceSm,
      leading: Icon(Symbols.link, color: scheme.primary),
      title: Text(link.label(locale)),
      trailing: Tooltip(
        message: l.guide_link_external,
        child: Icon(Symbols.open_in_new,
            size: 18, color: scheme.onSurfaceVariant),
      ),
      onTap: _open,
    );
  }
}

class _RelatedLocationCard extends ConsumerWidget {
  const _RelatedLocationCard({required this.facilityId});
  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final async = ref.watch(facilityByIdProvider(facilityId));
    final facility = async.valueOrNull;
    if (facility == null) return const SizedBox.shrink();

    final color = context.catColors.forFacility(facility.category);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.spaceXs),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: context.dimens.brMd,
          // Single-id focus per the deep-link contract (UX §3).
          onTap: () => context.go('/map?focus=$facilityId'),
          child: Padding(
            padding: EdgeInsets.all(context.dimens.spaceMd),
            child: Row(
              children: [
                Icon(Symbols.location_on, color: color),
                SizedBox(width: context.dimens.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(facility.name(locale),
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        [facility.building(locale), l.guide_relatedLocation_hint]
                            .where((e) => e != null && e.trim().isNotEmpty)
                            .join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.dimens.spaceLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: context.dimens.brMd,
      ),
      child: Row(
        children: [
          Icon(Symbols.hourglass_top, color: scheme.onSurfaceVariant),
          SizedBox(width: context.dimens.spaceMd),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final d = context.dimens;
    return ListView(
      padding: EdgeInsets.all(d.spaceMd),
      children: const [
        SkeletonBox(height: 28, width: 200),
        SizedBox(height: 12),
        SkeletonBox(height: 16, width: 140),
        SizedBox(height: 24),
        SkeletonBox(height: 16, width: 100),
        SizedBox(height: 12),
        SkeletonBox(height: 80, radius: 12),
        SizedBox(height: 20),
        SkeletonBox(height: 16, width: 100),
        SizedBox(height: 12),
        SkeletonBox(height: 80, radius: 12),
      ],
    );
  }
}
