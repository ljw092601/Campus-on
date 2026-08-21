import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/shared/widgets/floor_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Building floor-guide feature (plan §9): generated data invariants + the
/// FloorAccordion widget on the mock repository.
void main() {
  group('generated building data', () {
    test('48 buildings / 34 floor docs / 249 floors, ids consistent', () {
      expect(MockData.facilities, hasLength(48));
      expect(MockData.buildingFloors, hasLength(34));
      expect(
        MockData.buildingFloors.fold<int>(0, (n, b) => n + b.floors.length),
        249,
      );

      final floorIds = {for (final b in MockData.buildingFloors) b.facilityId};
      for (final f in MockData.facilities) {
        expect(floorIds.contains(f.id), f.hasFloorInfo,
            reason: 'hasFloorInfo mismatch for ${f.id}');
        expect(f.campus, isNotNull, reason: '${f.id} missing campus');
      }
    });

    test('campus split matches the campus map (24/15/9)', () {
      int count(Campus c) =>
          MockData.facilities.where((f) => f.campus == c).length;
      expect(count(Campus.seunghak), 24);
      expect(count(Campus.gudeok), 15);
      expect(count(Campus.bumin), 9);
    });
  });

  testWidgets('FloorAccordion renders floors and expands to rooms',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // s02 학생회관 — 8 floors, B2F..6F, 1F includes '식당'.
        home: Scaffold(
          body: SingleChildScrollView(
            child: FloorAccordion(facilityId: 's02'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('B2F'), findsOneWidget);
    expect(find.text('6F'), findsOneWidget);

    // Expand 1F → its room list becomes visible.
    await tester.tap(find.text('1F'));
    await tester.pumpAndSettle();
    expect(find.textContaining('식당'), findsWidgets);
  });
}
