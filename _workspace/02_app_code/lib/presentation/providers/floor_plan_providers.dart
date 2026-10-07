import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/floor_plan.dart';

enum RoomLookupStatus { found, missingRoom, missingPlan }

class RoomLookup {
  const RoomLookup(this.status, [this.location]);
  final RoomLookupStatus status;
  final RoomLocation? location;
}

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
///
/// This and the derived families below are plain autoDispose (no TTL, M-25):
/// they are cheap lookups over the always-alive [floorPlansProvider], so
/// re-deriving on the next visit costs nothing while nothing lingers per
/// building/room key.
final buildingFloorPlansProvider = FutureProvider.autoDispose
    .family<Map<String, FloorPlan>, String>((ref, code) async {
  final all = await ref.watch(floorPlansProvider.future);
  return all[code] ?? const {};
});

/// Resolves "S04" + "0306-1" to its drawing and dot position; null when the
/// room is not on any drawing (no plan for that building/floor, or unknown
/// code).
final roomLocationProvider = FutureProvider.autoDispose
    .family<RoomLocation?, (String, String)>((ref, key) async {
  return (await ref.watch(roomLookupProvider(key).future)).location;
});

/// Resolves a (building code, room code) pair against the bundled drawings.
/// The building code may be a floor-plan code ("S04", "B04A") or a campus-map
/// code whose drawings are split by wing ("B04", as in a `/map?focus=b04&
/// room=0301` deep link without `plan=`): the wings from [planCodesFor] are
/// tried in order and the first drawing that has the room wins (L-3).
final roomLookupProvider = FutureProvider.autoDispose
    .family<RoomLookup, (String, String)>((ref, key) async {
  final (buildingCode, roomCode) = key;
  final index = await ref.watch(floorPlansProvider.future);
  final candidates = planCodesFor(buildingCode, index.keys);
  final floor = floorKeyOf(roomCode);
  var floorDrawn = false;
  for (final code in candidates) {
    final plans = await ref.watch(buildingFloorPlansProvider(code).future);
    for (final plan in plans.values) {
      final room = plan.rooms[roomCode];
      if (room != null) {
        return RoomLookup(
            RoomLookupStatus.found, RoomLocation(plan: plan, room: room));
      }
    }
    floorDrawn |= plans.containsKey(floor);
  }
  return RoomLookup(floorDrawn
      ? RoomLookupStatus.missingRoom
      : RoomLookupStatus.missingPlan);
});

/// Canonical floor key of a room code as used by the plan index: "0306-1" →
/// "3F", "B103-2" → "B1F", "" when the code is too short.
String floorKeyOf(String roomCode) {
  final base = roomCode.split('-').first;
  if (base.startsWith('B') && base.length >= 2) return 'B${base[1]}F';
  if (base.length >= 2) return '${int.tryParse(base.substring(0, 2))}F';
  return '';
}
