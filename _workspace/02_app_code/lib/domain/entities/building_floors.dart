import 'package:flutter/foundation.dart';

/// One floor of a building: floor label ("B1F", "3F", "옥탑F") + the rooms on
/// it. Room names are Korean-only for now (source data is Korean; other
/// languages are a later phase — see plan §9).
@immutable
class FloorInfo {
  const FloorInfo({required this.floor, required this.rooms});

  final String floor;
  final List<String> rooms;

  factory FloorInfo.fromJson(Map<String, dynamic> j) => FloorInfo(
        floor: (j['floor'] ?? '') as String,
        rooms: [for (final r in (j['rooms'] as List? ?? const [])) r as String],
      );

  Map<String, dynamic> toJson() => {'floor': floor, 'rooms': rooms};
}

/// Floor-by-floor guide for one building, keyed by the owning [Facility.id].
/// Stored as its own Firestore collection (`building_floors`) so the map's
/// load-all-facilities query stays light; loaded lazily when a pin is tapped.
///
/// Floors keep source order (deepest basement first, rooftop last).
@immutable
class BuildingFloors {
  const BuildingFloors({required this.facilityId, required this.floors});

  final String facilityId;
  final List<FloorInfo> floors;

  factory BuildingFloors.fromJson(Map<String, dynamic> j) => BuildingFloors(
        facilityId: (j['facilityId'] ?? j['id'] ?? '') as String,
        floors: [
          for (final f in (j['floors'] as List? ?? const []))
            FloorInfo.fromJson((f as Map).cast<String, dynamic>()),
        ],
      );

  Map<String, dynamic> toJson() => {
        'facilityId': facilityId,
        'floors': [for (final f in floors) f.toJson()],
      };
}
