import 'package:campus_on/data/mock/building_data.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Invariants of the generated building data (L-26): every floor's room list
/// is free of duplicate names, and the regenerated s14/3F in particular.
void main() {
  group('BuildingData floors', () {
    test('s14 3F has no duplicate room names', () {
      final s14 = BuildingData.floors
          .singleWhere((b) => b.facilityId == 's14');
      final rooms = s14.floors.singleWhere((f) => f.floor == '3F').rooms;
      expect(rooms.where((r) => r == '자료실'), hasLength(1));
      expect(rooms.toSet().length, rooms.length,
          reason: 'duplicates: ${_dupes(rooms)}');
    });

    test('no floor of any building lists the same room name twice', () {
      final problems = <String>[];
      for (final b in BuildingData.floors) {
        for (final f in b.floors) {
          final d = _dupes(f.rooms);
          if (d.isNotEmpty) problems.add('${b.facilityId}/${f.floor}: $d');
        }
      }
      expect(problems, isEmpty);
    });

    test('every floor has at least one non-empty room name', () {
      for (final b in BuildingData.floors) {
        for (final f in b.floors) {
          expect(f.rooms, isNotEmpty,
              reason: '${b.facilityId}/${f.floor} has no rooms');
          expect(f.rooms.any((r) => r.trim().isEmpty), isFalse,
              reason: '${b.facilityId}/${f.floor} has a blank room');
        }
      }
    });
  });
}

List<String> _dupes(List<String> rooms) {
  final seen = <String>{};
  return [for (final r in rooms) if (!seen.add(r)) r];
}
