/// A single GPS fix of the user's position, shown as the blue dot on the map
/// (S2 "my location").
///
/// Deliberately has NO value equality: every fetch produces a new instance,
/// and the map view uses instance identity to decide "this is a fresh fix →
/// redraw the dot and recenter" even when the coordinates barely moved.
class UserLocation {
  const UserLocation({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
  });

  final double lat;
  final double lng;

  /// Horizontal accuracy radius in meters (drawn as a translucent halo).
  /// Null when the platform doesn't report it.
  final double? accuracyMeters;
}
