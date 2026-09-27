import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/classroom_search_screen.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/shared/widgets/floor_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('oia-visit map pin lands on the building whose floors list the office',
        () {
      // The office moved to 글로벌인재관(B03) 2F in 2025 (office notices); the
      // floor-guide source was corrected so the pin and the floor list agree.
      final oia = MockData.guideItems.firstWhere((g) => g.id == 'oia-visit');
      expect(oia.relatedFacilityIds, ['b03']);
      List<String> rooms(String id, String floor) => MockData.buildingFloors
          .firstWhere((b) => b.facilityId == id)
          .floors
          .firstWhere((f) => f.floor == floor)
          .rooms;
      expect(rooms('b03', '2F'), contains('국제교류과'));
      for (final b in MockData.buildingFloors) {
        for (final f in b.floors) {
          if (b.facilityId == 'b03' && f.floor == '2F') continue;
          expect(f.rooms, isNot(contains('국제교류과')),
              reason: '${b.facilityId} ${f.floor}');
        }
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

  // Suggested 4-digit codes come from floor-list order, so reordering a floor
  // (e.g. the 2025 국제교류과 move) renumbers them. The screen says so.
  for (final locale in const [Locale('ko'), Locale('en')]) {
    testWidgets('classroom search warns that suggested numbers are placeholders '
        '(${locale.languageCode})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClassroomSearchScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(locale.languageCode == 'ko'
            ? '실제 호실 번호가 아닙니다'
            : 'not verified room numbers'),
        findsOneWidget,
      );
    });
  }

  /// s02 학생회관 — 8 floors, B2F..6F, 1F includes '식당'.
  Widget accordion(Locale locale) => ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: FloorAccordion(facilityId: 's02'),
            ),
          ),
        ),
      );

  testWidgets('FloorAccordion renders floors and expands to rooms',
      (tester) async {
    await tester.pumpWidget(accordion(const Locale('ko')));
    await tester.pumpAndSettle();

    expect(find.text('B2F'), findsOneWidget);
    expect(find.text('6F'), findsOneWidget);

    // Expand 1F → its room list becomes visible.
    await tester.tap(find.text('1F'));
    await tester.pumpAndSettle();
    expect(find.textContaining('식당'), findsWidgets);
  });

  testWidgets('room names and floor labels read in the chosen language',
      (tester) async {
    // The floor guide used to be Korean whatever the reader chose. Both the
    // floor label and the room names follow the language now, so the tap
    // target is the localised label.
    for (final (locale, label, room) in const [
      (Locale('en'), '1F', 'Cafeteria'),
      (Locale('zh'), '1层', '食堂'),
      (Locale('vi'), 'Tầng 1', 'Nhà ăn'),
    ]) {
      // Drop the previous tree first: pumping another MaterialApp of the same
      // type reuses the ExpansionTile's state, so the tap would close the tile
      // that the previous language left open.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(accordion(locale));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget,
          reason: 'the floor label reads as "$label" in ${locale.languageCode}');
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.textContaining(room), findsWidgets,
          reason: '식당 should read as "$room" in ${locale.languageCode}');
      expect(find.textContaining('식당'), findsNothing,
          reason: 'the Korean must not be left in alongside it');
    }
  });
}
