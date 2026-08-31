import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';

/// Floor-by-floor accordion for one building (map Peek sheet + S4 detail).
///
/// Self-loading via [buildingFloorsProvider]; renders shrink-wrapped so it can
/// sit inside any parent scrollable. Floors keep source order (deepest basement
/// → rooftop). Room names are Korean-only for now (plan §9).
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final floor in building.floors)
              ExpansionTile(
                initiallyExpanded: floor.floor == expandedFloor,
                tilePadding: EdgeInsets.symmetric(horizontal: d.spaceSm),
                childrenPadding: EdgeInsets.fromLTRB(
                    d.spaceMd, 0, d.spaceMd, d.spaceMd),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 48),
                      padding: EdgeInsets.symmetric(
                          horizontal: d.spaceSm, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(d.radiusSm),
                      ),
                      child: Text(
                        floor.floor,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: scheme.onSecondaryContainer),
                      ),
                    ),
                    SizedBox(width: d.spaceSm),
                    Expanded(
                      child: Text(
                        l.facility_floors_roomCount(floor.rooms.length),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      floor.rooms.join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium,
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
