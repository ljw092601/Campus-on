import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/facility_providers.dart';
import '../category_labels.dart';
import 'category_chip.dart';

/// Horizontal scrolling filter bar: [All] + 6 facility categories.
/// Shared by S2 (map) and S3 (list) — both read/write
/// [facilityCategoryFilterProvider] so the selection stays in sync.
class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selected = ref.watch(facilityCategoryFilterProvider);
    final controller = ref.read(facilityCategoryFilterProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.dimens.spaceMd),
        children: [
          Padding(
            padding: EdgeInsets.only(right: context.dimens.spaceSm),
            child: CategoryChip(
              label: l.common_all,
              icon: Symbols.apps,
              color: scheme.primary,
              selected: selected == null,
              onTap: () => controller.state = null,
            ),
          ),
          for (final cat in FacilityCategory.values)
            Padding(
              padding: EdgeInsets.only(right: context.dimens.spaceSm),
              child: CategoryChip(
                label: cat.label(l),
                icon: cat.icon,
                color: context.catColors.forFacility(cat),
                selected: selected == cat,
                onTap: () => controller.state =
                    (selected == cat) ? null : cat,
              ),
            ),
        ],
      ),
    );
  }
}
