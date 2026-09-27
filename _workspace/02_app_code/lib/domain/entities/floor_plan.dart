import 'package:flutter/foundation.dart';

/// One room label found on a floor-plan drawing. Coordinates are fractions of
/// the image size (0..1) so they survive any re-export / resize of the plan.
@immutable
class PlanRoom {
  const PlanRoom({
    required this.code,
    required this.x,
    required this.y,
    this.rect,
  });

  /// Room code without the building prefix, e.g. "0306" or "0306-1".
  final String code;

  /// Label centre — where the red location dot is drawn.
  final double x;
  final double y;

  /// Room bounds as [left, top, width, height] fractions, when known.
  final List<double>? rect;

  factory PlanRoom.fromJson(String code, List<dynamic> j) => PlanRoom(
        code: code,
        x: (j[0] as num).toDouble(),
        y: (j[1] as num).toDouble(),
        rect: j.length >= 6
            ? [for (final v in j.sublist(2, 6)) (v as num).toDouble()]
            : null,
      );
}

/// Floor-plan drawing of one floor (`assets/floorplans/`), generated from the
/// designer PNGs by `tool/floorplans/extract_rooms.py`.
@immutable
class FloorPlan {
  const FloorPlan({
    required this.buildingCode,
    required this.floorLabel,
    required this.asset,
    required this.width,
    required this.height,
    required this.rooms,
  });

  final String buildingCode;

  /// Floor label matching [FloorInfo.floor], e.g. "3F".
  final String floorLabel;
  final String asset;
  final double width;
  final double height;
  final Map<String, PlanRoom> rooms;

  double get aspectRatio => width / height;

  factory FloorPlan.fromJson(
          String buildingCode, String floorLabel, Map<String, dynamic> j) =>
      FloorPlan(
        buildingCode: buildingCode,
        floorLabel: floorLabel,
        asset: j['image'] as String,
        width: (j['w'] as num).toDouble(),
        height: (j['h'] as num).toDouble(),
        rooms: {
          for (final e in (j['rooms'] as Map).entries)
            e.key as String:
                PlanRoom.fromJson(e.key as String, e.value as List<dynamic>),
        },
      );
}

/// A resolved search hit: the room and the drawing it sits on.
@immutable
class RoomLocation {
  const RoomLocation({required this.plan, required this.room});

  final FloorPlan plan;
  final PlanRoom room;
}
