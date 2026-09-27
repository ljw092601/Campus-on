import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/admin_guide.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/guide_providers.dart';
import '../shared/category_labels.dart';
import '../shared/widgets/guide_list_item.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/ui_kit.dart';

/// S6 — Guide Item List. Items within one category (published first). Tapping a
/// row opens the S7 detail; the star toggles a local favorite.
class GuideItemListScreen extends ConsumerWidget {
  const GuideItemListScreen({super.key, required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(guideItemsByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(category.label(l))),
      body: async.when(
        loading: () => const SkeletonList(rows: 4),
        error: (e, _) => ErrorStateView(
          message: l.guide_list_error,
          retryLabel: l.common_retry,
          onRetry: () => ref.invalidate(guideItemsByCategoryProvider(category)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateView(
              icon: Symbols.checklist,
              title: l.guide_list_empty_title,
            );
          }
          // One grouped white card (DONG-A-MATE mockup), rows split by inset
          // dividers.
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GroupCard(
                children: [
                  for (final item in items)
                    GuideListItem(
                      item: item,
                      onTap: () => context.go('/guide/item/${item.id}'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
