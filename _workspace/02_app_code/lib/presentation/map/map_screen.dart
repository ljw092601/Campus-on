import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/location_service.dart';
import '../../domain/entities/facility.dart';
import '../../domain/entities/nearby_place.dart';
import '../../domain/entities/user_location.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/location_providers.dart';
import '../shared/widgets/category_filter_bar.dart';
import '../shared/widgets/state_views.dart';
import 'widgets/campus_map_view.dart';
import 'widgets/peek_sheet.dart';

/// S2 — Map. Kakao map + 6-category markers + Peek sheet + `/map?focus=` deep
/// link (fitBounds + auto-open first marker's Peek).
///
/// `/map?nearby=<kw1>,<kw2>,...` additionally searches those keywords around
/// campus and pins the results (off-campus places such as carrier stores) —
/// used by guide pages that point at a service the campus itself doesn't host.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    super.key,
    this.focusIds = const [],
    this.nearbyQueries = const [],
  });

  final List<String> focusIds;
  final List<String> nearbyQueries;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  String? _selectedId;

  // ── Off-campus keyword search (`?nearby=`) ───────────────────────────────
  // Results are owned here and passed back down to the map view, so a rebuild
  // (filter change, GPS fix) never re-runs the search.
  List<NearbyPlace> _places = const [];
  bool _placesSearched = false;

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

  /// Selected marker resolved as an off-campus place (null for facility ids).
  NearbyPlace? get _selectedPlace {
    final id = NearbyPlace.idFromMarker(_selectedId ?? '');
    if (id == null) return null;
    for (final p in _places) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _onPlacesFound(List<NearbyPlace> places, AppLocalizations l) {
    if (!mounted) return;
    setState(() {
      _places = places;
      _placesSearched = true;
    });
    if (places.isEmpty) _showPlacesSnackBar(l.map_nearby_empty);
  }

  void _showPlacesSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPlace(NearbyPlace place, AppLocalizations l) async {
    final url = place.placeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    final selectedPlace = _selectedPlace;
    final sheetOpen = selected != null || selectedPlace != null;

    return Stack(
      children: [
        Positioned.fill(
          child: CampusMapView(
            facilities: facilities,
            focusIds: widget.focusIds,
            selectedId: _selectedId,
            userLocation: _userLocation,
            following: _following,
            headingStream: _tracking ? _headingStream : null,
            placeQueries: widget.nearbyQueries,
            places: _places,
            onPlacesFound: (places) => _onPlacesFound(places, l),
            onPlacesFailed: () => _showPlacesSnackBar(l.map_nearby_failed),
            onUserPan: () {
              if (_following) setState(() => _following = false);
            },
            onMarkerTap: (id) => setState(() => _selectedId = id),
          ),
        ),
        // Result count for the `?nearby=` search — the pins alone don't say
        // what was searched for.
        if (widget.nearbyQueries.isNotEmpty && _placesSearched)
          Positioned(
            left: context.dimens.spaceMd,
            right: context.dimens.spaceMd,
            top: context.dimens.spaceSm,
            child: _NearbyBanner(count: _places.length),
          ),
        // "My location" FAB — starts live tracking (blue dot + heading cone
        // follow the user); while tracking, re-enables follow after a pan.
        Positioned(
          right: context.dimens.spaceMd,
          bottom: context.dimens.spaceMd + (sheetOpen ? 96 : 0),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PeekSheet(
              facility: selected,
              onViewDetail: () =>
                  context.go('/map/facility/${selected.id}'),
            ),
          )
        else if (selectedPlace != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlacePeekSheet(
              place: selectedPlace,
              // No in-app detail screen for an off-campus place — the CTA is
              // hidden rather than dead when Kakao gives us no page for it.
              onOpen: (selectedPlace.placeUrl ?? '').isEmpty
                  ? null
                  : () => _openPlace(selectedPlace, l),
            ),
          ),
      ],
    );
  }
}

/// Thin status strip over the map telling the user what the pins are — shown
/// only for the `?nearby=` entry point.
class _NearbyBanner extends StatelessWidget {
  const _NearbyBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: context.dimens.brSm,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.dimens.spaceMd,
            vertical: context.dimens.spaceSm),
        child: Row(
          children: [
            Icon(Symbols.storefront, size: 18, color: scheme.onSurfaceVariant),
            SizedBox(width: context.dimens.spaceSm),
            Expanded(
              child: Text(
                l.map_nearby_resultCount(count),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
