import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';
import '../../shared/category_labels.dart';
import '../../shared/widgets/ui_kit.dart';
import '../../../core/layout/flexible_text_layout.dart';

/// Campus switcher for the map (S2). The three campuses are km apart, so the
/// map shows one at a time; switching re-filters markers and moves the camera
/// (handled by CampusMapView reacting to [mapCampusProvider]).
class CampusSelector extends ConsumerWidget {
  const CampusSelector({super.key, this.onSelected});

  final ValueChanged<Campus>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final campus = ref.watch(mapCampusProvider);

    final padding = EdgeInsets.fromLTRB(context.dimens.spaceMd,
        context.dimens.spaceSm, context.dimens.spaceMd, 0);

    // The map screen passes [onSelected] so it can sync its own state
    // (camera, selection) with the switch (audit campus selector sync).
    void select(Campus c) {
      if (onSelected != null) {
        onSelected!(c);
      } else {
        ref.read(mapCampusProvider.notifier).state = c;
      }
    }

    // Three names do not fit one row when there is little of it to go round:
    // past the default text size at any width (감사 05/037 SF-1), and on a
    // 320dp screen even at the default size — `Seunghak` alone wants more than
    // a third of it. A scrollable chip row keeps every name whole and
    // reachable; the pill segmented control stays where it genuinely fits.
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
      // Pill segmented control (DONG-A-MATE mockup). Its labels are one line
      // with an ellipsis — a safety net for in-between sizes; past the default
      // text size the chip row above takes over.
      child: PillSegmented<Campus>(
        values: Campus.values,
        selected: campus,
        labelOf: (c) => c.label(l),
        onChanged: select,
      ),
    );
  }
}
