import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/config/app_config.dart';
import '../../../domain/entities/facility.dart';

/// Thin wrapper around the Kakao Maps widget. ALL Kakao-plugin coupling lives
/// here — if the plugin's API shifts, only this file needs updating; the map
/// screen (S2) depends on this widget's stable interface.
///
/// Behaviour:
///  - Places one marker per facility.
///  - On create, if [focusIds] is non-empty, fitBounds over those markers
///    (single id → recenter) per the `/map?focus=` deep-link contract.
///  - Reports marker taps via [onMarkerTap] (facility id).
///
/// NOTE (week-3 asset TODO): Kakao markers use image sources, so the 6 category
/// colors need 6 pin PNGs. Until those assets exist we use the default pin and
/// convey category by color+icon in the Peek sheet and list. A per-category pin
/// helper will be added alongside those assets.
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

  List<kakao.Marker> _markers() => [
        for (final f in widget.facilities)
          kakao.Marker(
            markerId: f.id,
            latLng: kakao.LatLng(f.lat, f.lng),
          ),
      ];

  kakao.LatLng get _center {
    if (widget.facilities.isNotEmpty) {
      final f = widget.facilities.first;
      return kakao.LatLng(f.lat, f.lng);
    }
    return kakao.LatLng(
        AppConfig.campusCenterLat, AppConfig.campusCenterLng);
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
    return kakao.KakaoMap(
      center: _center,
      markers: _markers(),
      onMapCreated: (controller) {
        _controller = controller;
        _applyFocus();
      },
      onMarkerTap: (markerId, latLng, zoomLevel) {
        widget.onMarkerTap(markerId);
      },
    );
  }
}
