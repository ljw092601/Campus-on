import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/location_service.dart';

/// Device location access (S2 "my location" FAB). Stateless service — a plain
/// Provider is enough; the map screen owns the fetched fix as widget state.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
