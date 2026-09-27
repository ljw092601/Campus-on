import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';
import '../../shared/category_labels.dart';
import '../../../core/layout/flexible_text_layout.dart';

/// Campus switcher for the map (S2). The three campuses are km apart, so the
/// map shows one at a time; switching re-filters markers and moves the camera
/// (handled by CampusMapView reacting to [mapCampusProvider]).
class CampusSelector extends ConsumerWidget {
  const CampusSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final campus = ref.watch(mapCampusProvider);

    final padding = EdgeInsets.fromLTRB(
        context.dimens.spaceMd, context.dimens.spaceSm, context.dimens.spaceMd, 0);

    void select(Campus c) =>
        ref.read(mapCampusProvider.notifier).state = c;

    // Three names do not fit one row when there is little of it to go round:
    // past the default text size at any width (감사 05/037 SF-1), and on a
    // 320dp screen even at the default size — `Seunghak` alone wants more than
    // a third of it. A scrollable chip row keeps every name whole and
    // reachable; the segmented button stays where it genuinely fits.
    if (prefersFlexibleLayout(context)) {
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in Campus.values) ...[
                ChoiceChip(
                  label: Text(c.label(l)),
                  selected: campus == c,
                  onSelected: (_) => select(c),
                ),
                if (c != Campus.values.last)
                  SizedBox(width: context.dimens.spaceSm),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: SegmentedButton<Campus>(
        segments: [
          for (final c in Campus.values)
            ButtonSegment(
              value: c,
              // At ordinary sizes the names fit; the ellipsis is a safety net for
              // the sizes in between, not the answer at 200 % (see above).
              label: Text(
                c.label(l),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              tooltip: c.label(l),
            ),
        ],
        selected: {campus},
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (selection) => select(selection.first),
      ),
    );
  }
}
