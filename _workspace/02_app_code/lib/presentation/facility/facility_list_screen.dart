import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../shared/widgets/category_filter_bar.dart';
import '../shared/widgets/facility_list_item.dart';
import '../shared/widgets/state_views.dart';

/// S3 — Facility List. Category filter + list; toggles with the map (S2).
class FacilityListScreen extends ConsumerWidget {
  const FacilityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filtered = ref.watch(filteredFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.list_appbar_title),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            tooltip: l.search_appbar_hint,
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Symbols.map),
            tooltip: l.map_toggle_toMap,
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
      body: Column(
        children: [
          const CategoryFilterBar(),
          Expanded(
            child: filtered.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                message: l.list_error_loadFailed,
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(allFacilitiesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyStateView(
                    icon: Symbols.search_off,
                    title: l.list_empty_noResult,
                    actionLabel: l.common_resetFilter,
                    onAction: () =>
                        ref.read(facilityCategoryFilterProvider.notifier).state =
                            null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allFacilitiesProvider),
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => FacilityListItem(
                      facility: list[i],
                      onTap: () =>
                          context.go('/map/facility/${list[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
