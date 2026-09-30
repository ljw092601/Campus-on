import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'floor_plan_providers.dart';

/// One selectable classroom inside a building: the room code, the floor it
/// sits on (label matching [FloorInfo.floor], e.g. "3F"), and the room name
/// behind it (empty when only the code is known).
class ClassroomEntry {
  const ClassroomEntry({
    required this.code,
    required this.floorLabel,
    required this.roomName,
    this.onPlan = false,
  });

  /// Room code: "0301" (first two digits = floor), "0306-1" / "0101-A" for a
  /// split room, "B101" for basement 1.
  final String code;
  final String floorLabel;
  final String roomName;

  /// True when the room is located on a floor-plan drawing (red-dot capable).
  final bool onPlan;
}

/// Accepted room-code input: "0301", "B101" (basement), or the 3-digit
/// oddities some drawings use ("059-1"), each with an optional "-N"/"-NN"
/// or "-A" suffix.
final roomCodePattern = RegExp(r'^(B\d{3}|\d{3,4})(-(\d{1,2}|[A-Z]))?$');

/// "0306-1" → "3F", "B110-1" → "B1F". Null for a malformed code or floor 00.
String? floorLabelOf(String roomCode) {
  if (!roomCodePattern.hasMatch(roomCode)) return null;
  if (roomCode.startsWith('B')) return 'B${roomCode[1]}F';
  final n = int.parse(roomCode.substring(0, 2));
  return n == 0 ? null : '${n}F';
}

/// Orders codes basement-first, then numerically:
/// B101 < 0306 < 0306-1 < 0306-2 < 0306-10 < 0307, with letter suffixes
/// (0101-A < 0101-B) after the bare code.
int compareRoomCodes(String a, String b) {
  final ba = a.startsWith('B'), bb = b.startsWith('B');
  if (ba != bb) return ba ? -1 : 1;
  final pa = a.split('-'), pb = b.split('-');
  final c = pa[0].compareTo(pb[0]);
  if (c != 0) return c;
  final sa = pa.length > 1 ? pa[1] : '', sb = pb.length > 1 ? pb[1] : '';
  // No suffix < numeric suffixes (by value) < letter suffixes.
  final na = sa.isEmpty ? -1 : int.tryParse(sa);
  final nb = sb.isEmpty ? -1 : int.tryParse(sb);
  if (na != null && nb != null) return na - nb;
  if (na != null) return -1;
  if (nb != null) return 1;
  return sa.compareTo(sb);
}

/// Only verified room numbers from bundled drawings are offered as suggestions.
final classroomEntriesProvider =
    FutureProvider.family<List<ClassroomEntry>, (String, String?)>(
        (ref, key) async {
  final (_, planCode) = key;
  if (planCode == null) return const [];
  final plans = await ref.watch(buildingFloorPlansProvider(planCode).future);
  return [
    for (final p in plans.values)
      for (final r in p.rooms.keys)
        ClassroomEntry(
            code: r, floorLabel: p.floorLabel, roomName: '', onPlan: true),
  ]..sort((a, b) => compareRoomCodes(a.code, b.code));
});
