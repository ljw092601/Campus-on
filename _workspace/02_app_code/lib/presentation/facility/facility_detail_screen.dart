import '../shared/favorite_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/layout/flexible_text_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../shared/category_labels.dart';
import '../shared/external_links.dart';
import '../shared/map_links.dart';
import '../shared/widgets/floor_accordion.dart';
import '../shared/widgets/facility_list_item.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';
import '../shared/widgets/ui_kit.dart';

/// S4 — Facility Detail. Tinted header card (name, tags, call action), info
/// rows, floor guide and a bottom full-width "view on map" CTA.
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
          message: readErrorMessage(e, l, l.facility_detail_error),
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
      icon: Icon(Symbols.star,
          fill: isFav ? 1 : 0, color: isFav ? AppColors.yellow : null),
      tooltip: isFav ? l.facility_favorite_remove : l.facility_favorite_add,
      onPressed: () =>
          toggleFavorite(context, ref, FavoriteType.facility, facilityId),
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
    final d = context.dimens;

    final address = facility.address(locale);
    final hours = facility.hours(locale);
    final description = facility.description(locale);
    final building = facility.building(locale);
    final location = [building, address]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' · ');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                EdgeInsets.fromLTRB(d.spaceMd, d.spaceXs, d.spaceMd, d.spaceLg),
            children: [
              _HeaderCard(facility: facility),
              if (location.isNotEmpty ||
                  hours != null ||
                  facility.phone != null) ...[
                SizedBox(height: d.spaceMd),
                GroupCard(
                  children: [
                    if (location.isNotEmpty)
                      _InfoRow(icon: Symbols.location_on, text: location),
                    if (hours != null)
                      _InfoRow(icon: Symbols.schedule, text: hours),
                    if (facility.phone != null)
                      _InfoRow(icon: Symbols.call, text: facility.phone!),
                  ],
                ),
              ],
              if (description != null) ...[
                SizedBox(height: d.spaceLg),
                _SectionTitle(l.facility_section_about),
                GroupCard(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(description,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ],
              if (facility.hasFloorInfo) ...[
                SizedBox(height: d.spaceLg),
                FloorSectionHeader(facilityId: facility.id),
                FloorAccordion(facilityId: facility.id),
              ],
            ],
          ),
        ),
        _BottomCta(facility: facility),
      ],
    );
  }
}

/// Light tinted header card: white plate with the big category icon (or the
/// facility photo), navy name, secondary-language name, category + campus
/// tags and the quick action row.
class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.facility});
  final Facility facility;

  /// Shared launcher: shows the "couldn't open" snackbar when no dialer can
  /// take the number (audit L-8) instead of doing nothing.
  Future<void> _call(BuildContext context, String phone) =>
      openExternal(context, Uri(scheme: 'tel', path: phone));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final tone = facility.category.tone;
    final secondaryName =
        locale.languageCode == 'ko' ? facility.nameEn : facility.nameKo;
    final campus = facility.campus;

    final icon =
        Icon(facility.category.icon, size: 44, color: tone.fg(context));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: facility.imageUrl != null
                    ? Image.network(
                        facility.imageUrl!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => icon,
                      )
                    : icon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name(locale),
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: headingColor(context),
                      ),
                    ),
                    if (secondaryName.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      // The name in the other language is how a student
                      // matches the building sign (a Chinese or Vietnamese
                      // reader still sees the Korean sign text to show
                      // someone); clipping it defeats the purpose, so it
                      // wraps as far as it needs to.
                      Text(
                        secondaryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Text(
                            facility.category.label(l),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: tone.fg(context),
                            ),
                          ),
                        ),
                        if (campus != null)
                          _CampusPill(l.map_campus_full(campus.label(l))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (facility.phone != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _call(context, facility.phone!),
                  icon: const Icon(Symbols.call, size: 18),
                  label: Text(l.facility_action_call),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Campus tag in the header card — neutral pill that stays readable on the
/// tinted card background.
class _CampusPill extends StatelessWidget {
  const _CampusPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        // Romanised campus names ('Seunghak Campus') are wider than the header
        // column on a 320dp phone / at large text; wrap there instead of
        // clipping the tail.
        maxLines: prefersFlexibleLayout(context) ? null : 1,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: headingColor(context),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconTile(icon: icon, tone: Tone.blue, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Bottom-fixed full-width "지도에서 보기" CTA (56 tall, soft shadow).
class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.facility});
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // A fixed height clipped the label at large text; the button grows with
    // it instead (capped, so it cannot swallow the screen).
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final btnHeight = 56 * scale.clamp(1.0, 2.0);
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(context.dimens.spaceMd, 8,
          context.dimens.spaceMd, context.dimens.spaceMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: btnHeight,
          child: FilledButton.icon(
            onPressed: () => context.go(mapFocusLink(facility.id)),
            icon: const Icon(Symbols.location_on, size: 22),
            label: Text(l.facility_action_viewOnMap),
            style: FilledButton.styleFrom(
              textStyle:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
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
        SkeletonBox(height: 180, radius: 28),
        SizedBox(height: 16),
        SkeletonBox(height: 24, width: 180),
        SizedBox(height: 12),
        SkeletonBox(height: 240, radius: 24),
      ],
    );
  }
}
