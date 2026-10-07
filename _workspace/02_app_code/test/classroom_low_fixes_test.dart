// Audit Low items on the classroom search / floor plan flow:
// L-3 wing fallback, L-5 viewport carry-over, L-7 input/suggestions/wing
// labels, L-28 reduce-motion pulse, L-30 plan semantics, L-31 floor label
// i18n, L-33 double-tap zoom.
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/classroom_search_screen.dart';
import 'package:campus_on/presentation/classroom/floor_label.dart';
import 'package:campus_on/presentation/classroom/floor_plan_screen.dart';
import 'package:campus_on/presentation/classroom/widgets/floor_plan_view.dart';
import 'package:campus_on/presentation/classroom/widgets/room_location_card.dart';
import 'package:campus_on/presentation/providers/classroom_providers.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _s04 = Facility(
  id: 's04',
  nameKo: '공과대학2호관',
  nameEn: 'Engineering Building 2',
  category: FacilityCategory.building,
  lat: 0,
  lng: 0,
  buildingCode: 'S04',
  hasFloorInfo: true,
);

const _b04 = Facility(
  id: 'b04',
  nameKo: '종합강의동(BA-BD)',
  nameEn: 'General Lecture Building (BA-BD)',
  category: FacilityCategory.building,
  lat: 0,
  lng: 0,
  buildingCode: 'B04',
  hasFloorInfo: true,
);

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allFacilitiesProvider.overrideWith((ref) async => const [_s04, _b04]),
    ]);
  });
  tearDown(() => container.dispose());

  Widget app(Widget home, {Locale? locale, bool reduceMotion = false}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: home,
        ),
      );

  Widget host(Widget child, {Locale? locale, bool reduceMotion = false}) =>
      app(Scaffold(body: SingleChildScrollView(child: child)),
          locale: locale, reduceMotion: reduceMotion);

  group('L-7a/b room-code input normalisation', () {
    test('full-width, dash look-alikes, spaces and case are normalised', () {
      expect(normalizeRoomCodeInput('０３０６－１'), '0306-1');
      expect(normalizeRoomCodeInput('0306–1'), '0306-1'); // en dash
      expect(normalizeRoomCodeInput('0306—1'), '0306-1'); // em dash
      expect(normalizeRoomCodeInput('0306−1'), '0306-1'); // minus sign
      expect(normalizeRoomCodeInput(' 0306 - 1 '), '0306-1');
      expect(normalizeRoomCodeInput('0101-a'), '0101-A');
      expect(normalizeRoomCodeInput('b101'), 'B101');
      expect(normalizeRoomCodeInput('03０6　1'), '03061');
    });

    test('a pasted full code keeps only the room half', () {
      expect(normalizeRoomCodeInput('S04-0306-1'), '0306-1');
      expect(normalizeRoomCodeInput('S04-0306'), '0306');
      expect(normalizeRoomCodeInput('b04a-0301'), '0301');
      expect(normalizeRoomCodeInput('Ｓ０４－０３０６－１'), '0306-1');
      expect(normalizeRoomCodeInput('B02-B103-2'), 'B103-2');
      // Not a building prefix: a basement room code stays intact.
      expect(normalizeRoomCodeInput('B101'), 'B101');
    });

    test('unsupported characters are dropped', () {
      expect(normalizeRoomCodeInput('03#06.1호'), '03061');
      expect(normalizeRoomCodeInput(''), '');
    });

    test('length cap follows the plan index (longest room "0501-10")',
        () async {
      final plans = await container.read(floorPlansProvider.future);
      final max = maxRoomCodeLength(plans);
      expect(max, 7);
      final longest = [
        for (final b in plans.values)
          for (final p in b.values) ...p.rooms.keys
      ].map((k) => k.length).reduce((a, b) => a > b ? a : b);
      expect(max, greaterThanOrEqualTo(longest));
      expect(maxRoomCodeLength(const {}), 7);
    });
  });

  group('L-3 wing fallback in roomLookupProvider', () {
    test('a campus-map code without plan= tries each wing in order',
        () async {
      // 0301 exists in both wings → first wing (B04A) wins.
      final both = await container.read(roomLookupProvider(('B04', '0301')).future);
      expect(both.status, RoomLookupStatus.found);
      expect(both.location!.plan.buildingCode, 'B04A');

      // 0407 is drawn only in B04B.
      final bOnly = await container.read(roomLookupProvider(('B04', '0407')).future);
      expect(bOnly.status, RoomLookupStatus.found);
      expect(bOnly.location!.plan.buildingCode, 'B04B');

      // Explicit wing still means that wing only.
      expect((await container.read(roomLookupProvider(('B04A', '0407')).future)).status,
          RoomLookupStatus.missingRoom);
    });

    test('status when no wing has the room', () async {
      expect((await container.read(roomLookupProvider(('B04', '0399')).future)).status,
          RoomLookupStatus.missingRoom);
      expect((await container.read(roomLookupProvider(('B04', '9901')).future)).status,
          RoomLookupStatus.missingPlan);
      expect((await container.read(roomLookupProvider(('S01', '0301')).future)).status,
          RoomLookupStatus.missingPlan);
    });

    test('floorKeyOf matches the plan index keys', () {
      expect(floorKeyOf('0306-1'), '3F');
      expect(floorKeyOf('B103-2'), 'B1F');
      expect(floorKeyOf('1203'), '12F');
      expect(floorKeyOf('1'), '');
    });

    testWidgets('room card resolves the wing for a plan-less deep link',
        (tester) async {
      await tester.runAsync(
          () => container.read(roomLookupProvider(('B04', '0407')).future));
      await tester.pumpWidget(
          host(const RoomLocationCard(facility: _b04, roomCode: '0407')));
      await tester.pump();

      expect(find.byType(FloorPlanView), findsOneWidget);
      expect(find.text('B04B-0407'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('L-31 floor labels', () {
    test('canonical keys are localised at display time', () {
      final ko = lookupAppLocalizations(const Locale('ko'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(localizedFloorLabel(ko, '3F'), '3층');
      expect(localizedFloorLabel(ko, '12F'), '12층');
      expect(localizedFloorLabel(ko, 'B1F'), '지하 1층');
      expect(localizedFloorLabel(en, '3F'), '3F');
      expect(localizedFloorLabel(en, 'B1F'), 'B1F');
      // Unknown shapes pass through untouched.
      expect(localizedFloorLabel(ko, 'RF'), 'RF');
      expect(localizedFloorLabel(ko, ''), '');
      // floorLabelOf stays the canonical key feeding the localisation.
      expect(localizedFloorLabel(ko, floorLabelOf('B110-1')!), '지하 1층');
    });

    testWidgets('room card header shows the Korean floor label',
        (tester) async {
      await tester.runAsync(
          () => container.read(roomLookupProvider(('S04', '0306-1')).future));
      await tester.pumpWidget(host(
          const RoomLocationCard(facility: _s04, roomCode: '0306-1'),
          locale: const Locale('ko')));
      await tester.pump();
      expect(find.text('3층'), findsOneWidget);
      expect(find.text('3F'), findsNothing);
    });
  });

  group('L-28 / L-30 floor plan view', () {
    testWidgets('pulse stops under reduce-motion and runs otherwise',
        (tester) async {
      final outlined = await tester.runAsync(
          () => container.read(roomLocationProvider(('S04', '0306-1')).future));
      final dotOnly = await tester.runAsync(
          () => container.read(roomLocationProvider(('B01', '0108')).future));
      expect(outlined!.room.outline, isNotNull);
      expect(dotOnly!.room.outline, isNull);
      expect(dotOnly.room.rect, isNull);

      for (final loc in [outlined, dotOnly]) {
        await tester.pumpWidget(host(
            FloorPlanView(plan: loc.plan, room: loc.room),
            reduceMotion: true));
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0,
            reason: 'no ticking under reduce-motion (${loc.room.code})');

        await tester.pumpWidget(host(
            FloorPlanView(plan: loc.plan, room: loc.room),
            reduceMotion: false));
        await tester.pump();
        expect(tester.binding.transientCallbackCount, greaterThan(0),
            reason: 'pulse running (${loc.room.code})');

        // Flipping the setting at runtime stops the running pulse.
        await tester.pumpWidget(host(
            FloorPlanView(plan: loc.plan, room: loc.room),
            reduceMotion: true));
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('drawing and highlight carry semantic labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      final loc = await tester.runAsync(
          () => container.read(roomLocationProvider(('S04', '0306-1')).future));
      await tester.pumpWidget(host(
          FloorPlanView(plan: loc!.plan, room: loc.room),
          locale: const Locale('ko')));
      await tester.pump();

      expect(find.bySemanticsLabel('S04 3층 도면'), findsOneWidget);
      expect(find.bySemanticsLabel('0306-1 위치'), findsOneWidget);

      await tester.pumpWidget(host(
          FloorPlanView(plan: loc.plan, room: loc.room),
          locale: const Locale('en')));
      await tester.pump();
      expect(find.bySemanticsLabel('S04 3F floor plan'), findsOneWidget);
      expect(find.bySemanticsLabel('Location of 0306-1'), findsOneWidget);
      handle.dispose();
    });
  });

  group('L-5 / L-33 full-screen plan', () {
    Future<InteractiveViewer> pumpScreen(WidgetTester tester) async {
      final loc = await tester.runAsync(
          () => container.read(roomLocationProvider(('S07', '0524-13')).future));
      await tester.pumpWidget(
          app(FloorPlanScreen(location: loc!, title: 'S07-0524-13')));
      await tester.pump();
      return tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    }

    testWidgets('viewport change keeps the zoom instead of resetting',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final viewer = await pumpScreen(tester);
      final ctrl = viewer.transformationController!;
      expect(ctrl.value.getMaxScaleOnAxis(), closeTo(2.5, 1e-6));

      // User zooms further in.
      ctrl.value = Matrix4.identity()
        ..translateByDouble(-900, -1400, 0, 1)
        ..scaleByDouble(4, 4, 1, 1);
      await tester.pump();

      // Rotate.
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();
      await tester.pump();
      expect(ctrl.value.getMaxScaleOnAxis(), closeTo(4, 1e-6));
      expect(tester.takeException(), isNull);

      // Recenter still works after the rotation.
      final labels =
          AppLocalizations.of(tester.element(find.byType(FloorPlanScreen)));
      await tester.tap(find.byTooltip(labels.classroom_plan_recenter));
      await tester.pump();
      expect(ctrl.value.getMaxScaleOnAxis(), closeTo(2.5, 1e-6));
    });

    testWidgets('rotation keeps the same plan point at the centre',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final viewer = await pumpScreen(tester);
      final ctrl = viewer.transformationController!;
      final loc = container.read(roomLocationProvider(('S07', '0524-13'))).value!;

      Offset centreInPlanFractions(Size viewport) {
        final ar = loc.plan.aspectRatio;
        final fit = viewport.width / viewport.height > ar
            ? Size(viewport.height * ar, viewport.height)
            : Size(viewport.width, viewport.width / ar);
        final o = Offset((viewport.width - fit.width) / 2,
            (viewport.height - fit.height) / 2);
        final scene = MatrixUtils.transformPoint(
            Matrix4.inverted(ctrl.value), viewport.center(Offset.zero));
        return Offset(
            (scene.dx - o.dx) / fit.width, (scene.dy - o.dy) / fit.height);
      }

      final box = tester.renderObject<RenderBox>(find.byType(InteractiveViewer));
      final before = centreInPlanFractions(box.size);
      expect(before.dx, closeTo(loc.room.x, 1e-6));
      expect(before.dy, closeTo(loc.room.y, 1e-6));

      // Pan away from the room, then rotate: the panned-to point stays.
      ctrl.value = ctrl.value.clone()..translateByDouble(-120, 80, 0, 1);
      await tester.pump();
      final panned = centreInPlanFractions(box.size);

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();
      await tester.pump();
      final after = centreInPlanFractions(
          tester.renderObject<RenderBox>(find.byType(InteractiveViewer)).size);
      expect(after.dx, closeTo(panned.dx, 1e-6));
      expect(after.dy, closeTo(panned.dy, 1e-6));
    });

    testWidgets('double-tap toggles between fitted and 2.5x at the tap point',
        (tester) async {
      final viewer = await pumpScreen(tester);
      final ctrl = viewer.transformationController!;
      expect(ctrl.value.getMaxScaleOnAxis(), closeTo(2.5, 1e-6));

      Future<void> doubleTapAt(Offset at) async {
        await tester.tapAt(at);
        await tester.pump(kDoubleTapMinTime);
        await tester.tapAt(at);
        await tester.pump();
      }

      final box = tester.renderObject<RenderBox>(find.byType(InteractiveViewer));
      final centre = box.localToGlobal(box.size.center(Offset.zero));

      // Zoomed in (initial focus) → back to the fitted plan.
      await doubleTapAt(centre);
      expect(ctrl.value, Matrix4.identity());

      // Fitted → 2.5x with the tapped point fixed on screen.
      final tap = centre + const Offset(60, -40);
      await doubleTapAt(tap);
      expect(ctrl.value.getMaxScaleOnAxis(), closeTo(2.5, 1e-6));
      final local = box.globalToLocal(tap);
      final mapped = MatrixUtils.transformPoint(ctrl.value, local);
      expect(mapped.dx, closeTo(local.dx, 1e-6));
      expect(mapped.dy, closeTo(local.dy, 1e-6));

      // And back again.
      await doubleTapAt(centre);
      expect(ctrl.value, Matrix4.identity());
      expect(tester.takeException(), isNull);
      // Let the tap recogniser's double-tap window expire.
      await tester.pump(kDoubleTapTimeout);
    });
  });

  group('L-7c/d classroom search screen', () {
    // Explicit frames instead of pumpAndSettle: the dropdown menu's open /
    // close transitions are what we wait for here.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> pickBuilding(WidgetTester tester, String label) async {
      await tester.tap(find.byType(TextField).first);
      await settle(tester);
      await tester.tap(find.text(label).last);
      await settle(tester);
    }

    // A family instance first created inside the test's fake-async zone
    // never leaves AsyncLoading (its awaited bundle future resolved in the
    // real zone), so the instances the screen will watch are resolved — and
    // kept alive — before pumping. The same pattern as floor_plan_view_test.
    Future<List<ClassroomEntry>> warmUp(WidgetTester tester) async {
      final entries = classroomEntriesProvider(('s04', 'S04'));
      return (await tester.runAsync(() async {
        await container.read(floorPlansProvider.future);
        // listen() inside runAsync so the instance is created in the real
        // zone too; closed on tear-down.
        final sub = container.listen(entries, (_, __) {});
        addTearDown(sub.close);
        return container.read(entries.future);
      }))!;
    }

    testWidgets('wing entries are labelled apart and long lists say "more"',
        (tester) async {
      final entries = await warmUp(tester);
      await tester.pumpWidget(app(const ClassroomSearchScreen()));
      await settle(tester);

      // Open the dropdown: B04 is listed per wing with distinct names.
      await tester.tap(find.byType(TextField).first);
      await settle(tester);
      expect(find.text('B04A · General Lecture Building (BA-BD) · Wing A'),
          findsWidgets);
      expect(find.text('B04B · General Lecture Building (BA-BD) · Wing B'),
          findsWidgets);
      expect(find.text('S04 · Engineering Building 2'), findsWidgets);
      await tester.tap(find.text('S04 · Engineering Building 2').last);
      await settle(tester);

      // S04 has 131 drawn rooms → 60 shown, the rest announced.
      expect(entries.length, greaterThan(60));
      expect(find.byType(Card), findsNWidgets(60));
      final labels = AppLocalizations.of(
          tester.element(find.byType(ClassroomSearchScreen)));
      expect(find.text(labels.classroom_suggestions_more(entries.length - 60)),
          findsOneWidget);

      // Narrowing the input removes the note.
      await tester.enterText(find.byType(TextField).last, '0306');
      await settle(tester);
      expect(find.textContaining('more'), findsNothing);
      expect(find.byType(Card), findsWidgets);
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('pasting a full code with an en dash keeps the room half',
        (tester) async {
      await warmUp(tester);
      await tester.pumpWidget(app(const ClassroomSearchScreen()));
      await settle(tester);
      await pickBuilding(tester, 'S04 · Engineering Building 2');

      final room = find.byType(TextField).last;
      await tester.enterText(room, 'S04–0306-1');
      await settle(tester);
      expect(tester.widget<TextField>(room).controller!.text, '0306-1');

      await tester.enterText(room, 'ｓ０４－０３０６');
      await settle(tester);
      expect(tester.widget<TextField>(room).controller!.text, '0306');

      // Longest real code still fits.
      await tester.enterText(room, '0501-10');
      await settle(tester);
      expect(tester.widget<TextField>(room).controller!.text, '0501-10');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
