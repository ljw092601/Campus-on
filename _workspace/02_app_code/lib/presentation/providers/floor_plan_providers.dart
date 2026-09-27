import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/floor_plan.dart';

/// Bundled room index for the floor-plan drawings.
const floorPlanIndexAsset = 'assets/floorplans/floorplans.json';

/// Floor plans keyed by building code ("S04") → floor label ("3F"). Loaded
/// once from the bundle; buildings without drawings are simply absent.
final floorPlansProvider =
    FutureProvider<Map<String, Map<String, FloorPlan>>>((ref) async {
  final raw = await rootBundle.loadString(floorPlanIndexAsset);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final b in json.entries)
      b.key: {
        for (final f in (b.value as Map<String, dynamic>).entries)
          f.key:
              FloorPlan.fromJson(b.key, f.key, f.value as Map<String, dynamic>),
      },
  };
});

/// Floor-plan building codes for a campus-map building code, given the codes
/// present in the plan index: the code itself ("S04"), or its wings when the
/// drawings split it ("B04" → "B04A", "B04B"). Empty when the building has no
/// drawings.
List<String> planCodesFor(String buildingCode, Iterable<String> indexCodes) {
  final codes = indexCodes.toSet();
  if (codes.contains(buildingCode)) return [buildingCode];
  final wings = [
    for (final c in codes)
      if (c.length == buildingCode.length + 1 && c.startsWith(buildingCode)) c
  ]..sort();
  return wings;
}

/// Drawings of one building (empty when it has none). `.family` on the
/// floor-plan building code (see [planCodesFor]).
final buildingFloorPlansProvider =
    FutureProvider.family<Map<String, FloorPlan>, String>((ref, code) async {
  final all = await ref.watch(floorPlansProvider.future);
  return all[code] ?? const {};
});

/// Resolves "S04" + "0306-1" to its drawing and dot position; null when the
/// room is not on any drawing (no plan for that building/floor, or unknown
/// code).
final roomLocationProvider =
    FutureProvider.family<RoomLocation?, (String, String)>((ref, key) async {
  final (buildingCode, roomCode) = key;
  final plans =
      await ref.watch(buildingFloorPlansProvider(buildingCode).future);
  for (final plan in plans.values) {
    final room = plan.rooms[roomCode];
    if (room != null) return RoomLocation(plan: plan, room: room);
  }
  return null;
});
