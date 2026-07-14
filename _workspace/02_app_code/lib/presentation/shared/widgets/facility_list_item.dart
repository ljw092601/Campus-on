import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/favorite_ref.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../category_labels.dart';

/// Reusable facility row (UX doc §4.5 ListItem, facility variant).
/// leading category icon+color, title, "category · Xm", trailing favorite star.
class FacilityListItem extends ConsumerWidget {
  const FacilityListItem({
    super.key,
    required this.facility,
    required this.onTap,
    this.distanceMeters,
  });

  final Facility facility;
  final VoidCallback onTap;
  final int? distanceMeters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final color = context.catColors.forFacility(facility.category);
    // Narrow the subscription to this row's favorite flag only (QA P-1).
    final favKey = '${FavoriteType.facility.name}:${facility.id}';
    final isFav = ref.watch(favoritesProvider
        .select((v) => v.valueOrNull?.contains(favKey) ?? false));

    final subtitleParts = <String>[facility.category.label(l)];
    if (distanceMeters != null) {
      subtitleParts.add(l.facility_meta_distance(distanceMeters!));
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(facility.category.icon, color: color),
      ),
      title: Text(facility.name(locale),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitleParts.join(' · '),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: Icon(Symbols.star,
            fill: isFav ? 1 : 0,
            color: isFav ? Theme.of(context).colorScheme.primary : null),
        tooltip:
            isFav ? l.facility_favorite_remove : l.facility_favorite_add,
        onPressed: () => ref
            .read(favoritesProvider.notifier)
            .toggle(FavoriteType.facility, facility.id),
      ),
    );
  }
}
