import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/nearby_place.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../classroom/widgets/room_location_card.dart';
import '../../providers/locale_provider.dart';
import '../../shared/category_labels.dart';
import '../../shared/widgets/floor_accordion.dart';

/// Bottom Peek sheet shown when a marker is tapped or via deep link (S2).
///
/// Rendered inside a `DraggableScrollableSheet` (see map_screen.dart):
/// collapsed it shows name · category and a "View detail" CTA → S4; dragging
/// up reveals the building's floor-by-floor guide. [scrollController] MUST be
/// the sheet-provided controller and everything lives inside the one ListView —
/// that's what lets a drag anywhere on the sheet resize it.
class PeekSheet extends ConsumerWidget {
  const PeekSheet({
    super.key,
    required this.facility,
    required this.onViewDetail,
    required this.scrollController,
    this.expandedFloor,
    this.roomCode,
    this.roomPlanCode,
    this.onClose,
  });

  final Facility facility;
  final VoidCallback onViewDetail;
  final ScrollController scrollController;

  /// Explicit dismiss (audit M-8). Null hides the close button.
  final VoidCallback? onClose;

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
    final color = context.catColors.forFacility(facility.category);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;

    return _PeekShell(
      scrollController: scrollController,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(facility.category.icon, color: color),
            ),
            SizedBox(width: d.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facility.name(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(facility.category.label(l),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onViewDetail,
              child: Text(l.map_peek_viewDetail),
            ),
            if (onClose != null) _CloseButton(onPressed: onClose!),
          ],
        ),
        if (roomCode != null) ...[
          SizedBox(height: d.spaceMd),
          RoomLocationCard(
              facility: facility, roomCode: roomCode!, planCode: roomPlanCode),
        ],
        if (facility.hasFloorInfo) ...[
          SizedBox(height: d.spaceMd),
          Text(l.facility_floors_title,
              style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: d.spaceXs),
          FloorAccordion(
              facilityId: facility.id, expandedFloor: expandedFloor),
        ],
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
    this.onClose,
  });

  final NearbyPlace place;
  final VoidCallback? onOpen;

  /// Explicit dismiss (audit M-8). Null hides the close button.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = context.catColors.forFacility(FacilityCategory.etc);
    final subtitle = [
      place.displayAddress,
      if (place.distanceMeters != null)
        l.facility_meta_distance(place.distanceMeters!),
    ].whereType<String>().join(' · ');

    return _PeekShell(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Symbols.storefront, color: color),
            ),
            SizedBox(width: context.dimens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onOpen,
              child: Text(l.map_peek_openPlace),
            ),
            if (onClose != null) _CloseButton(onPressed: onClose!),
          ],
        ),
      ],
    );
  }
}

/// Compact "×" at the end of the header row. Keeps the 48dp tap target but
/// drops the extra horizontal padding so the title keeps its room on narrow
/// phones.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(left: context.dimens.spaceXs),
      child: IconButton(
        icon: const Icon(Symbols.close),
        tooltip: l.common_close,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      ),
    );
  }
}

/// Shared sheet chrome (rounded surface + grab handle) so both peek variants
/// stay pixel-identical. With a [scrollController] the content lives in one
/// ListView (required by `DraggableScrollableSheet` so a drag anywhere resizes
/// the sheet); without one it collapses to an intrinsic-height Column, which a
/// plain `Positioned` bottom sheet needs.
class _PeekShell extends StatelessWidget {
  const _PeekShell({required this.children, this.scrollController});

  final List<Widget> children;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;
    final handle = Center(
      child: Container(
        width: 36,
        height: 4,
        margin: EdgeInsets.only(bottom: d.spaceSm),
        decoration: BoxDecoration(
          color: scheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    final padding =
        EdgeInsets.fromLTRB(d.spaceMd, d.spaceSm, d.spaceMd, d.spaceMd);

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(top: Radius.circular(d.radiusLg)),
      elevation: 3,
      child: SafeArea(
        top: false,
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
    );
  }
}
