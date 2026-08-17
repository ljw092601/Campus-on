import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
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
  });

  final Facility facility;
  final VoidCallback onViewDetail;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final color = context.catColors.forFacility(facility.category);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(top: Radius.circular(d.radiusLg)),
      elevation: 3,
      child: SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding:
              EdgeInsets.fromLTRB(d.spaceMd, d.spaceSm, d.spaceMd, d.spaceMd),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: d.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
              ],
            ),
            if (facility.hasFloorInfo) ...[
              SizedBox(height: d.spaceMd),
              Text(l.facility_floors_title,
                  style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: d.spaceXs),
              FloorAccordion(facilityId: facility.id),
            ],
          ],
        ),
      ),
    );
  }
}
