import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/config/app_config.dart';
import '../../../domain/entities/facility.dart';
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
class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.facilities,
    required this.focusIds,
    required this.onMarkerTap,
    this.selectedId,
  });

  final List<Facility> facilities;
  final List<String> focusIds;
  final String? selectedId;
  final ValueChanged<String> onMarkerTap;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  kakao.KakaoMapController? _controller;

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
      ];

  kakao.LatLng get _center {
    if (widget.facilities.isNotEmpty) {
      final f = widget.facilities.first;
      return kakao.LatLng(f.lat, f.lng);
    }
    return kakao.LatLng(AppConfig.campusCenterLat, AppConfig.campusCenterLng);
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
          onMapCreated: (controller) {
            _controller = controller;
            _applyFocus();
          },
          onMarkerTap: (markerId, latLng, zoomLevel) {
            widget.onMarkerTap(markerId);
          },
        );
      },
    );
  }
}
