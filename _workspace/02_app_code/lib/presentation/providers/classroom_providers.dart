import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'facility_providers.dart';

/// One selectable classroom inside a building: the 4-digit room code, the
/// floor it sits on (label matching [FloorInfo.floor], e.g. "3F"), and the
/// room name behind it.
class ClassroomEntry {
  const ClassroomEntry({
    required this.code,
    required this.floorLabel,
    required this.roomName,
  });

  /// 4-digit room code, first two digits = floor (e.g. "0301" = 3F room 01).
  final String code;
  final String floorLabel;
  final String roomName;
}

final _numericFloor = RegExp(r'^(\d+)F$');

/// PLACEHOLDER room numbers derived from the floor guide: a numeric floor
/// "3F" with N rooms yields 0301..03NN, each paired with that floor's room
/// names in source order. Basements ("B1F") and rooftops ("옥탑F") are skipped
/// because their numbering scheme is not defined yet.
///
/// TODO(room-data): replace this derivation with the real per-building room
/// number dataset once it is provided — the screen only consumes
/// [ClassroomEntry], so swapping the source is contained to this provider.
final classroomEntriesProvider =
    FutureProvider.family<List<ClassroomEntry>, String>((ref, facilityId) async {
  final building = await ref.watch(buildingFloorsProvider(facilityId).future);
  if (building == null) return const [];

  final entries = <ClassroomEntry>[];
  for (final floor in building.floors) {
    final m = _numericFloor.firstMatch(floor.floor);
    if (m == null) continue;
    final floorNo = int.parse(m.group(1)!);
    if (floorNo > 99) continue;
    final prefix = floorNo.toString().padLeft(2, '0');
    for (var i = 0; i < floor.rooms.length && i < 99; i++) {
      entries.add(ClassroomEntry(
        code: '$prefix${(i + 1).toString().padLeft(2, '0')}',
        floorLabel: floor.floor,
        roomName: floor.rooms[i],
      ));
    }
  }
  return entries;
});
