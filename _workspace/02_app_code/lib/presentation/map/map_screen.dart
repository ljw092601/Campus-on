import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../shared/widgets/category_filter_bar.dart';
import '../shared/widgets/state_views.dart';
import 'widgets/campus_map_view.dart';
import 'widgets/peek_sheet.dart';

/// S2 — Map. Kakao map + 6-category markers + Peek sheet + `/map?focus=` deep
/// link (fitBounds + auto-open first marker's Peek).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusIds = const []});

  final List<String> focusIds;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    if (widget.focusIds.isNotEmpty) {
      // Representative marker = first id (deep-link contract, UX doc §3).
      _selectedId = widget.focusIds.first;
    }
  }

  Facility? _find(List<Facility> list, String? id) {
    if (id == null) return null;
    for (final f in list) {
      if (f.id == id) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = ref.watch(filteredFacilitiesProvider);

    // One-shot Empty toast: fire only on the transition INTO an empty result
    // (data change), not on every rebuild (e.g. marker-tap setState). Requires
    // a real Kakao key so it doesn't stack on top of the no-key fallback.
    ref.listen<AsyncValue<List<Facility>>>(filteredFacilitiesProvider,
        (prev, next) {
      if (!AppConfig.hasKakaoKey) return;
      final nextEmpty = next.valueOrNull?.isEmpty ?? false;
      final prevEmpty = prev?.valueOrNull?.isEmpty ?? false;
      if (nextEmpty && !prevEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l.map_empty_noMarker)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.map_appbar_title),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            tooltip: l.search_appbar_hint,
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Symbols.list),
            tooltip: l.map_toggle_toList,
            onPressed: () => context.go('/map/list'),
          ),
        ],
      ),
      body: Column(
        children: [
          const CategoryFilterBar(),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: l.map_error_loadFailed,
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(allFacilitiesProvider),
                secondaryLabel: l.map_error_openList,
                onSecondary: () => context.go('/map/list'),
              ),
              data: (facilities) => _buildMap(context, l, facilities),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
      BuildContext context, AppLocalizations l, List<Facility> facilities) {
    // No key → documented fallback instead of a crash (UX doc S2 Error).
    if (!AppConfig.hasKakaoKey) {
      return ErrorStateView(
        message: l.map_error_loadFailed,
        retryLabel: l.common_retry,
        onRetry: () => ref.invalidate(allFacilitiesProvider),
        secondaryLabel: l.map_error_openList,
        onSecondary: () => context.go('/map/list'),
      );
    }

    // Empty filter result → toast handled once via ref.listen in build().
    final selected = _find(facilities, _selectedId);

    return Stack(
      children: [
        Positioned.fill(
          child: CampusMapView(
            facilities: facilities,
            focusIds: widget.focusIds,
            selectedId: _selectedId,
            onMarkerTap: (id) => setState(() => _selectedId = id),
          ),
        ),
        // "My location" FAB (permission handling wired in week 3).
        Positioned(
          right: context.dimens.spaceMd,
          bottom: context.dimens.spaceMd +
              (selected != null ? 96 : 0),
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            onPressed: () => ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                  SnackBar(content: Text(l.map_myLocation_denied))),
            child: const Icon(Symbols.my_location),
          ),
        ),
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PeekSheet(
              facility: selected,
              onViewDetail: () =>
                  context.go('/map/facility/${selected.id}'),
            ),
          ),
      ],
    );
  }
}
