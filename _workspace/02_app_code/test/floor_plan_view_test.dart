import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/floor_plan_screen.dart';
import 'package:campus_on/presentation/classroom/widgets/floor_plan_view.dart';
import 'package:campus_on/presentation/classroom/widgets/room_location_card.dart';
import 'package:campus_on/presentation/providers/floor_plan_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
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
    expect(find.textContaining(RegExp('도면|floor plan')), findsOneWidget);
  });

  testWidgets('full-screen plan lays out and zooms onto the room',
      (tester) async {
    final loc = await tester.runAsync(
        () => container.read(roomLocationProvider(('S07', '0524-13')).future));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FloorPlanScreen(location: loc!, title: 'S07-0524-13'),
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
}
