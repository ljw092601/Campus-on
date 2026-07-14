import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_guide.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/guide_providers.dart';
import '../shared/category_labels.dart';

/// S5 — Guide Categories (Guide tab root). The 6 categories are hardcoded (from
/// the enum) so the list always renders; only the per-category count badge is
/// data-driven and is hidden when it fails to load.
class GuideCategoryScreen extends ConsumerWidget {
  const GuideCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final counts = ref.watch(guideCategoryCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.guide_appbar_title),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            tooltip: l.search_appbar_hint,
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: GuideCategory.values.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final cat = GuideCategory.values[i];
          final count = counts.valueOrNull?[cat];
          return _CategoryRow(category: cat, count: count);
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, this.count});
  final GuideCategory category;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = context.catColors.forGuide(category);
    final count = this.count; // local promotes to non-null inside the guard
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(category.icon, color: color),
      ),
      title: Text(category.label(l)),
      subtitle: Text(category.summary(l),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            // Visual = compact number; screen reader hears "{count}건 / items".
            Semantics(
              label: l.guide_meta_itemCount(count),
              child: Text('$count',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
            ),
          SizedBox(width: context.dimens.spaceXs),
          const Icon(Symbols.chevron_right),
        ],
      ),
      onTap: () => context.go('/guide/category/${category.name}'),
    );
  }
}
