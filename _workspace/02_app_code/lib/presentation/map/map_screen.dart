import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/location_service.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/user_location.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/location_providers.dart';
import '../shared/widgets/category_filter_bar.dart';
import '../shared/widgets/state_views.dart';
import 'widgets/campus_map_view.dart';
import 'widgets/campus_selector.dart';
import 'widgets/peek_sheet.dart';

/// S2 — Map. Kakao map + 6-category markers + Peek sheet + `/map?focus=` deep
/// link (fitBounds + auto-open first marker's Peek).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusIds = const []});

  final List<String> focusIds;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  // Peek sheet extents (fractions of the map area). Collapsed shows the
  // header row; dragging up reveals the floor guide.
  static const _peekMin = 0.17;
  static const _peekMax = 0.75;

  String? _selectedId;

  /// One-shot: a `/map?focus=` target may live on another campus (e.g. a guide
  /// linking to 부민 종합강의동) — switch the campus selector to it once the
  /// facility list is known.
  bool _campusSynced = false;

  // ── Live "my location" tracking (native map-app behaviour) ────────────────
  // FAB starts a position stream: the blue dot follows the user in real time
  // and the camera chases every fix (follow mode). A manual map pan drops
  // follow mode (dot keeps updating); tapping the FAB again re-enables it.
  UserLocation? _userLocation;
  bool _locating = false; // access check / waiting for the first fix
  bool _following = false;
  StreamSubscription<UserLocation>? _positionSub;
  Stream<double>? _headingStream;
  Timer? _firstFixTimeout;
  bool _resumeTrackingOnForeground = false;

  bool get _tracking => _positionSub != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.focusIds.isNotEmpty) {
      // Representative marker = first id (deep-link contract, UX doc §3).
      _selectedId = widget.focusIds.first;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
    super.dispose();
  }

  /// GPS keeps draining while backgrounded unless the stream is torn down —
  /// stop on pause, transparently restart on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _tracking) {
      _stopTracking(keepFollowing: true);
      _resumeTrackingOnForeground = true;
    } else if (state == AppLifecycleState.resumed &&
        _resumeTrackingOnForeground) {
      _resumeTrackingOnForeground = false;
      _startTracking(AppLocalizations.of(context));
    }
  }

  Future<void> _onMyLocationPressed(AppLocalizations l) async {
    if (_tracking) {
      // Already tracking → just re-enable follow (recenters via the map view).
      setState(() => _following = true);
      return;
    }
    await _startTracking(l);
  }

  Future<void> _startTracking(AppLocalizations l) async {
    setState(() {
      _following = true;
      _locating = _userLocation == null; // spinner only before the first dot
    });
    final service = ref.read(locationServiceProvider);
    final access = await service.ensureAccess();
    if (!mounted) return;
    if (access is! LocationReady) {
      setState(() {
        _locating = false;
        _following = false;
      });
      _showAccessSnackBar(access, l, service);
      return;
    }

    _headingStream ??= service.headingUpdates();
    _positionSub = service.positionUpdates().listen((location) {
      _firstFixTimeout?.cancel();
      if (!mounted) return;
      setState(() {
        _locating = false;
        _userLocation = location;
      });
    }, onError: (Object _) {
      if (!mounted) return;
      _stopTracking();
      setState(() => _locating = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.map_myLocation_failed)));
    });
    // No last-known fix and no live fix either (e.g. deep indoors) → give up
    // instead of spinning forever.
    _firstFixTimeout = Timer(const Duration(seconds: 20), () {
      if (!mounted || _userLocation != null) return;
      _stopTracking();
      setState(() => _locating = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.map_myLocation_failed)));
    });
    setState(() {}); // reflect the tracking state on the FAB
  }

  void _stopTracking({bool keepFollowing = false}) {
    _positionSub?.cancel();
    _positionSub = null;
    _firstFixTimeout?.cancel();
    _firstFixTimeout = null;
    if (!keepFollowing) _following = false;
  }

  void _showAccessSnackBar(
      LocationResult access, AppLocalizations l, LocationService service) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    switch (access) {
      case LocationServiceDisabled():
        messenger.showSnackBar(SnackBar(
          content: Text(l.map_myLocation_serviceOff),
          action: SnackBarAction(
            label: l.map_myLocation_openSettings,
            onPressed: service.openLocationSettings,
          ),
        ));
      case LocationPermissionDenied(permanent: final permanent):
        messenger.showSnackBar(SnackBar(
          content: Text(l.map_myLocation_denied),
          // Re-requesting is futile once permanently denied — link to settings.
          action: permanent
              ? SnackBarAction(
                  label: l.map_myLocation_openSettings,
                  onPressed: service.openAppSettings,
                )
              : null,
        ));
      case LocationFailure():
        messenger.showSnackBar(
            SnackBar(content: Text(l.map_myLocation_failed)));
      case LocationReady():
        break; // not an error — caller proceeds
    }
  }

  Facility? _find(List<Facility> list, String? id) {
    if (id == null) return null;
    for (final f in list) {
      if (f.id == id) return f;
    }
    return null;
  }

  void _syncCampusToFocus(List<Facility> all) {
    if (_campusSynced || widget.focusIds.isEmpty) return;
    _campusSynced = true;
    final target = _find(all, widget.focusIds.first)?.campus;
    if (target == null) return;
    // Defer the provider write out of build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(mapCampusProvider.notifier).state = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = ref.watch(mapFacilitiesProvider);

    final allFacilities = ref.watch(allFacilitiesProvider).valueOrNull;
    if (allFacilities != null) _syncCampusToFocus(allFacilities);

    // One-shot Empty toast: fire only on the transition INTO an empty result
    // (data change), not on every rebuild (e.g. marker-tap setState). Requires
    // a real Kakao key so it doesn't stack on top of the no-key fallback.
    ref.listen<AsyncValue<List<Facility>>>(mapFacilitiesProvider,
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
          const CampusSelector(),
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
    final campus = ref.watch(mapCampusProvider);

    return LayoutBuilder(builder: (context, constraints) {
      // Keep the FAB above the collapsed Peek sheet (a fraction of THIS box).
      final peekHeight = constraints.maxHeight * _peekMin;
      return Stack(
        children: [
          Positioned.fill(
            child: CampusMapView(
              facilities: facilities,
              campus: campus,
              focusIds: widget.focusIds,
              selectedId: _selectedId,
              userLocation: _userLocation,
              following: _following,
              headingStream: _tracking ? _headingStream : null,
              onUserPan: () {
                if (_following) setState(() => _following = false);
              },
              onMarkerTap: (id) => setState(() => _selectedId = id),
            ),
          ),
          // "My location" FAB — starts live tracking (blue dot + heading cone
          // follow the user); while tracking, re-enables follow after a pan.
          Positioned(
            right: context.dimens.spaceMd,
            bottom: context.dimens.spaceMd +
                (selected != null ? peekHeight : 0),
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              tooltip: l.map_myLocation_tooltip,
              onPressed: _locating ? null : () => _onMyLocationPressed(l),
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  // Crosshair without dot = "not locked on me" (post-pan);
                  // matches the affordance native map apps use.
                  : Icon(_tracking && !_following
                      ? Symbols.location_searching
                      : Symbols.my_location),
            ),
          ),
          if (selected != null)
            Positioned.fill(
              // Key resets the sheet extent when another pin is tapped.
              child: DraggableScrollableSheet(
                key: ValueKey(selected.id),
                initialChildSize: _peekMin,
                minChildSize: _peekMin,
                // No floor info → nothing below the header; lock the sheet.
                maxChildSize: selected.hasFloorInfo ? _peekMax : _peekMin,
                // min/max are the implicit snap targets — half-open states
                // settle to collapsed or expanded on release.
                snap: selected.hasFloorInfo,
                builder: (context, scrollController) => PeekSheet(
                  facility: selected,
                  scrollController: scrollController,
                  onViewDetail: () =>
                      context.go('/map/facility/${selected.id}'),
                ),
              ),
            ),
        ],
      );
    });
  }
}
