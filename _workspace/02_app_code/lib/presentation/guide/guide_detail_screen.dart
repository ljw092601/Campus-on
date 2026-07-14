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

/// S7 — Guide Detail. Fixed 4-section template (overview → checklist → steps →
/// links/locations) rendered as expandable panels. Coming-soon items show the
/// standard placeholder (plus any related-location card so the deep link works).
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
    final color = context.catColors.forGuide(item.categoryId);
    final d = context.dimens;

    final overview = item.overview(locale);
    final checklist = item.checklist(locale);
    final steps = item.steps(locale);
    final hasLinksOrLocations =
        item.links.isNotEmpty || item.relatedFacilityIds.isNotEmpty;

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
              _MetaRow(item: item, color: color),
            ],
          ),
        ),
        SizedBox(height: d.spaceSm),

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
              child: Text(overview,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          if (checklist.isNotEmpty)
            _Section(
              title: l.guide_section_checklist,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in checklist) _ChecklistRow(text: c),
                ],
              ),
            ),
          if (steps.isNotEmpty)
            _Section(
              title: l.guide_section_steps,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    _StepRow(index: i + 1, text: steps[i], color: color),
                ],
              ),
            ),
        ],

        // Links + related locations (shown even for coming-soon items).
        if (hasLinksOrLocations)
          _Section(
            title: l.guide_section_links,
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

/// Expandable section panel (UX §4.5 SectionAccordion), expanded by default.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.symmetric(horizontal: context.dimens.spaceMd),
        childrenPadding: EdgeInsets.fromLTRB(
            context.dimens.spaceMd, 0, context.dimens.spaceMd, context.dimens.spaceMd),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [child],
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
