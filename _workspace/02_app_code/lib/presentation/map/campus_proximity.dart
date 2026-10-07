import 'dart:math' as math;

/// Pure geometry behind the "my location" camera policy (S2, audit M-24).
///
/// A GPS fix far from every campus (an emulator's default in California, a
/// student checking the app from home in Seoul) must NOT drag the camera to an
/// empty map. The screen asks here whether a fix is close enough to follow.
class CampusProximity {
  const CampusProximity._();

  /// Beyond this distance from the nearest campus centre the camera stops
  /// following the user. The three campuses are ~5 km apart, so 3 km keeps a
  /// commute between them inside the follow zone while excluding other cities.
  static const double followRadiusMeters = 3000;

  static const double _earthRadiusMeters = 6371000;

  /// Great-circle distance (haversine) in meters.
  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Distance in meters to the closest of [centers]; infinity when there are
  /// no centers at all (callers treat that as "unknown → don't follow").
  static double nearestDistanceMeters({
    required double lat,
    required double lng,
    required Iterable<({double lat, double lng})> centers,
  }) {
    var best = double.infinity;
    for (final c in centers) {
      final d = distanceMeters(lat, lng, c.lat, c.lng);
      if (d < best) best = d;
    }
    return best;
  }

  /// True when the fix lies outside [radiusMeters] of every campus centre.
  static bool isFarFromCampus({
    required double lat,
    required double lng,
    required Iterable<({double lat, double lng})> centers,
    double radiusMeters = followRadiusMeters,
  }) =>
      nearestDistanceMeters(lat: lat, lng: lng, centers: centers) >
      radiusMeters;

  static double _rad(double degrees) => degrees * math.pi / 180;
}
