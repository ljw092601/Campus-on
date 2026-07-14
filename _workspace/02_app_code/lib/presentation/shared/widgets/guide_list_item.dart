import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/admin_guide.dart';
import '../../../domain/entities/favorite_ref.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';

/// Reusable guide row (UX doc §4.5 ListItem, guide variant): category icon+color,
/// title, one-line summary, trailing favorite star. Shared by S6 and S10.
class GuideListItem extends ConsumerWidget {
  const GuideListItem({super.key, required this.item, required this.onTap});

  final AdminGuideItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final color = context.catColors.forGuide(item.categoryId);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.valueOrNull
            ?.contains('${FavoriteType.guide.name}:${item.id}') ??
        false;
    final summary = item.summary(locale);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(item.categoryId.icon, color: color),
      ),
      title: Text(item.title(locale),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: summary != null
          ? Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: IconButton(
        icon: Icon(Symbols.star,
            fill: isFav ? 1 : 0,
            color: isFav ? Theme.of(context).colorScheme.primary : null),
        tooltip: isFav ? l.guide_favorite_remove : l.guide_favorite_add,
        onPressed: () => ref
            .read(favoritesProvider.notifier)
            .toggle(FavoriteType.guide, item.id),
      ),
    );
  }
}
