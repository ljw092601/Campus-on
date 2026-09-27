import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/admin_guide.dart';
import '../../../domain/entities/favorite_ref.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import 'ui_kit.dart';

/// Mockup accent tone + hub glyph per guide category (DONG-A-MATE UI):
/// immigration blue, housing yellow, living green, health coral, school
/// purple, emergency red. [GuideCategory.icon] stays the item-level default.
extension GuideCategoryTone on GuideCategory {
  Tone get tone => switch (this) {
        GuideCategory.immigration => Tone.blue,
        GuideCategory.housing => Tone.yellow,
        GuideCategory.living => Tone.green,
        GuideCategory.health => Tone.coral,
        GuideCategory.school => Tone.purple,
        GuideCategory.emergency => Tone.red,
      };

  IconData get hubIcon => switch (this) {
        GuideCategory.immigration => Symbols.badge,
        GuideCategory.housing => Symbols.home,
        GuideCategory.living => Symbols.account_balance,
        GuideCategory.health => Symbols.add_box,
        GuideCategory.school => Symbols.school,
        GuideCategory.emergency => Symbols.notifications,
      };
}

/// Reusable guide row (UX doc §4.5 ListItem, guide variant): item/category icon
/// on a tinted tile in the category tone, bold title, one-line summary,
/// trailing favorite star. Shared by S6 and S10; meant to sit inside a
/// [GroupCard].
class GuideListItem extends ConsumerWidget {
  const GuideListItem({super.key, required this.item, required this.onTap});

  final AdminGuideItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    // Narrow the subscription: only this row's favorite flag, so toggling one
    // item doesn't rebuild the whole list (QA P-1).
    final favKey = '${FavoriteType.guide.name}:${item.id}';
    final isFav = ref.watch(favoritesProvider
        .select((v) => v.valueOrNull?.contains(favKey) ?? false));
    final summary = item.summary(locale);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      minVerticalPadding: 10,
      leading: IconTile(icon: item.icon, tone: item.categoryId.tone, size: 44),
      title: Text(item.title(locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          )),
      subtitle: summary != null
          ? Text(summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant))
          : null,
      trailing: IconButton(
        icon: Icon(Symbols.star,
            fill: isFav ? 1 : 0,
            color: isFav ? AppColors.yellow : scheme.onSurfaceVariant),
        tooltip: isFav ? l.guide_favorite_remove : l.guide_favorite_add,
        onPressed: () => ref
            .read(favoritesProvider.notifier)
            .toggle(FavoriteType.guide, item.id),
      ),
    );
  }
}
