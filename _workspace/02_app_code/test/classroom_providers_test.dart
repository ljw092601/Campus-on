import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_on/domain/entities/floor_plan.dart';
import 'package:campus_on/presentation/providers/classroom_providers.dart';
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

  test('plan room JSON: outline and rect are optional', () {
    final full = PlanRoom.fromJson('0302', const {
      'x': 0.2,
      'y': 0.3,
      'r': [0.1, 0.2, 0.3, 0.4],
      'o': [0.1, 0.2, 0.4, 0.2, 0.4, 0.6, 0.1, 0.6],
    });
    expect(full.rect, [0.1, 0.2, 0.3, 0.4]);
    expect(full.outline, hasLength(8));

    final bare = PlanRoom.fromJson('0108', const {'x': 0.5, 'y': 0.5});
    expect(bare.rect, isNull);
    expect(bare.outline, isNull);
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

  test('building without floor info yields no entries', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // s17 체육관 등 층별 미등록 건물 — 데이터에 따라 null 반환 → 빈 목록.
    final entries = await container
        .read(classroomEntriesProvider(('no-such-id', null)).future);
    expect(entries, isEmpty);
  });
}
