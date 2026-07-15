import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/user_location.dart';

/// Outcome of a location-access request. The map screen switches on this to
/// either start tracking or show the matching snackbar (UX doc S2).
sealed class LocationResult {
  const LocationResult();
}

/// Service on + permission granted — tracking may start.
class LocationReady extends LocationResult {
  const LocationReady();
}

/// Device-level location service (GPS) is turned off.
class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// App permission denied. [permanent] means "don't ask again" / iOS Settings —
/// re-requesting is futile, so the UI offers a shortcut to app settings.
class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied({required this.permanent});

  final bool permanent;
}

/// Access check itself blew up (plugin/platform error).
class LocationFailure extends LocationResult {
  const LocationFailure();
}

/// Thin wrapper around geolocator + flutter_compass. ALL sensor-plugin coupling
/// lives here, mirroring how campus_map_view.dart isolates the Kakao plugin —
/// screens only ever see [LocationResult]/[UserLocation]/plain doubles.
class LocationService {
  const LocationService();

  /// Runs the service/permission flow. Never throws — every failure mode maps
  /// to a [LocationResult] subtype; [LocationReady] means tracking may start.
  Future<LocationResult> ensureAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionDenied(permanent: true);
      }
      if (permission == LocationPermission.denied) {
        return const LocationPermissionDenied(permanent: false);
      }
      return const LocationReady();
    } catch (_) {
      return const LocationFailure();
    }
  }

  /// Continuous position fixes (call after [ensureAccess] returns
  /// [LocationReady]). Emits the OS's last known fix first, if any, so the dot
  /// appears immediately while the live GPS fix warms up. distanceFilter keeps
  /// updates meaningful (and the WebView redraws cheap) — one event per ~2m
  /// moved, nothing while standing still.
  Stream<UserLocation> positionUpdates() async* {
    final last = await _lastKnownOrNull();
    if (last != null) yield last;
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).map(_toUserLocation);
  }

  /// Compass heading in degrees clockwise from north, normalized to [0, 360).
  /// Empty stream when the device has no magnetometer.
  Stream<double> headingUpdates() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    return events
        .map((e) => e.heading)
        .where((h) => h != null)
        .map((h) => (h! % 360 + 360) % 360);
  }

  /// Opens the app's OS settings page (for the "denied forever" snackbar action).
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device location (GPS) settings page.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<UserLocation?> _lastKnownOrNull() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      return position == null ? null : _toUserLocation(position);
    } catch (_) {
      return null;
    }
  }

  UserLocation _toUserLocation(Position position) => UserLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracyMeters: position.accuracy,
      );
}
