import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/floor_plan_screen.dart';
import 'package:campus_on/presentation/classroom/widgets/floor_plan_view.dart';
import 'package:campus_on/presentation/classroom/widgets/room_location_card.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/shared/widgets/floor_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  });
  tearDown(() => container.dispose());

  Widget host(Widget child) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  const s04 = Facility(
    id: 's04',
    nameKo: '공과대학2호관',
    nameEn: 'Engineering Building 2',
    category: FacilityCategory.building,
    lat: 0,
    lng: 0,
    buildingCode: 'S04',
    hasFloorInfo: true,
  );

  testWidgets('room card shows the plan with the room highlighted',
      (tester) async {
    await tester.runAsync(
        () => container.read(roomLocationProvider(('S04', '0306-1')).future));
    await tester.pumpWidget(
        host(const RoomLocationCard(facility: s04, roomCode: '0306-1')));
    await tester.pump();

    expect(find.text('S04-0306-1'), findsOneWidget);
    expect(find.text('3F'), findsOneWidget);
    expect(find.byType(FloorPlanView), findsOneWidget);
  });

  testWidgets('unknown room falls back to the notice', (tester) async {
    await tester.runAsync(
        () => container.read(roomLocationProvider(('S04', '0399')).future));
    await tester.pumpWidget(
        host(const RoomLocationCard(facility: s04, roomCode: '0399')));
    await tester.pump();

    expect(find.byType(FloorPlanView), findsNothing);
    final labels =
        AppLocalizations.of(tester.element(find.byType(RoomLocationCard)));
    expect(find.text(labels.classroom_room_notFound), findsOneWidget);
  });

  testWidgets('full-screen plan lays out and zooms onto the room',
      (tester) async {
    final loc = await tester.runAsync(
        () => container.read(roomLocationProvider(('S07', '0501-10')).future));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FloorPlanScreen(location: loc!, title: 'S07-0501-10'),
      ),
    ));
    await tester.pump();

    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 2.5);
    final original = viewer.transformationController!.value.clone();
    viewer.transformationController!.value = Matrix4.identity();
    await tester.pump();
    final labels =
        AppLocalizations.of(tester.element(find.byType(FloorPlanScreen)));
    final recenter = find.byTooltip(labels.classroom_plan_recenter);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((w) =>
                w is IconButton && w.tooltip == labels.classroom_plan_recenter))
            .onPressed,
        isNotNull);
    await tester.tap(recenter);
    await tester.pump();
    expect(viewer.transformationController!.value, original);
    expect(tester.takeException(), isNull);
  });

  // Own container, disposed inside the test: the floor-guide provider's cache
  // timer must not outlive it. The plan index is an asset load (real I/O),
  // so it is warmed up in runAsync first.
  Future<void> pumpGuide(
      WidgetTester tester, ProviderContainer c, FloorAccordion child) async {
    await tester.runAsync(() => c.read(floorPlansProvider.future));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> disposeGuide(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  }

  testWidgets('floor guide shows the floor drawing and opens it full screen',
      (tester) async {
    final c = ProviderContainer();
    await pumpGuide(
        tester,
        c,
        const FloorAccordion(
            facilityId: 's04', buildingCode: 'S04', title: '공과대학2호관'));

    // Collapsed: no drawing yet.
    expect(find.byType(FloorPlanView), findsNothing);
    await tester.tap(find.text('3F'));
    await tester.pumpAndSettle();
    expect(find.byType(FloorPlanView), findsOneWidget);
    // With a drawing the room names start folded behind a toggle.
    expect(find.textContaining(' · '), findsNothing);
    await tester.ensureVisible(find.text('Show room names'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show room names'));
    await tester.pumpAndSettle();
    expect(find.textContaining(' · '), findsOneWidget);
    expect(find.text('Hide room names'), findsOneWidget);

    await tester.ensureVisible(find.byType(FloorPlanView));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloorPlanView));
    await tester.pumpAndSettle();
    expect(find.byType(FloorPlanScreen), findsOneWidget);
    // No room on a floor-guide plan → no "back to the room" action.
    expect(find.byTooltip('Back to the room'), findsNothing);
    await disposeGuide(tester, c);
  });

  testWidgets('split building shows one drawing per wing with its code',
      (tester) async {
    final c = ProviderContainer();
    await pumpGuide(
        tester,
        c,
        const FloorAccordion(
            facilityId: 'b04', buildingCode: 'B04', expandedFloor: '3F'));
    expect(find.byType(FloorPlanView), findsNWidgets(2));
    expect(find.text('B04A'), findsOneWidget);
    expect(find.text('B04B'), findsOneWidget);
    await disposeGuide(tester, c);
  });
}
