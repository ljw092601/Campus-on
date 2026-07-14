import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/favorites_provider.dart';
import '../shared/widgets/facility_list_item.dart';
import '../shared/widgets/guide_list_item.dart';
import '../shared/widgets/state_views.dart';

/// S10 — Favorites. Facility/guide segments over locally-saved items, with
/// swipe-to-delete. Data is fully local (SharedPreferences), so no error state.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum _Segment { facility, guide }

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  _Segment _segment = _Segment.facility;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.favorites_title)),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.dimens.spaceMd),
            child: SegmentedButton<_Segment>(
              segments: [
                ButtonSegment(
                    value: _Segment.facility,
                    label: Text(l.favorites_segment_facility)),
                ButtonSegment(
                    value: _Segment.guide,
                    label: Text(l.favorites_segment_guide)),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(
            child: _segment == _Segment.facility
                ? const _FacilityFavorites()
                : const _GuideFavorites(),
          ),
        ],
      ),
    );
  }
}

class _FacilityFavorites extends ConsumerWidget {
  const _FacilityFavorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(favoriteFacilitiesProvider);

    return async.when(
      loading: () => const SkeletonList(rows: 4),
      error: (e, _) => EmptyStateView(
          icon: Symbols.star, title: l.favorites_empty_facility),
      data: (facilities) {
        if (facilities.isEmpty) {
          return EmptyStateView(
            icon: Symbols.star,
            title: l.favorites_empty_title,
            body: l.favorites_empty_facility,
            actionLabel: l.favorites_action_openMap,
            onAction: () => context.go('/map'),
          );
        }
        return ListView.separated(
          itemCount: facilities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final f = facilities[i];
            return Dismissible(
              key: ValueKey('fav-facility-${f.id}'),
              direction: DismissDirection.endToStart,
              background: const _DismissBg(),
              onDismissed: (_) => _remove(context, ref, FavoriteType.facility, f.id),
              child: FacilityListItem(
                facility: f,
                onTap: () => context.go('/map/facility/${f.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _GuideFavorites extends ConsumerWidget {
  const _GuideFavorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(favoriteGuideItemsProvider);

    return async.when(
      loading: () => const SkeletonList(rows: 4),
      error: (e, _) =>
          EmptyStateView(icon: Symbols.star, title: l.favorites_empty_guide),
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Symbols.star,
            title: l.favorites_empty_title,
            body: l.favorites_empty_guide,
            actionLabel: l.favorites_action_openGuide,
            onAction: () => context.go('/guide'),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final g = items[i];
            return Dismissible(
              key: ValueKey('fav-guide-${g.id}'),
              direction: DismissDirection.endToStart,
              background: const _DismissBg(),
              onDismissed: (_) => _remove(context, ref, FavoriteType.guide, g.id),
              child: GuideListItem(
                item: g,
                onTap: () => context.go('/guide/item/${g.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

void _remove(
    BuildContext context, WidgetRef ref, FavoriteType type, String id) {
  final l = AppLocalizations.of(context);
  ref.read(favoritesProvider.notifier).toggle(type, id);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(l.favorites_removed),
      action: SnackBarAction(
        label: l.common_undo,
        onPressed: () => ref.read(favoritesProvider.notifier).toggle(type, id),
      ),
    ));
}

class _DismissBg extends StatelessWidget {
  const _DismissBg();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: context.dimens.spaceLg),
      child: Icon(Symbols.delete, color: scheme.onErrorContainer),
    );
  }
}
