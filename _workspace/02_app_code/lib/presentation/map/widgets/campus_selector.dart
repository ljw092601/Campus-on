import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';
import '../../shared/category_labels.dart';
import '../../shared/widgets/ui_kit.dart';

/// Campus switcher for the map (S2). The three campuses are km apart, so the
/// map shows one at a time; switching re-filters markers and moves the camera
/// (handled by CampusMapView reacting to [mapCampusProvider]).
class CampusSelector extends ConsumerWidget {
  const CampusSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final campus = ref.watch(mapCampusProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dimens.spaceMd,
          context.dimens.spaceSm, context.dimens.spaceMd, 0),
      child: PillSegmented<Campus>(
        values: Campus.values,
        selected: campus,
        labelOf: (c) => c.label(l),
        onChanged: (c) => ref.read(mapCampusProvider.notifier).state = c,
      ),
    );
  }
}
