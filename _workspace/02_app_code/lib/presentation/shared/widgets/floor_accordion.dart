import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';
import 'ui_kit.dart';

/// Floor-by-floor accordion for one building (map Peek sheet + S4 detail).
///
/// Self-loading via [buildingFloorsProvider]; renders shrink-wrapped so it can
/// sit inside any parent scrollable. Floors keep source order (deepest basement
/// → rooftop). Room names are Korean-only for now (plan §9).
///
/// Styled as a [GroupCard]: each row is a navy floor pill ("B1F"), the bold
/// room count and a gray chevron.
class FloorAccordion extends ConsumerWidget {
  const FloorAccordion(
      {super.key, required this.facilityId, this.expandedFloor});

  final String facilityId;

  /// Floor label (e.g. "3F") whose tile starts expanded — used by the
  /// classroom-search deep link so the target floor is open on arrival.
  final String? expandedFloor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;
    final async = ref.watch(buildingFloorsProvider(facilityId));

    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: d.spaceMd),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.symmetric(vertical: d.spaceSm),
        child: Row(
          children: [
            Expanded(
              child: Text(l.facility_floors_error,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.error)),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(buildingFloorsProvider(facilityId)),
              child: Text(l.common_retry),
            ),
          ],
        ),
      ),
      data: (building) {
        if (building == null || building.floors.isEmpty) {
          return const SizedBox.shrink();
        }
        return GroupCard(
          children: [
            for (final floor in building.floors)
              ExpansionTile(
                initiallyExpanded: floor.floor == expandedFloor,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: scheme.onSurfaceVariant,
                collapsedIconColor: scheme.onSurfaceVariant,
                title: Row(
                  children: [
                    ToneBadge(
                      floor.floor,
                      tone: Tone.navy,
                      minWidth: 48,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l.facility_floors_roomCount(floor.rooms.length),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      floor.rooms.join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Total room count across all floors of [facilityId] (the "총 87곳" pill),
/// null while loading / without floor data.
int? floorRoomTotal(WidgetRef ref, String facilityId) {
  final building = ref.watch(buildingFloorsProvider(facilityId)).valueOrNull;
  if (building == null || building.floors.isEmpty) return null;
  return building.floors.fold<int>(0, (n, f) => n + f.rooms.length);
}

/// "층별 안내" section header with the neutral total-count pill on the right.
class FloorSectionHeader extends ConsumerWidget {
  const FloorSectionHeader({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final total = floorRoomTotal(ref, facilityId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l.facility_floors_title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
            ),
          ),
          if (total != null)
            ToneBadge(l.facility_floors_total(total), fontSize: 13),
        ],
      ),
    );
  }
}
