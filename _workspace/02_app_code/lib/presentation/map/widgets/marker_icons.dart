import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../domain/entities/facility.dart';

/// Loads and caches the 6 category pin PNGs (assets/markers/pin_<cat>.png) as
/// Kakao [kakao.MarkerIcon]s.
///
/// `MarkerIcon.fromAsset` base64-encodes the PNG so it renders inside the plugin
/// WebView with no network — fully offline. Icons are loaded once app-wide and
/// memoised, so map rebuilds (filter/deep-link) don't reload assets.
class CategoryMarkerIcons {
  const CategoryMarkerIcons._();

  static Map<FacilityCategory, kakao.MarkerIcon>? _cache;
  static Future<Map<FacilityCategory, kakao.MarkerIcon>>? _inFlight;

  /// Pin PNGs are 68×84 (0.81 aspect); rendered smaller so dense campus
  /// clusters stay readable. Anchor the tip (bottom-center) on the coordinate.
  static const int width = 32;
  static const int height = 40;
  static const int offsetX = 16;
  static const int offsetY = 40;

  // ── Selected-pin emphasis (audit L-35) ────────────────────────────────────
  // The same PNG rendered 1.3× larger (no extra asset): the plugin scales the
  // base64 image to the Marker's width/height inside the WebView. The tip
  // stays anchored on the coordinate.
  static const double selectedScale = 1.3;
  static const int selectedWidth = 42; // round(32 × 1.3)
  static const int selectedHeight = 52; // round(40 × 1.3)
  static const int selectedOffsetX = 21;
  static const int selectedOffsetY = 52;

  /// kakao_map_plugin 0.3.7 never updates a marker whose id already exists
  /// (`addMarker` returns early), so a selection change must re-add the pin
  /// under a different id. The selected pin carries this suffix; everything
  /// that reports marker ids back to the screen strips it again.
  static const String selectedIdSuffix = '#sel';

  static String selectedMarkerId(String id) => '$id$selectedIdSuffix';

  /// Original marker id for a tap on either the plain or the selected pin.
  static String baseMarkerId(String markerId) =>
      markerId.endsWith(selectedIdSuffix)
          ? markerId.substring(0, markerId.length - selectedIdSuffix.length)
          : markerId;

  static Future<Map<FacilityCategory, kakao.MarkerIcon>> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _loadAll();
  }

  static Future<Map<FacilityCategory, kakao.MarkerIcon>> _loadAll() async {
    try {
      final map = <FacilityCategory, kakao.MarkerIcon>{};
      for (final c in FacilityCategory.values) {
        map[c] = await kakao.MarkerIcon.fromAsset(
            'assets/markers/pin_${c.name}.png');
      }
      _cache = map;
      return map;
    } finally {
      _inFlight = null;
    }
  }
}
