import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/presentation/providers/classroom_providers.dart';

void main() {
  test('classroom entries derive 4-digit codes from the floor guide', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // s01 (대학본부) has registered floor info in the generated data.
    final entries =
        await container.read(classroomEntriesProvider('s01').future);

    expect(entries, isNotEmpty);
    for (final e in entries) {
      expect(e.code, matches(RegExp(r'^\d{4}$')));
      expect(e.roomName, isNotEmpty);
      // First two digits encode the floor label (e.g. "3F" → "03xx").
      final floorNo = int.parse(e.code.substring(0, 2));
      expect('${floorNo}F', e.floorLabel);
    }
    // Numbers restart at 01 on each floor and stay unique per building.
    expect(entries.map((e) => e.code).toSet().length, entries.length);
    expect(entries.any((e) => e.code.endsWith('01')), isTrue);
  });

  test('building without floor info yields no entries', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // s17 체육관 등 층별 미등록 건물 — 데이터에 따라 null 반환 → 빈 목록.
    final entries =
        await container.read(classroomEntriesProvider('no-such-id').future);
    expect(entries, isEmpty);
  });
}
