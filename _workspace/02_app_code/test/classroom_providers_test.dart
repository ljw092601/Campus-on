import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/presentation/providers/classroom_providers.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';

void main() {
  // floorplans.json is read from the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('room code helpers', () {
    expect(floorLabelOf('0306-1'), '3F');
    expect(floorLabelOf('1203'), '12F');
    expect(floorLabelOf('0006'), isNull);
    expect(floorLabelOf('06'), isNull);
    expect(floorLabelOf('0306-'), isNull);
    expect(floorLabelOf('B110-1'), 'B1F');
    expect(floorLabelOf('0101-A'), '1F');
    expect(floorLabelOf('059-1'), '5F');
    expect(floorLabelOf('0101-a'), isNull);
    final codes = [
      '0307',
      '0306-10',
      '0306-2',
      '0306',
      '0306-1',
      'B101',
      '0306-A'
    ]..sort(compareRoomCodes);
    expect(codes,
        ['B101', '0306', '0306-1', '0306-2', '0306-10', '0306-A', '0307']);
  });

  test('plan codes: own code or wings', () {
    const index = ['S04', 'S12', 'B04A', 'B04B', 'B02'];
    expect(planCodesFor('S04', index), ['S04']);
    expect(planCodesFor('S12', index), ['S12']);
    expect(planCodesFor('B04', index), ['B04A', 'B04B']);
    expect(planCodesFor('S01', index), isEmpty);
  });

  test('wings and basements resolve on their own drawings', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final a =
        await container.read(roomLocationProvider(('B04A', '0301')).future);
    final b =
        await container.read(roomLocationProvider(('B04B', '0301')).future);
    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(a!.plan.asset, isNot(b!.plan.asset));

    final basement =
        await container.read(roomLocationProvider(('B02', 'B103-2')).future);
    expect(basement!.plan.floorLabel, 'B1F');

    final entries =
        await container.read(classroomEntriesProvider(('s04', 'S04')).future);
    expect(entries.map((e) => e.code), contains('0101-A'));
  });

  test('building with floor plans lists the real codes from the drawings',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // s04 = 공과대학2호관 (S04), drawn for 1F..5F.
    final entries =
        await container.read(classroomEntriesProvider(('s04', 'S04')).future);
    final codes = entries.map((e) => e.code).toList();

    expect(entries.every((e) => e.onPlan), isTrue);
    expect(codes, containsAll(['0304', '0306-1', '0311-3']));
    for (final e in entries) {
      expect(e.code, matches(roomCodePattern));
      expect(floorLabelOf(e.code), e.floorLabel);
    }
    expect(codes.toSet().length, codes.length);

    final loc =
        await container.read(roomLocationProvider(('S04', '0306-1')).future);
    expect(loc, isNotNull);
    expect(loc!.plan.floorLabel, '3F');
    expect(loc.room.x, inInclusiveRange(0, 1));
    expect(loc.room.y, inInclusiveRange(0, 1));

    expect(await container.read(roomLocationProvider(('S04', '0999')).future),
        isNull);
  });

  test('classroom entries derive 4-digit codes from the floor guide', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // s01 (대학본부) has registered floor info in the generated data.
    final entries =
        await container.read(classroomEntriesProvider(('s01', null)).future);

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

  test('국제교류과 is listed on B03 2F, not B04 1F (office moved in 2025)',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Office notices (2025-08-04 relocation; 2026-07-21·08-14 「글로벌인재관
    // 2층 국제교류과(B03-0202)」) — the floor-guide source is corrected to
    // match. Only the floor is asserted: the 4-digit code is a placeholder
    // derived from list order, so it is not treated as the real room number.
    final b03 = await container.read(classroomEntriesProvider(('b03', null)).future);
    final office = b03.where((e) => e.roomName == '국제교류과').toList();
    expect(office, hasLength(1));
    expect(office.single.floorLabel, '2F');
    expect(office.single.code, startsWith('02'));

    // B04 has a drawing, so the search screen passes a plan code and the
    // entries carry no room names. The floor guide is where these names reach
    // the screen, so the guarantee is asserted on that data (감사 05/053 권고 2).
    final b04 = await container.read(buildingFloorsProvider('b04').future);
    expect(b04, isNotNull, reason: 'B04 floor guide is missing');
    final b04Rooms = {
      for (final f in b04!.floors)
        for (final r in f.rooms) (r, f.floor)
    };
    expect(b04Rooms.any((e) => e.$1 == '국제교류과'), isFalse);
    // Not confirmed as moved — the campus-map location is kept.
    expect(b04Rooms.contains(('국제교류과회의실/자료실', '1F')), isTrue);
    expect(b04Rooms.contains(('국제교류처장실', '1F')), isTrue);
  });

  test('building without floor info yields no entries', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // s17 체육관 등 층별 미등록 건물 — 데이터에 따라 null 반환 → 빈 목록.
    final entries = await container
        .read(classroomEntriesProvider(('no-such-id', null)).future);
    expect(entries, isEmpty);
  });
}
