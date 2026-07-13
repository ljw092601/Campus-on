import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../shared/category_labels.dart';
import '../shared/widgets/state_views.dart';

/// S4 — Facility Detail. Info + inline mini-map link + bottom CTA (responsive
/// horizontal→vertical stack under large font scale).
class FacilityDetailScreen extends ConsumerWidget {
  const FacilityDetailScreen({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(facilityByIdProvider(facilityId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          _FavoriteButton(facilityId: facilityId),
        ],
      ),
      body: async.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => ErrorStateView(
          message: l.facility_detail_error,
          retryLabel: l.common_retry,
          onRetry: () => ref.invalidate(facilityByIdProvider(facilityId)),
        ),
        data: (facility) {
          if (facility == null) {
            return ErrorStateView(
              message: l.facility_detail_error,
              retryLabel: l.common_retry,
              onRetry: () => ref.invalidate(facilityByIdProvider(facilityId)),
            );
          }
          return _DetailBody(facility: facility);
        },
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.facilityId});
  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.valueOrNull
            ?.contains('${FavoriteType.facility.name}:$facilityId') ??
        false;
    return IconButton(
      icon: Icon(Symbols.star, fill: isFav ? 1 : 0),
      tooltip: isFav ? l.facility_favorite_remove : l.facility_favorite_add,
      onPressed: () => ref
          .read(favoritesProvider.notifier)
          .toggle(FavoriteType.facility, facilityId),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.facility});
  final Facility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final color = context.catColors.forFacility(facility.category);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;

    final address = facility.address(locale);
    final hours = facility.hours(locale);
    final description = facility.description(locale);
    final building = facility.building(locale);
    final secondaryName =
        locale.languageCode == 'ko' ? facility.nameEn : facility.nameKo;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: d.spaceLg),
            children: [
              // Header banner: image or category-color fallback (Partial state).
              _Banner(facility: facility, color: color),
              Padding(
                padding: EdgeInsets.all(d.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name(locale),
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: d.spaceXs),
                    Row(
                      children: [
                        if (secondaryName.trim().isNotEmpty)
                          Flexible(
                            child: Text(secondaryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant)),
                          ),
                        SizedBox(width: d.spaceSm),
                        _CategoryBadge(
                            label: facility.category.label(l), color: color),
                      ],
                    ),
                    SizedBox(height: d.spaceMd),
                    _MiniMap(facility: facility, color: color),
                    SizedBox(height: d.spaceMd),
                    if (address != null || building != null)
                      _InfoRow(
                        icon: Symbols.location_on,
                        text: [building, address]
                            .where((e) => e != null && e.trim().isNotEmpty)
                            .join(' · '),
                      ),
                    if (hours != null)
                      _InfoRow(icon: Symbols.schedule, text: hours),
                    if (facility.phone != null)
                      _InfoRow(icon: Symbols.call, text: facility.phone!),
                    if (description != null) ...[
                      SizedBox(height: d.spaceMd),
                      Text(l.facility_section_about,
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: d.spaceXs),
                      Text(description,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomCta(facility: facility),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.facility, required this.color});
  final Facility facility;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: facility.imageUrl != null
          ? Image.network(
              facility.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() => Container(
        color: color.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Icon(facility.category.icon, size: 64, color: color),
      );
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.facility, required this.color});
  final Facility facility;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Inline mini-map placeholder → tapping deep-links to the full map (S2).
    // A Kakao static image can replace this container in week 3.
    return InkWell(
      borderRadius: context.dimens.brMd,
      onTap: () => context.go('/map?focus=${facility.id}'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: context.dimens.brMd,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Icon(Symbols.location_on, color: color, size: 40),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          SizedBox(width: context.dimens.spaceSm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: color)),
    );
  }
}

/// Bottom-fixed CTA. Horizontal 2-buttons by default; switches to a vertical
/// stack when the font scale is large or width is tight (UX doc S4 A11y rule).
class _BottomCta extends ConsumerWidget {
  const _BottomCta({required this.facility});
  final Facility facility;

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final hasPhone = facility.phone != null;

    final mapBtn = FilledButton.icon(
      onPressed: () => context.go('/map?focus=${facility.id}'),
      icon: const Icon(Symbols.map),
      label: Text(l.facility_action_viewOnMap),
    );
    final callBtn = OutlinedButton.icon(
      onPressed: hasPhone ? () => _call(facility.phone!) : null,
      icon: const Icon(Symbols.call),
      label: Text(l.facility_action_call),
    );

    return SafeArea(
      minimum: EdgeInsets.all(context.dimens.spaceMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = scale >= 1.3 || constraints.maxWidth < 340;
          if (!hasPhone) {
            return SizedBox(
                width: double.infinity, height: 48, child: mapBtn);
          }
          if (stack) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: double.infinity, height: 48, child: mapBtn),
                SizedBox(height: context.dimens.spaceSm),
                SizedBox(width: double.infinity, height: 48, child: callBtn),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: SizedBox(height: 48, child: mapBtn)),
              SizedBox(width: context.dimens.spaceMd),
              Expanded(child: SizedBox(height: 48, child: callBtn)),
            ],
          );
        },
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
        SkeletonBox(height: 160, radius: 12),
        SizedBox(height: 16),
        SkeletonBox(height: 24, width: 180),
        SizedBox(height: 8),
        SkeletonBox(height: 16, width: 120),
        SizedBox(height: 16),
        SkeletonBox(height: 120, radius: 12),
      ],
    );
  }
}
