import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/config/app_config.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/nearby_place.dart';
import '../../../domain/entities/user_location.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/state_views.dart';
import 'marker_icons.dart';
import 'nearby_search_bridge.dart';

/// Thin wrapper around the Kakao Maps widget. ALL Kakao-plugin coupling lives
/// here — if the plugin's API shifts, only this file needs updating; the map
/// screen (S2) depends on this widget's stable interface.
///
/// Behaviour:
///  - Places one per-category colored pin per facility (6 colors, UX §4.1).
///    The 6 pin PNGs are loaded once via [CategoryMarkerIcons] before the map
///    renders, so markers are colored from the first frame (fully offline).
///  - On create, and whenever [focusIds] or [focusKey] changes (a new
///    `/map?focus=` deep link into the already-open map tab), fitBounds over
///    those markers (single id → recenter) per the deep-link contract. A
///    single pin is centred in the part of the map left visible above
///    [focusObscuredFraction] (the open peek sheet).
///  - Reports marker taps via [onMarkerTap] (facility id).
///  - Draws [userLocation] as a blue dot (pixel-fixed CustomOverlay) plus a
///    translucent accuracy halo (meter-based Circle). While [following], every
///    NEW [UserLocation] instance recenters the camera (instance identity marks
///    a fresh GPS fix); a map drag reports [onUserPan] so the screen can drop
///    follow mode, exactly like native map apps.
///  - [placeQueries] (non-empty) runs a Kakao keyword search around the campus
///    center once the map is ready — off-campus POIs such as carrier stores.
///    Results are converted to [NearbyPlace] here (the plugin's model never
///    leaves this file), reported via [onPlacesFound], and drawn with the
///    "etc" pin; their marker ids carry the [NearbyPlace.markerPrefix] so the
///    screen can tell a store tap from a facility tap.
///  - [headingStream] (compass, degrees from north) rotates a direction cone
///    around the dot. Updates bypass Flutter rebuilds entirely: they are
///    throttled and applied straight to the overlay's DOM node, because compass
///    events arrive at ~30Hz — far too fast to re-add overlays through the
///    plugin bridge.
/// Lets the map screen trigger zoom from its own buttons without touching the
/// Kakao controller directly (all plugin coupling stays in this file).
class CampusMapZoomHandle {
  _CampusMapViewState? _state;

  Future<void> zoomIn() async => _state?._zoomBy(-1);
  Future<void> zoomOut() async => _state?._zoomBy(1);
}

