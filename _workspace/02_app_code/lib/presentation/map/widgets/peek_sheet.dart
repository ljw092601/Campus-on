import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/favorite_ref.dart';
import '../../../domain/entities/nearby_place.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../classroom/widgets/room_location_card.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../../shared/category_labels.dart';
import '../../shared/widgets/facility_list_item.dart';
import '../../shared/widgets/floor_accordion.dart';
import '../../shared/widgets/ui_kit.dart';

/// Bottom Peek sheet shown when a marker is tapped or via deep link (S2).
///
/// Rendered inside a `DraggableScrollableSheet` (see map_screen.dart):
/// collapsed it shows name · category, a "View detail" CTA → S4 and quick
/// actions; dragging up reveals the building's floor-by-floor guide.
/// [scrollController] MUST be the sheet-provided controller and everything
/// lives inside the one ListView — that's what lets a drag anywhere on the
/// sheet resize it.
class PeekSheet extends ConsumerWidget {
  const PeekSheet({
    super.key,
    required this.facility,
    required this.onViewDetail,
    required this.scrollController,
    this.onShowFloors,
    this.expandedFloor,
    this.roomCode,
    this.roomPlanCode,
  });

  final Facility facility;
  final VoidCallback onViewDetail;
  final ScrollController scrollController;

  /// Expands the sheet to the floor guide ("층별 안내" action). Null hides
  /// the action (building without floor info).
  final VoidCallback? onShowFloors;

  /// Floor label to open pre-expanded (classroom search deep link).
  final String? expandedFloor;

  /// Searched room code (classroom search deep link): shows its floor plan
  /// with a red dot above the floor guide.
  final String? roomCode;

  /// Floor-plan building code for [roomCode] when it differs from the
  /// building's own code (a B04 wing: "B04A").
  final String? roomPlanCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final d = context.dimens;
    final tone = facility.category.tone;
    final favKey = '${FavoriteType.facility.name}:${facility.id}';
    final isFav = ref.watch(favoritesProvider
        .select((v) => v.valueOrNull?.contains(favKey) ?? false));
    final campus = facility.campus;

    return _PeekShell(
      scrollController: scrollController,
      children: [
        _PeekHeader(
          icon: facility.category.icon,
          tone: tone,
          title: facility.name(locale),
          badge: facility.category.label(l),
          subtitle: campus == null ? null : l.map_campus_full(campus.label(l)),
          ctaLabel: l.map_peek_viewDetail,
          onCta: onViewDetail,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onShowFloors != null)
              _PeekAction(
                icon: Symbols.format_list_bulleted,
                label: l.facility_floors_title,
                onPressed: onShowFloors,
              ),
            Semantics(
              selected: isFav,
              child: _PeekAction(
                icon: Symbols.star,
                filled: isFav,
                label: l.favorites_title,
                tooltip: isFav
                    ? l.facility_favorite_remove
                    : l.facility_favorite_add,
                onPressed: () => ref
                    .read(favoritesProvider.notifier)
                    .toggle(FavoriteType.facility, facility.id),
              ),
            ),
          ],
        ),
        if (roomCode != null) ...[
          SizedBox(height: d.spaceLg),
          RoomLocationCard(
              facility: facility, roomCode: roomCode!, planCode: roomPlanCode),
        ],
        if (facility.hasFloorInfo) ...[
          SizedBox(height: d.spaceLg),
          FloorSectionHeader(facilityId: facility.id),
          FloorAccordion(facilityId: facility.id, expandedFloor: expandedFloor),
        ],
        // Keeps the last floor row clear of the sheet's rounded bottom edge.
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Same Peek sheet for an off-campus search result (S2 `?nearby=`): the place
/// has no detail screen of its own, so the CTA opens its Kakao Map page.
class PlacePeekSheet extends StatelessWidget {
  const PlacePeekSheet({
    super.key,
    required this.place,
    required this.onOpen,
  });

  final NearbyPlace place;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subtitle = [
      place.displayAddress,
      if (place.distanceMeters != null)
        l.facility_meta_distance(place.distanceMeters!),
    ].whereType<String>().join(' · ');

    return _PeekShell(
      children: [
        _PeekHeader(
          icon: Symbols.storefront,
          tone: Tone.neutral,
          title: place.name,
          subtitle: subtitle.isEmpty ? null : subtitle,
          ctaLabel: l.map_peek_openPlace,
          onCta: onOpen,
        ),
      ],
    );
  }
}

/// Icon tile · bold name · badge + gray meta · blue stadium CTA.
class _PeekHeader extends StatelessWidget {
  const _PeekHeader({
    required this.icon,
    required this.tone,
    required this.title,
    required this.ctaLabel,
    required this.onCta,
    this.badge,
    this.subtitle,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String? badge;
  final String? subtitle;
  final String ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconTile(icon: icon, tone: tone, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: headingColor(context),
                ),
              ),
              if (badge != null || subtitle != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (badge != null) ...[
                      ToneBadge(badge!, tone: tone, fontSize: 12),
                      const SizedBox(width: 8),
                    ],
                    if (subtitle != null)
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onCta,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          child: Text(ctaLabel),
        ),
      ],
    );
  }
}

/// Outlined stadium quick action under the header ("층별 안내", "즐겨찾기").
class _PeekAction extends StatelessWidget {
  const _PeekAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon,
          size: 18,
          fill: filled ? 1 : 0,
          color: filled ? AppColors.yellow : scheme.onSurfaceVariant),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: scheme.onSurface,
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// Shared sheet chrome (floating white r28 card + grab handle) so both peek
/// variants stay pixel-identical. With a [scrollController] the content lives
/// in one ListView (required by `DraggableScrollableSheet` so a drag anywhere
/// resizes the sheet); without one it collapses to an intrinsic-height
/// Column, which a plain `Positioned` bottom sheet needs.
class _PeekShell extends StatelessWidget {
  const _PeekShell({required this.children, this.scrollController});

  final List<Widget> children;
  final ScrollController? scrollController;

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final handle = Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: scheme.outlineVariant,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    const padding = EdgeInsets.fromLTRB(18, 10, 18, 18);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1B3A7A).withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: dark
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none,
          ),
          child: scrollController != null
              ? ListView(
                  controller: scrollController,
                  padding: padding,
                  children: [handle, ...children],
                )
              : Padding(
                  padding: padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [handle, ...children],
                  ),
                ),
        ),
      ),
    );
  }
}
