import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/config/app_config.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/nearby_place.dart';
import '../../../domain/entities/user_location.dart';
import 'marker_icons.dart';

/// Thin wrapper around the Kakao Maps widget. ALL Kakao-plugin coupling lives
/// here — if the plugin's API shifts, only this file needs updating; the map
/// screen (S2) depends on this widget's stable interface.
///
/// Behaviour:
///  - Places one per-category colored pin per facility (6 colors, UX §4.1).
///    The 6 pin PNGs are loaded once via [CategoryMarkerIcons] before the map
///    renders, so markers are colored from the first frame (fully offline).
///  - On create, if [focusIds] is non-empty, fitBounds over those markers
///    (single id → recenter) per the `/map?focus=` deep-link contract.
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
class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.facilities,
    required this.focusIds,
    required this.onMarkerTap,
    this.campus,
    this.selectedId,
    this.userLocation,
    this.following = false,
    this.onUserPan,
    this.headingStream,
    this.placeQueries = const [],
    this.places = const [],
    this.onPlacesFound,
    this.onPlacesFailed,
  });

  final List<Facility> facilities;

  /// Currently shown campus. When it CHANGES, the camera re-fits to the new
  /// campus's markers (the plugin itself syncs the marker set).
  final Campus? campus;

  final List<String> focusIds;
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

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  static const _dotOverlayId = 'user-location-dot';
  static const _headingElementId = 'uloc-heading';
  static const _accuracyCircleId = 'user-location-accuracy';
  static const _locationBlue = Color(0xFF4285F4);

  kakao.KakaoMapController? _controller;

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
    _syncHeadingSubscription(null);
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHeadingSubscription(oldWidget.headingStream);

    // Campus switch: chase the new campus's marker cluster. widget.facilities
    // is already the new campus's (filtered) list in this same build.
    if (widget.campus != oldWidget.campus) _fitToFacilities();

    // New search terms → search again; new results → frame them. (The plugin
    // syncs the marker list itself from the `markers` param on update.)
    if (!listEquals(oldWidget.placeQueries, widget.placeQueries)) {
      _runPlaceSearch();
    }
    if (oldWidget.places.length != widget.places.length) {
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
    _headingSub?.cancel();
    super.dispose();
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
        customOverlayId: _dotOverlayId,
        latLng: kakao.LatLng(loc.lat, loc.lng),
        content: _dotHtml(),
        yAnchor: 0.5,
        // Above facility pins (selected pin uses 10).
        zIndex: 20,
      ),
    ];
  }

  List<kakao.Circle> _userCircles() {
    final loc = widget.userLocation;
    final accuracy = loc?.accuracyMeters;
    // A halo under ~15m would hide beneath the dot; skip it.
    if (loc == null || accuracy == null || accuracy < 15) return const [];
    return [
      kakao.Circle(
        circleId: _accuracyCircleId,
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

  List<kakao.Marker> _markers(Map<FacilityCategory, kakao.MarkerIcon> icons) => [
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

  /// Runs every query around the campus center and reports the merged result.
  ///
  /// One search per keyword (the JS SDK takes a single keyword per call) with
  /// the responses de-duplicated by place id, since "SKT 대리점" and
  /// "KT 대리점" can both match a multi-carrier shop.
  Future<void> _runPlaceSearch() async {
    final controller = _controller;
    final queries = widget.placeQueries;
    if (controller == null || queries.isEmpty) return;

    final found = <String, NearbyPlace>{};
    var failed = false;
    for (final keyword in queries) {
      try {
        final res = await controller.keywordSearch(
          kakao.KeywordSearchRequest(
            keyword: keyword,
            x: AppConfig.campusCenterLng,
            y: AppConfig.campusCenterLat,
            radius: _placeSearchRadiusMeters,
            size: 15,
            sort: kakao.SortBy.distance,
          ),
        );
        for (final a in res.list) {
          final place = _toPlace(a);
          if (place != null) found[place.id] = place;
        }
      } catch (_) {
        // A single failed keyword shouldn't drop the others (the search runs
        // through the WebView bridge, which can reject while the page settles).
        failed = true;
      }
    }
    if (!mounted) return;
    if (found.isEmpty && failed) {
      widget.onPlacesFailed?.call();
      return;
    }
    final places = found.values.toList()
      ..sort((a, b) =>
          (a.distanceMeters ?? 1 << 30).compareTo(b.distanceMeters ?? 1 << 30));
    widget.onPlacesFound?.call(places);
  }

  /// Kakao returns every field as a string; a row without usable coordinates
  /// can't be pinned, so it is dropped rather than guessed at.
  NearbyPlace? _toPlace(kakao.KeywordAddress a) {
    final lat = double.tryParse(a.y ?? '');
    final lng = double.tryParse(a.x ?? '');
    final id = a.id;
    if (lat == null || lng == null || id == null || id.isEmpty) return null;
    return NearbyPlace(
      id: id,
      name: (a.placeName ?? '').trim(),
      lat: lat,
      lng: lng,
      address: a.addressName,
      roadAddress: a.roadAddressName,
      phone: a.phone,
      placeUrl: a.placeUrl,
      distanceMeters: double.tryParse(a.distance ?? '')?.round(),
    );
  }

  /// Wide enough to reach the shopping streets around campus, small enough
  /// that results stay walkable.
  static const int _placeSearchRadiusMeters = 5000;

  void _fitPlaces() {
    final controller = _controller;
    if (controller == null || widget.places.isEmpty) return;
    // Keep the campus in frame alongside the stores so the user keeps their
    // bearings; a single result just recenters.
    final targets = [
      kakao.LatLng(AppConfig.campusCenterLat, AppConfig.campusCenterLng),
      for (final p in widget.places) kakao.LatLng(p.lat, p.lng),
    ];
    controller.fitBounds(targets);
  }

  kakao.LatLng get _center {
    if (widget.facilities.isNotEmpty) {
      final f = widget.facilities.first;
      return kakao.LatLng(f.lat, f.lng);
    }
    return kakao.LatLng(AppConfig.campusCenterLat, AppConfig.campusCenterLng);
  }

  void _fitToFacilities() {
    final controller = _controller;
    if (controller == null || widget.facilities.isEmpty) return;
    final targets = [
      for (final f in widget.facilities) kakao.LatLng(f.lat, f.lng),
    ];
    if (targets.length == 1) {
      controller.setCenter(targets.first);
    } else {
      controller.fitBounds(targets);
    }
  }

  void _applyFocus() {
    final controller = _controller;
    if (controller == null || widget.focusIds.isEmpty) return;
    final targets = widget.facilities
        .where((f) => widget.focusIds.contains(f.id))
        .map((f) => kakao.LatLng(f.lat, f.lng))
        .toList();
    if (targets.isEmpty) return;
    if (targets.length == 1) {
      controller.setCenter(targets.first);
    } else {
      controller.fitBounds(targets);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gate the map on the (memoised) pin icons so every marker is colored from
    // the first render. The future resolves instantly after the first load.
    return FutureBuilder<Map<FacilityCategory, kakao.MarkerIcon>>(
      future: CategoryMarkerIcons.load(),
      builder: (context, snapshot) {
        final icons = snapshot.data;
        if (icons == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return kakao.KakaoMap(
          center: _center,
          markers: _markers(icons),
          circles: _userCircles(),
          customOverlays: _userOverlays(),
          onMapCreated: (controller) {
            _controller = controller;
            // The plugin only auto-adds overlays on didUpdateWidget (e.g. a
            // filter change), not on first create — so add them explicitly once
            // the controller is ready, otherwise the initial (unfiltered) map
            // renders with no pins until the user interacts.
            controller.addMarker(markers: _markers(icons));
            if (widget.userLocation != null) {
              controller.addCircle(circles: _userCircles());
              controller.addCustomOverlay(customOverlays: _userOverlays());
            }
            _applyFocus();
            _runPlaceSearch();
          },
          onMarkerTap: (markerId, latLng, zoomLevel) {
            widget.onMarkerTap(markerId);
          },
          // A manual pan means "stop chasing me" — native map-app behaviour.
          onDragChangeCallback: (latLng, zoomLevel, dragType) {
            if (dragType == kakao.DragType.start) widget.onUserPan?.call();
          },
        );
      },
    );
  }
}
