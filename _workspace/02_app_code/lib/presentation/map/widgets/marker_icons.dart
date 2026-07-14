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

  /// Pin image is 48×60; anchor the tip (bottom-center) to the coordinate.
  static const int width = 40;
  static const int height = 50;
  static const int offsetX = 20;
  static const int offsetY = 50;

  static Future<Map<FacilityCategory, kakao.MarkerIcon>> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _loadAll();
  }

  static Future<Map<FacilityCategory, kakao.MarkerIcon>> _loadAll() async {
    final map = <FacilityCategory, kakao.MarkerIcon>{};
    for (final c in FacilityCategory.values) {
      map[c] = await kakao.MarkerIcon.fromAsset('assets/markers/pin_${c.name}.png');
    }
    _cache = map;
    _inFlight = null;
    return map;
  }
}
