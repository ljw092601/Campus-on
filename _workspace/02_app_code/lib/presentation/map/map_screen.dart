import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../shared/external_links.dart';
import '../shared/widgets/category_filter_bar.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';
import 'campus_proximity.dart';
import 'widgets/campus_map_view.dart';
import 'widgets/campus_selector.dart';
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
    this.focusFloorCode,
    this.focusRoomCode,
    this.focusPlanCode,
    this.focusToken,
    this.navigationBase = '/map',
  });

  final List<String> focusIds;
  final List<String> nearbyQueries;

  /// Floor code from `/map?floor=` (classroom search deep link): "03" for
  /// 3F, "B1" for basement 1. Opens the focused building's peek sheet
  /// expanded at that floor.
  final String? focusFloorCode;

  /// Room code from `/map?room=` (e.g. "0306-1"): the peek sheet shows that
  /// room's floor plan with a red dot.
  final String? focusRoomCode;

  /// Floor-plan building code from `/map?plan=` ("B04A") when the room's
  /// drawings are not filed under the building's own code.
  final String? focusPlanCode;

  /// `/map?t=` — unique per search, so repeating the same search into the
  /// already-open map tab still re-selects and re-centres.
  final String? focusToken;

  /// Classroom results use a root stack above the search form, while the map
  /// tab uses its own branch. Details/lists stay in their originating stack.
  final String navigationBase;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  // Peek sheet extents (fractions of the map area). Collapsed shows the
  // header row; dragging up reveals the floor guide.
  static const _peekMin = 0.17;
  static const _peekMax = 0.75;

  /// Sheet extent at (or below) which a downward swipe counts as "dismiss".
  /// With `minChildSize: 0` the sheet snaps to 0 when released below half of
  /// [_peekMin]; this threshold catches that landing without firing on an
  /// ordinary collapse to [_peekMin].
  static const _peekDismissExtent = 0.02;

  String? _selectedId;
  bool _mapLoadFailed = false;

  /// One-shot: a `/map?focus=` target may live on another campus (e.g. a guide
  /// linking to 부민 종합강의동) — switch the campus selector to it once the
  /// facility list is known.
  bool _campusSynced = false;
  bool _focusActive = false;
  bool _focusApplied = false;
  bool _focusSyncScheduled = false;

  // ── Off-campus keyword search (`?nearby=`) ───────────────────────────────
  // Results are owned here and passed back down to the map view, so a rebuild
  // (filter change, GPS fix) never re-runs the search.
  List<NearbyPlace> _places = const [];
  bool _placesSearched = false;

  // ── Live "my location" tracking (native map-app behaviour) ────────────────
  // FAB starts a position stream: the blue dot follows the user in real time
  // and the camera chases every fix (follow mode). A manual map pan drops
  // follow mode (dot keeps updating); tapping the FAB again re-enables it.
  final _zoomHandle = CampusMapZoomHandle();

  UserLocation? _userLocation;
  bool _locating = false; // access check / waiting for the first fix
  bool _following = false;
  StreamSubscription<UserLocation>? _positionSub;
  Stream<double>? _headingStream;
  Timer? _firstFixTimeout;
  bool _resumeTrackingOnForeground = false;

  /// Whether this screen is on screen at all (audit L-19). go_router wraps
  /// every inactive shell branch in `Offstage` + `TickerMode(enabled: false)`,
  /// and the Navigator disables tickers under an opaque pushed route (detail,
  /// list, search), so [TickerMode.valuesOf] is "the map tab is visible" without
  /// knowing the tab index. The high-accuracy GPS stream only runs while
  /// true; [_resumeTrackingOnVisible] restarts it when the tab comes back.
  bool _visible = true;
  bool _resumeTrackingOnVisible = false;

  /// Far-from-campus notice (audit M-24) already shown for the current
  /// "outside" stretch. Reset by a fix back inside the radius, so the user is
  /// told once per excursion, not on every 2 m GPS update.
  bool _farNotified = false;

  bool get _tracking => _positionSub != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.focusIds.isNotEmpty) {
      // Representative marker = first id (deep-link contract, UX doc §3).
      _selectedId = widget.focusIds.first;
      _focusActive = true;
    }
  }

  /// Identity of the current deep-link request. The map tab stays alive in
  /// the shell, so a new search arrives as new widget params on this same
  /// State rather than a fresh initState.
  String _focusKeyOf(MapScreen w) => [
        w.focusIds.join(','),
        w.focusFloorCode,
        w.focusRoomCode,
        w.focusPlanCode,
        w.focusToken,
      ].join('|');

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusKeyOf(widget) != _focusKeyOf(oldWidget)) {
      // New search / deep link: select its building (opens the peek sheet)
      // and let the campus follow it again.
      _focusActive = widget.focusIds.isNotEmpty;
      _focusApplied = false;
      _selectedId = _focusActive ? widget.focusIds.first : null;
      _campusSynced = false;
      _focusSyncScheduled = false;
      _following = false;
    }
    if (!listEquals(widget.nearbyQueries, oldWidget.nearbyQueries)) {
      if (NearbyPlace.idFromMarker(_selectedId ?? '') != null) {
        _selectedId = null;
      }
      _places = const [];
      _placesSearched = false;
    }
  }

  void _clearFocus() {
    _focusActive = false;
    _selectedId = null;
    _following = false;
  }

  /// Dismisses the peek sheet (bare-map tap, close button, swipe-down —
  /// audit M-8). Unlike [_clearFocus] it leaves follow mode alone: closing a
  /// sheet is not a camera gesture. Dropping [_focusActive] also removes the
  /// classroom red dot, matching what a tap on another pin does.
  void _deselect() {
    if (_selectedId == null) return;
    setState(() {
      _focusActive = false;
      _selectedId = null;
    });
  }

  void _markFocusApplied() {
    final key = _focusKeyOf(widget);
    // Camera callbacks can arrive during a child's build/update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusActive && key == _focusKeyOf(widget)) {
        setState(() => _focusApplied = true);
      }
    });
  }

  void _selectCampus(Campus campus) {
    setState(() {
      _clearFocus();
      _places = const [];
      _placesSearched = false;
    });
    ref.read(mapCampusProvider.notifier).state = campus;
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
      if (_visible) {
        _startTracking(AppLocalizations.of(context));
      } else {
        _resumeTrackingOnVisible = true; // wait for the tab instead
      }
    }
  }

  /// Tab visibility (L-19): the map tab left (other tab, pushed detail) →
  /// stop the GPS stream but keep the last fix so the dot is back instantly;
  /// tab visible again → resume if we were tracking when it went away.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (!visible) {
      if (_tracking) {
        _stopTracking(keepFollowing: true);
        _resumeTrackingOnVisible = true;
      }
      return;
    }
    if (!_resumeTrackingOnVisible) return;
    _resumeTrackingOnVisible = false;
    // Dependencies change mid-build; restart once the frame is out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_visible || _tracking) return;
      _startTracking(AppLocalizations.of(context));
    });
  }

  Future<void> _onMyLocationPressed(AppLocalizations l) async {
    setState(_clearFocus);
    if (_tracking) {
      // Already tracking → just re-enable follow (recenters via the map view),
      // unless the last fix is off-campus: then repeat the notice instead of
      // flying to an empty map (the press is an explicit ask, so re-telling
      // is not spam).
      final loc = _userLocation;
      final follow = loc == null || _allowFollow(loc, l, userInitiated: true);
      setState(() => _following = follow);
      return;
    }
    await _startTracking(l, userInitiated: true);
  }

  Future<void> _startTracking(AppLocalizations l,
      {bool userInitiated = false}) async {
    // A stale fix from an earlier session may already be off-campus — decide
    // before the first rebuild, or the map view would chase it the moment
    // follow turns on.
    final stale = _userLocation;
    final follow =
        stale == null || _allowFollow(stale, l, userInitiated: userInitiated);
    setState(() {
      _following = follow;
      _locating = stale == null; // spinner only before the first dot
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
      // The denied snackbar says "showing campus center" — do it (L-21).
      if (access is LocationPermissionDenied) _zoomHandle.centerOnCampus();
      return;
    }

    _headingStream ??= service.headingUpdates();
    _positionSub = service.positionUpdates().listen((location) {
      _firstFixTimeout?.cancel();
      if (!mounted) return;
      // Off-campus fix: keep drawing the dot, but drop follow so the camera
      // stays on campus (M-24). The FAB then shows "not locked", and a fresh
      // press re-evaluates.
      final follow = _allowFollow(location, l);
      setState(() {
        _locating = false;
        _userLocation = location;
        if (!follow) _following = false;
      });
      // Camera is chasing this fix: keep the campus selector (and marker
      // set) on the campus it is actually over (L-36).
      if (_following) _syncCampusToLocation(location);
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

  /// Camera policy for a GPS fix (M-24): true when the camera may follow it.
  /// Shows the far-from-campus notice once per excursion outside the radius
  /// (or again on an explicit [userInitiated] FAB press).
  bool _allowFollow(UserLocation loc, AppLocalizations l,
      {bool userInitiated = false}) {
    final far = CampusProximity.isFarFromCampus(
        lat: loc.lat, lng: loc.lng, centers: _campusCenters());
    if (!far) {
      _farNotified = false;
      return true;
    }
    if (!_farNotified || userInitiated) {
      _farNotified = true;
      _showSnackBar(l.map_location_farFromCampus);
    }
    return false;
  }

  /// Switches [mapCampusProvider] to the campus a followed GPS fix is on
  /// (L-36). Deliberately NOT [_selectCampus]: that path is the user's own
  /// selector tap and clears focus/selection/nearby results (M-29); a GPS
  /// update must not throw the user's state away. The map view skips its
  /// campus refit while following, so the camera stays on the fix.
  void _syncCampusToLocation(UserLocation loc) {
    final centers = <Campus, ({double lat, double lng})>{};
    for (final campus in Campus.values) {
      final center = _campusCenter(campus);
      if (center != null) centers[campus] = center;
    }
    final nearest = CampusProximity.nearestWithin(
        lat: loc.lat, lng: loc.lng, centers: centers);
    if (nearest == null) return;
    final notifier = ref.read(mapCampusProvider.notifier);
    if (notifier.state != nearest) notifier.state = nearest;
  }

  /// Centres of every campus with known facilities (facility-average, like
  /// [_campusCenter]); the configured default when none are loaded yet.
  List<({double lat, double lng})> _campusCenters() {
    final centers = <({double lat, double lng})>[];
    for (final campus in Campus.values) {
      final center = _campusCenter(campus);
      if (center != null) centers.add(center);
    }
    if (centers.isEmpty) {
      centers.add(
          (lat: AppConfig.campusCenterLat, lng: AppConfig.campusCenterLng));
    }
    return centers;
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
        messenger
            .showSnackBar(SnackBar(content: Text(l.map_myLocation_failed)));
      case LocationReady():
        break; // not an error — caller proceeds
    }
  }

  /// Floor label ("3F") for the `?floor=` deep link, but only while the
  /// deep-linked building itself is the selected one — tapping another pin
  /// goes back to the normal collapsed peek.
  String? _floorLabelFor(Facility selected) {
    final code = widget.focusFloorCode;
    if (!_focusActive ||
        code == null ||
        widget.focusIds.isEmpty ||
        selected.id != widget.focusIds.first ||
        !selected.hasFloorInfo) {
      return null;
    }
    if (RegExp(r'^B\d$').hasMatch(code)) return '${code}F';
    final n = int.tryParse(code);
    if (n == null || n <= 0) return null;
    return '${n}F';
  }

  /// `?room=` code, only while the deep-linked building is selected.
  String? _roomCodeFor(Facility selected) {
    final code = widget.focusRoomCode;
    if (!_focusActive ||
        code == null ||
        widget.focusIds.isEmpty ||
        selected.id != widget.focusIds.first) {
      return null;
    }
    return code;
  }

  bool _opensExpanded(Facility selected) =>
      _floorLabelFor(selected) != null || _roomCodeFor(selected) != null;

  bool _expandable(Facility selected) =>
      selected.hasFloorInfo || _roomCodeFor(selected) != null;

  Facility? _find(List<Facility> list, String? id) {
    if (id == null) return null;
    for (final f in list) {
      if (f.id == id) return f;
    }
    return null;
  }

  ({double lat, double lng})? _campusCenter(Campus campus) {
    final facilities = ref
        .read(allFacilitiesProvider)
        .valueOrNull
        ?.where((f) => f.campus == campus)
        .toList();
    if (facilities == null || facilities.isEmpty) return null;
    return (
      lat: facilities.fold(0.0, (sum, f) => sum + f.lat) / facilities.length,
      lng: facilities.fold(0.0, (sum, f) => sum + f.lng) / facilities.length,
    );
  }

  void _syncCampusToFocus(List<Facility> all) {
    if (!_focusActive || _campusSynced || _focusSyncScheduled) return;
    _focusSyncScheduled = true;
    final key = _focusKeyOf(widget);
    // Resolve against ALL facilities, then send one ready request to the map.
    // No pending focus is left in the WebView while campus/filter changes settle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key != _focusKeyOf(widget) || !_focusActive) return;
      _focusSyncScheduled = false;
      final target = _find(all, widget.focusIds.first);
      if (target == null) {
        setState(_clearFocus);
        _showSnackBar(AppLocalizations.of(context).map_focus_notFound);
        return;
      }
      ref.read(facilityCategoryFilterProvider.notifier).state = null;
      if (target.campus != null) {
        ref.read(mapCampusProvider.notifier).state = target.campus!;
      }
      setState(() => _campusSynced = true);
    });
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
    if (places.isEmpty) _showSnackBar(l.map_nearby_empty);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Kakao place page in the browser; a failed launch tells the user (L-8).
  Future<void> _openPlace(NearbyPlace place) async {
    final url = place.placeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await openExternal(context, uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = ref.watch(mapFacilitiesProvider);

    final allFacilities = ref.watch(allFacilitiesProvider).valueOrNull;
    if (allFacilities != null) _syncCampusToFocus(allFacilities);

    ref.listen(facilityCategoryFilterProvider, (previous, next) {
      if (previous != next && _campusSynced) setState(_clearFocus);
    });

    // One-shot Empty toast: fire only on the transition INTO an empty result
    // (data change), not on every rebuild (e.g. marker-tap setState). Requires
    // a real Kakao key so it doesn't stack on top of the no-key fallback.
    ref.listen<AsyncValue<List<Facility>>>(mapFacilitiesProvider, (prev, next) {
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
            onPressed: () => context.push('${widget.navigationBase}/list'),
          ),
        ],
      ),
      body: Column(
        children: [
          CampusSelector(onSelected: _selectCampus),
          const CategoryFilterBar(),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: readErrorMessage(e, l, l.map_error_loadFailed),
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(allFacilitiesProvider),
                secondaryLabel: l.map_error_openList,
                onSecondary: () =>
                    context.push('${widget.navigationBase}/list'),
              ),
              data: (facilities) => ReadStatusContent(
                  data: facilities,
                  onRetry: () => ref.invalidate(allFacilitiesProvider),
                  child: _buildMap(context, l, facilities)),
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
        onSecondary: () => context.push('${widget.navigationBase}/list'),
      );
    }

    // Empty filter result → toast handled once via ref.listen in build().
    final selected = _find(facilities, _selectedId);
    final selectedPlace = _selectedPlace;
    final campus = ref.watch(mapCampusProvider);

    return LayoutBuilder(builder: (context, constraints) {
      // Keep the FAB above the collapsed Peek sheet (a fraction of THIS box).
      final peekHeight = constraints.maxHeight * _peekMin;
      return Stack(
        children: [
          Positioned.fill(
            child: CampusMapView(
              onLoadFailureChanged: (failed) {
                if (mounted) setState(() => _mapLoadFailed = failed);
              },
              onOpenList: () => context.push('${widget.navigationBase}/list'),
              facilities: facilities,
              campus: campus,
              campusCenter: _campusCenter(campus),
              focusIds: _focusActive && _campusSynced && !_focusApplied
                  ? widget.focusIds
                  : const [],
              onFocusApplied: _markFocusApplied,
              focusKey: _focusKeyOf(widget),
              // Classroom search: red dot on the room's building.
              targetId: _focusActive &&
                      _campusSynced &&
                      widget.focusRoomCode != null &&
                      widget.focusIds.isNotEmpty
                  ? widget.focusIds.first
                  : null,
              // Deep-linked building opens with the sheet expanded; keep its
              // pin above it.
              focusObscuredFraction: selected == null
                  ? 0
                  : (_opensExpanded(selected) ? _peekMax : _peekMin),
              selectedId: _selectedId,
              zoomHandle: _zoomHandle,
              userLocation: _userLocation,
              following: _following,
              headingStream: _tracking ? _headingStream : null,
              placeQueries: widget.nearbyQueries,
              places: _places,
              onPlacesFound: (places) => _onPlacesFound(places, l),
              onPlacesFailed: () => _showSnackBar(l.map_nearby_failed),
              onUserPan: () {
                if (_following) setState(() => _following = false);
              },
              onMarkerTap: (id) => setState(() {
                _clearFocus();
                _selectedId = id;
              }),
              // Tapping the bare map dismisses whichever peek sheet is open.
              onMapTap: _deselect,
            ),
          ),
          if (!_mapLoadFailed) ...[
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
            // Zoom in/out buttons sit right below it.
            Positioned(
              right: context.dimens.spaceMd,
              bottom: context.dimens.spaceMd +
                  (selected != null
                      ? peekHeight
                      : (selectedPlace != null ? 96 : 0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
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
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    tooltip: l.map_zoomIn_tooltip,
                    onPressed: _zoomHandle.zoomIn,
                    child: const Icon(Symbols.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    tooltip: l.map_zoomOut_tooltip,
                    onPressed: _zoomHandle.zoomOut,
                    child: const Icon(Symbols.remove),
                  ),
                ],
              ),
            ),
            if (selected != null)
              Positioned.fill(
                // Swipe-down past the collapsed header snaps the sheet to 0 —
                // treat that landing as a dismiss (M-8).
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (n) {
                    if (n.extent <= _peekDismissExtent) _deselect();
                    return false;
                  },
                  // Key resets the sheet extent when another pin is tapped —
                  // or when a new search targets this same building.
                  child: DraggableScrollableSheet(
                    key: ValueKey(_focusActive &&
                            widget.focusIds.isNotEmpty &&
                            selected.id == widget.focusIds.first
                        ? '${selected.id}|${_focusKeyOf(widget)}'
                        : selected.id),
                    // A `?floor=` / `?room=` deep link lands with the guide
                    // open.
                    initialChildSize:
                        _opensExpanded(selected) ? _peekMax : _peekMin,
                    // 0 lets a downward swipe dismiss; the collapsed header
                    // is a snap stop, never a resting place below it.
                    minChildSize: 0,
                    // Nothing below the header (no floor info, no searched
                    // room) → lock the sheet at the collapsed size.
                    maxChildSize: _expandable(selected) ? _peekMax : _peekMin,
                    // Snap stops: 0 (dismiss) · collapsed · expanded. A
                    // non-expandable sheet has max == collapsed, so listing it
                    // again as a snap size would violate the ascending rule.
                    snap: true,
                    snapSizes:
                        _expandable(selected) ? const [_peekMin] : null,
                    builder: (context, scrollController) => PeekSheet(
                      facility: selected,
                      scrollController: scrollController,
                      expandedFloor: _floorLabelFor(selected),
                      roomCode: _roomCodeFor(selected),
                      roomPlanCode: widget.focusPlanCode,
                      onViewDetail: () => context.push(
                          '${widget.navigationBase}/facility/${selected.id}'),
                      onClose: _deselect,
                    ),
                  ),
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
                      : () => _openPlace(selectedPlace),
                  onClose: _deselect,
                ),
              ),
          ],
        ],
      );
    });
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