class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.facilities,
    required this.focusIds,
    required this.onMarkerTap,
    this.campus,
    this.campusCenter,
    this.selectedId,
    this.userLocation,
    this.following = false,
    this.onUserPan,
    this.headingStream,
    this.placeQueries = const [],
    this.places = const [],
    this.onPlacesFound,
    this.onPlacesFailed,
    this.zoomHandle,
    this.focusKey,
    this.onFocusApplied,
    this.focusObscuredFraction = 0,
    this.targetId,
    this.onLoadFailureChanged,
    this.onOpenList,
    this.loadTimeout = const Duration(seconds: 20),
  });

  final ValueChanged<bool>? onLoadFailureChanged;
  final VoidCallback? onOpenList;
  final Duration loadTimeout;
  final List<Facility> facilities;

  /// Currently shown campus. When it CHANGES, the camera re-fits to the new
  /// campus's markers (the plugin itself syncs the marker set).
  final Campus? campus;
  final ({double lat, double lng})? campusCenter;

  final List<String> focusIds;

  /// Changes whenever a new focus request arrives, even for the same
  /// [focusIds] (e.g. searching the same building again after panning away).
  final Object? focusKey;
  final VoidCallback? onFocusApplied;

  /// Fraction of the map's height covered from the bottom (the peek sheet);
  /// a single focused pin is centred in the visible part above it.
  final double focusObscuredFraction;

  /// Facility marked with a pulsing red dot — the building of a searched
  /// classroom (null = none).
  final String? targetId;

  final String? selectedId;
  final ValueChanged<String> onMarkerTap;
  final UserLocation? userLocation;
  final bool following;
  final VoidCallback? onUserPan;
  final Stream<double>? headingStream;

  /// Keyword searches to run once the map is ready (e.g. carrier store names).
  final List<String> placeQueries;

  /// Places to draw. Owned by the screen; fed back from [onPlacesFound].
  final List<NearbyPlace> places;
  final ValueChanged<List<NearbyPlace>>? onPlacesFound;
  final VoidCallback? onPlacesFailed;

  /// Optional handle for screen-side zoom buttons.
  final CampusMapZoomHandle? zoomHandle;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  static const _dotOverlayId = 'user-location-dot';
  static const _headingElementId = 'uloc-heading';
  static const _accuracyCircleId = 'user-location-accuracy';
  static const _locationBlue = Color(0xFF4285F4);

  kakao.KakaoMapController? _controller;
  Timer? _loadTimer;
  bool _loadFailed = false;
  int _loadAttempt = 0;

  void _startLoading() {
    final attempt = ++_loadAttempt;
    _loadFailed = false;
    _icons = null;
    _loadTimer?.cancel();
    _loadTimer = Timer(widget.loadTimeout, () => _failLoading(attempt));
    _loadIcons(attempt);
  }

  Future<void> _loadIcons(int attempt) async {
    try {
      final icons = await CategoryMarkerIcons.load();
      if (!mounted || attempt != _loadAttempt || _loadFailed) return;
      setState(() => _icons = icons);
    } catch (_) {
      _failLoading(attempt);
    }
  }

  void _failLoading(int attempt) {
    if (!mounted || attempt != _loadAttempt || _loadFailed) return;
    _loadTimer?.cancel();
    _controller = null;
    _cameraRevision++;
    _markerRevision++;
    _searchRevision++;
    _placeSearch?.dispose();
    _placeSearch = null;
    setState(() => _loadFailed = true);
    widget.onLoadFailureChanged?.call(true);
  }

  void _retryLoading() {
    setState(_startLoading);
    widget.onLoadFailureChanged?.call(false);
  }

  int _cameraRevision = 0;
  int _searchRevision = 0;
  int _markerRevision = 0;
  int _locationRevision = 0;
  Future<void> _markerSync = Future.value();
  Map<FacilityCategory, kakao.MarkerIcon>? _icons;
  NearbySearchBridge? _placeSearch;

  StreamSubscription<double>? _headingSub;

  /// Continuous (unbounded) rotation target so CSS `transition: transform`
  /// never animates the long way around the 359°→0° seam.
  double? _headingContinuous;
  double? _lastRawHeading;

  /// Last value actually written to the DOM; baked into the overlay HTML when
  /// a position update forces the overlay to be re-added.
  double? _appliedHeading;
  DateTime _lastHeadingWrite = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    widget.zoomHandle?._state = this;
    _syncHeadingSubscription(null);
    _startLoading();
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.zoomHandle, widget.zoomHandle)) {
      oldWidget.zoomHandle?._state = null;
      widget.zoomHandle?._state = this;
    }
    _syncHeadingSubscription(oldWidget.headingStream);

    // New focus request (classroom search / guide link into the open map
    // tab) → move to it.
    final focusChanged = !listEquals(oldWidget.focusIds, widget.focusIds) ||
        oldWidget.focusKey != widget.focusKey;

    if (focusChanged ||
        widget.campus != oldWidget.campus ||
        widget.following != oldWidget.following) {
      _cameraRevision++;
    }
    // The screen resolves campus/filter before delivering a focus request.
    // Once applied, ordinary campus/filter rebuilds must never replay it.
    if (focusChanged && widget.focusIds.isNotEmpty) {
      _applyFocus();
    } else if (widget.campus != oldWidget.campus) {
      _fitToFacilities();
    }

    _syncMarkers();
    if (!identical(oldWidget.userLocation, widget.userLocation)) {
      _locationRevision++;
    }

    // New search terms/campus invalidate previous asynchronous results.
    if (!listEquals(oldWidget.placeQueries, widget.placeQueries) ||
        oldWidget.campus != widget.campus) {
      _runPlaceSearch();
    }
    if (!listEquals(oldWidget.places, widget.places)) {
      _fitPlaces();
    }

    // Follow mode: recenter on every fresh GPS fix (new instance) and at the
    // moment follow is (re-)enabled. The dot/halo themselves are synced by the
    // plugin's own didUpdateWidget via the customOverlays/circles params.
    final loc = widget.userLocation;
    if (loc == null || !widget.following) return;
    final freshFix = !identical(oldWidget.userLocation, loc);
    final followTurnedOn = !oldWidget.following;
    if (freshFix || followTurnedOn) {
      _controller?.setCenter(kakao.LatLng(loc.lat, loc.lng));
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    widget.zoomHandle?._state = null;
    _placeSearch?.dispose();
    _headingSub?.cancel();
    super.dispose();
  }

  /// Kakao zoom level: 1 = closest, larger = further out.
  Future<void> _zoomBy(int delta) async {
    final controller = _controller;
    if (controller == null) return;
    final level = await controller.getLevel();
    controller.setLevel((level + delta).clamp(1, 14));
  }

  // ── User location dot + heading cone ──────────────────────────────────────

  /// Pixel-fixed dot with a rotatable direction cone (a Circle would scale
  /// with zoom). Rendered inside the plugin WebView — double quotes only: the
  /// plugin injects this string into single-quoted JavaScript.
  String _dotHtml() {
    final heading = _appliedHeading;
    return '<div style="position:relative;width:44px;height:44px;">'
        '<div id="$_headingElementId" style="position:absolute;inset:0;'
        'opacity:${heading == null ? 0 : 1};'
        'transform:rotate(${(heading ?? 0).toStringAsFixed(1)}deg);'
        'transition:transform 0.15s linear;">'
        // Cone: apex on the dot, spreading up (= north at rotate(0)).
        '<div style="position:absolute;left:50%;bottom:50%;margin-left:-11px;'
        'width:0;height:0;border-left:11px solid transparent;'
        'border-right:11px solid transparent;'
        'border-top:18px solid rgba(66,133,244,0.45);"></div>'
        '</div>'
        '<div style="position:absolute;left:50%;top:50%;'
        'transform:translate(-50%,-50%);width:16px;height:16px;'
        'background:#4285F4;border:3px solid #fff;border-radius:50%;'
        'box-shadow:0 1px 4px rgba(0,0,0,0.4);"></div>'
        '</div>';
  }

  List<kakao.CustomOverlay> _userOverlays() {
    final loc = widget.userLocation;
    if (loc == null) return const [];
    return [
      kakao.CustomOverlay(
        customOverlayId: '$_dotOverlayId-$_locationRevision',
        latLng: kakao.LatLng(loc.lat, loc.lng),
        content: _dotHtml(),
        yAnchor: 0.5,
        // Above facility pins (selected pin uses 10).
        zIndex: 20,
      ),
    ];
  }

  // ── Searched-classroom building dot ───────────────────────────────────────

  /// Red dot on the searched room's building. The overlay id carries the
  /// facility id: the plugin never moves an existing overlay (same id is
  /// kept as-is) but drops ids missing from the list, so a new search target
  /// swaps the dot cleanly.
  List<kakao.CustomOverlay> _targetOverlays() {
    final id = widget.targetId;
    if (id == null) return const [];
    Facility? target;
    for (final f in widget.facilities) {
      if (f.id == id) target = f;
    }
    if (target == null) return const [];
    return [
      kakao.CustomOverlay(
        customOverlayId: 'room-target-$id',
        latLng: kakao.LatLng(target.lat, target.lng),
        // Double quotes only (injected into single-quoted JavaScript).
        content: '<div style="position:relative;width:34px;height:34px;">'
            '<div style="position:absolute;inset:0;border-radius:50%;'
            'background:rgba(229,57,53,0.25);"></div>'
            '<div style="position:absolute;left:50%;top:50%;'
            'transform:translate(-50%,-50%);width:14px;height:14px;'
            'background:#E53935;border:3px solid #fff;border-radius:50%;'
            'box-shadow:0 1px 4px rgba(0,0,0,0.4);"></div>'
            '</div>',
        yAnchor: 0.5,
        // Over facility pins (selected pin 10), under the user dot (20).
        zIndex: 15,
      ),
    ];
  }

  List<kakao.CustomOverlay> _allOverlays() =>
      [..._userOverlays(), ..._targetOverlays()];

  List<kakao.Circle> _userCircles() {
    final loc = widget.userLocation;
    final accuracy = loc?.accuracyMeters;
    // A halo under ~15m would hide beneath the dot; skip it.
    if (loc == null || accuracy == null || accuracy < 15) return const [];
    return [
      kakao.Circle(
        circleId: '$_accuracyCircleId-$_locationRevision',
        center: kakao.LatLng(loc.lat, loc.lng),
        radius: accuracy.clamp(15, 300).toDouble(),
        strokeWidth: 1,
        strokeColor: _locationBlue,
        strokeOpacity: 0.4,
        strokeStyle: kakao.StrokeStyle.solid,
        fillColor: _locationBlue,
        fillOpacity: 0.12,
        zIndex: 1,
      ),
    ];
  }

  void _syncHeadingSubscription(Stream<double>? oldStream) {
    if (identical(widget.headingStream, oldStream)) return;
    _headingSub?.cancel();
    _headingSub = widget.headingStream?.listen(_onHeading);
  }

  void _onHeading(double raw) {
    // Accumulate the shortest angular delta into a continuous target.
    final prevRaw = _lastRawHeading;
    _lastRawHeading = raw;
    if (_headingContinuous == null || prevRaw == null) {
      _headingContinuous = raw;
    } else {
      final delta = ((raw - prevRaw + 540) % 360) - 180;
      _headingContinuous = _headingContinuous! + delta;
    }
    final target = _headingContinuous!;

    // Throttle DOM writes: compass chatter (<2°) and anything faster than
    // 100ms is invisible behind the 150ms CSS transition anyway.
    final now = DateTime.now();
    if (_appliedHeading != null &&
        ((target - _appliedHeading!).abs() < 2 ||
            now.difference(_lastHeadingWrite) <
                const Duration(milliseconds: 100))) {
      return;
    }
    _appliedHeading = target;
    _lastHeadingWrite = now;
    _writeHeadingToDom(target);
  }

  /// Rotates the cone in place. Touching the DOM node directly (instead of
  /// re-adding the overlay) avoids remove/add flicker and keeps the CSS
  /// transition alive. No-ops harmlessly until the dot exists.
  void _writeHeadingToDom(double degrees) {
    final controller = _controller;
    if (controller == null) return;
    final value = degrees.toStringAsFixed(1);
    controller.webViewController.runJavaScript(
        'var e=document.getElementById("$_headingElementId");'
        'if(e){e.style.opacity="1";e.style.transform="rotate(${value}deg)";}');
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  List<kakao.Marker> _markers(Map<FacilityCategory, kakao.MarkerIcon> icons) =>
      [
        for (final f in widget.facilities)
          kakao.Marker(
            markerId: f.id,
            latLng: kakao.LatLng(f.lat, f.lng),
            icon: icons[f.category],
            width: CategoryMarkerIcons.width,
            height: CategoryMarkerIcons.height,
            offsetX: CategoryMarkerIcons.offsetX,
            offsetY: CategoryMarkerIcons.offsetY,
            // Selected marker draws above its neighbours.
            zIndex: f.id == widget.selectedId ? 10 : 0,
          ),
        // Off-campus search results share the pin set — "etc" keeps them
        // visually distinct from every curated campus category.
        for (final p in widget.places)
          kakao.Marker(
            markerId: p.markerId,
            latLng: kakao.LatLng(p.lat, p.lng),
            icon: icons[FacilityCategory.etc],
            width: CategoryMarkerIcons.width,
            height: CategoryMarkerIcons.height,
            offsetX: CategoryMarkerIcons.offsetX,
            offsetY: CategoryMarkerIcons.offsetY,
            zIndex: p.markerId == widget.selectedId ? 10 : 0,
          ),
      ];

  // ── Keyword search (off-campus places) ────────────────────────────────────

  /// The plugin starts one asynchronous add per marker. Serialize updates so
  /// an old batch cannot add pins after a newer empty filter has cleared them.
  void _syncMarkers() {
    final controller = _controller;
    final icons = _icons;
    if (controller == null || icons == null) return;
    final revision = ++_markerRevision;
    final markers = _markers(icons);
    _markerSync = _markerSync.then((_) async {
      if (!mounted || revision != _markerRevision) return;
      if (markers.isEmpty) {
        await controller.webViewController.runJavaScript('clearMarker();');
      } else {
        await controller.addMarker(markers: markers);
      }
    }).catchError((Object error) {
      debugPrint('Map marker update failed: $error');
    });
  }

  /// Runs every query around the campus center and reports the merged result.
  ///
  /// One search per keyword (the JS SDK takes a single keyword per call) with
  /// the responses de-duplicated by place id, since "SKT 대리점" and
  /// "KT 대리점" can both match a multi-carrier shop.
  Future<void> _runPlaceSearch() async {
    final revision = ++_searchRevision;
    final search = _placeSearch;
    final queries = widget.placeQueries;
    if (search == null || queries.isEmpty) return;
    final center = _campusCenter;

    final found = <String, NearbyPlace>{};
    var failed = false;
    for (final keyword in queries) {
      try {
        final places = await search.search(
          keyword,
          lat: center.latitude,
          lng: center.longitude,
        );
        if (!mounted || revision != _searchRevision) return;
        for (final place in places) {
          found[place.id] = place;
        }
      } catch (_) {
        // A single failed keyword shouldn't drop the others (the search runs
        // through the WebView bridge, which can reject while the page settles).
        failed = true;
      }
      if (!mounted || revision != _searchRevision) return;
    }
    if (!mounted || revision != _searchRevision) return;
    if (found.isEmpty && failed) {
      widget.onPlacesFailed?.call();
      return;
    }
    final places = found.values.toList()
      ..sort((a, b) =>
          (a.distanceMeters ?? 1 << 30).compareTo(b.distanceMeters ?? 1 << 30));
    widget.onPlacesFound?.call(places);
  }

  kakao.LatLng get _campusCenter => kakao.LatLng(
      widget.campusCenter?.lat ?? AppConfig.campusCenterLat,
      widget.campusCenter?.lng ?? AppConfig.campusCenterLng);

  void _fitPlaces() {
    final controller = _controller;
    if (controller == null || widget.places.isEmpty) return;
    // Keep the campus in frame alongside the stores so the user keeps their
    // bearings; a single result just recenters.
    final targets = [
      _campusCenter,
      for (final p in widget.places) kakao.LatLng(p.lat, p.lng),
    ];
    controller.fitBounds(targets);
  }

  kakao.LatLng get _center {
    if (widget.facilities.isNotEmpty) {
      final f = widget.facilities.first;
      return kakao.LatLng(f.lat, f.lng);
    }
    return _campusCenter;
  }

  void _fitToFacilities() {
    final controller = _controller;
    if (controller == null) return;
    if (widget.facilities.isEmpty) {
      controller.setCenter(_campusCenter);
      return;
    }
    final targets = [
      for (final f in widget.facilities) kakao.LatLng(f.lat, f.lng),
    ];
    if (targets.length == 1) {
      controller.setCenter(targets.first);
    } else {
      controller.fitBounds(targets);
    }
  }

  Future<void> _applyFocus() async {
    final controller = _controller;
    if (controller == null || widget.focusIds.isEmpty) return;
    final targets = widget.facilities
        .where((f) => widget.focusIds.contains(f.id))
        .map((f) => kakao.LatLng(f.lat, f.lng))
        .toList();
    if (targets.isEmpty) {
      _fitToFacilities();
      return;
    }
    final revision = _cameraRevision;
    if (targets.length > 1) {
      await controller.fitBounds(targets);
      if (mounted && revision == _cameraRevision) widget.onFocusApplied?.call();
      return;
    }
    final target = targets.first;
    controller.setCenter(target);
    final obscured = widget.focusObscuredFraction;
    if (obscured <= 0) {
      widget.onFocusApplied?.call();
      return;
    }
    // Shift the camera south by half the covered height so the pin sits in
    // the middle of the visible strip above the sheet.
    try {
      final bounds = await controller.getBounds();
      if (!mounted || revision != _cameraRevision) return;
      final span = bounds.ne.latitude - bounds.sw.latitude;
      controller.setCenter(kakao.LatLng(
          target.latitude - span * obscured / 2, target.longitude));
    } catch (_) {
      // Bounds unavailable (map not laid out yet) — the plain centre stands.
    }
    if (mounted && revision == _cameraRevision) widget.onFocusApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loadFailed) {
      return ErrorStateView(
        message: l.map_error_timeout,
        retryLabel: l.common_retry,
        onRetry: _retryLoading,
        secondaryLabel: l.map_error_openList,
        onSecondary: widget.onOpenList,
      );
    }
    if (_icons == null) return const Center(child: CircularProgressIndicator());
    final attempt = _loadAttempt;
    return Stack(children: [
      kakao.KakaoMap(
        key: ValueKey(attempt),
        center: _center,
        // Markers are synchronized serially by this wrapper (including []).
        circles: _userCircles(),
        customOverlays: _allOverlays(),
        onMapCreated: (controller) {
          if (!mounted || attempt != _loadAttempt || _loadFailed) return;
          _loadTimer?.cancel();
          setState(() => _controller = controller);
          widget.onLoadFailureChanged?.call(false);
          _placeSearch = NearbySearchBridge(controller);
          // The plugin only auto-adds overlays on didUpdateWidget (e.g. a
          // filter change), not on first create — so add them explicitly once
          // the controller is ready, otherwise the initial (unfiltered) map
          // renders with no pins until the user interacts.
          _syncMarkers();
          if (widget.userLocation != null) {
            controller.addCircle(circles: _userCircles());
          }
          final overlays = _allOverlays();
          if (overlays.isNotEmpty) {
            controller.addCustomOverlay(customOverlays: overlays);
          }
          _applyFocus();
          _runPlaceSearch();
        },
        onMarkerTap: (markerId, latLng, zoomLevel) {
          if (!mounted || attempt != _loadAttempt || _loadFailed) return;
          widget.onMarkerTap(markerId);
        },
        onCustomOverlayTap: (message, _) {
          if (!mounted || attempt != _loadAttempt || _loadFailed) return;
          _placeSearch?.receiveOverlayMessage(message);
        },
        // A manual pan means "stop chasing me" — native map-app behaviour.
        onDragChangeCallback: (latLng, zoomLevel, dragType) {
          if (!mounted || attempt != _loadAttempt || _loadFailed) return;
          if (dragType == kakao.DragType.start) {
            _cameraRevision++;
            widget.onUserPan?.call();
          }
        },
      ),
      if (_controller == null)
        const Positioned.fill(
            child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()))),
    ]);
  }
}
