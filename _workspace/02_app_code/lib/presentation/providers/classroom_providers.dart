import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/floor_plan.dart';
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
///
/// The result is the canonical floor *key* ("3F" / "B1F") shared with
/// `FloorInfo.floor` and the plan index, not display text — screens turn it
/// into "3층" / "지하 1층" with `localizedFloorLabel` (L-31).
String? floorLabelOf(String roomCode) {
  if (!roomCodePattern.hasMatch(roomCode)) return null;
  if (roomCode.startsWith('B')) return 'B${roomCode[1]}F';
  final n = int.parse(roomCode.substring(0, 2));
  return n == 0 ? null : '${n}F';
}

/// Dash look-alikes users paste or type on mobile keyboards (en/em dash,
/// minus sign, hyphen bullet, Japanese long vowel mark).
final _dashLikes = RegExp('[\u2010-\u2015\u2212\u30FC]');

/// Building-code prefix of a full room code ("S04-", "B04A-"): the search
/// screen takes the building from its dropdown, so a pasted full code keeps
/// only the room half.
final _buildingPrefix = RegExp(r'^[A-Z]\d{2}[A-Z]?-');

/// Normalises raw room-number input (typed or pasted) into the canonical
/// form accepted by [roomCodePattern]: full-width letters/digits/dashes →
/// ASCII, dash look-alikes → "-", whitespace dropped, upper-cased, a leading
/// building code ("S04-0306-1" → "0306-1") stripped, and anything else
/// removed (L-7a/b). Pure; the search screen wraps it in a
/// `TextInputFormatter`.
String normalizeRoomCodeInput(String raw) {
  final buf = StringBuffer();
  for (final cp in raw.runes) {
    // Full-width ASCII block (！..～) sits exactly 0xFEE0 above ASCII.
    buf.writeCharCode(cp >= 0xFF01 && cp <= 0xFF5E ? cp - 0xFEE0 : cp);
  }
  var s = buf
      .toString()
      .replaceAll(_dashLikes, '-')
      .replaceAll(RegExp(r'[\s\u3000]'), '')
      .toUpperCase();
  s = s.replaceFirst(_buildingPrefix, '');
  return s.replaceAll(RegExp(r'[^0-9A-Z-]'), '');
}

/// Longest room code in the plan index (never below 7, the length of
/// "0501-10"), so the input's length cap follows the data instead of a
/// hard-coded guess (L-7b).
int maxRoomCodeLength(Map<String, Map<String, FloorPlan>> plans) {
  var max = 7;
  for (final b in plans.values) {
    for (final p in b.values) {
      for (final r in p.rooms.keys) {
        if (r.length > max) max = r.length;
      }
    }
  }
  return max;
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
/// Plain autoDispose (bundle-derived, no TTL — see [buildingFloorPlansProvider]).
final classroomEntriesProvider = FutureProvider.autoDispose
    .family<List<ClassroomEntry>, (String, String?)>((ref, key) async {
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
