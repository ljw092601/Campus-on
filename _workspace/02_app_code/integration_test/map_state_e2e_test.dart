import 'dart:convert';

import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/entities/user_location.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/main.dart' as app;
import 'package:campus_on/presentation/classroom/widgets/room_location_card.dart';
import 'package:campus_on/presentation/classroom/classroom_search_screen.dart';
import 'package:campus_on/presentation/classroom/floor_plan_screen.dart';
import 'package:campus_on/presentation/classroom/widgets/floor_plan_view.dart';
import 'package:campus_on/presentation/facility/facility_detail_screen.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/map/widgets/campus_map_view.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/locale_provider.dart';
import 'package:campus_on/presentation/shared/category_labels.dart';
import 'package:campus_on/presentation/shared/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Run via tool/run_map_e2e.py: it grants location permission and supplies real
// emulator GPS fixes when the corresponding E2E_GPS_* checkpoint is printed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('map state: real Kakao WebView, navigation and native GPS',
      (tester) async {
    Future<void> until(Future<bool> Function() condition, String description,
        {int seconds = 35}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (await condition()) return;
      }
      fail('Timed out: $description');
    }

    CampusMapView view() =>
        tester.widget<CampusMapView>(find.byType(CampusMapView));
    ProviderContainer container() =>
        ProviderScope.containerOf(tester.element(find.byType(MapScreen)));
    AppLocalizations labels() =>
        AppLocalizations.of(tester.element(find.byType(MapScreen)));
    WebViewController web() => WebViewController.fromPlatform(tester
        .widget<WebViewWidget>(find.byType(WebViewWidget))
        .platform
        .params
        .controller);
    Future<dynamic> js(String expression) async {
      var value = await web()
          .runJavaScriptReturningResult('JSON.stringify($expression)');
      // Android returns a JSON string literal, iOS may return its contents.
      for (var i = 0; i < 2 && value is String; i++) {
        value = jsonDecode(value);
      }
      return value;
    }

    Future<List<dynamic>> markers() async =>
        (await js('markers.filter(m => m.getMap() !== null).map(m => m.id)'))
            as List<dynamic>;
    Future<List<dynamic>> overlays() async => (await js(
            'customOverlays.filter(o => o.getMap() !== null).map(o => ({'
            'id:o.id, lat:o.getPosition().getLat(), lng:o.getPosition().getLng()}))'))
        as List<dynamic>;
    Future<void> route(String path) async {
      AppRouter.router.go(path);
      await tester.pump(const Duration(milliseconds: 300));
      if (path.startsWith('/map')) {
        await until(() async => find.byType(MapScreen).evaluate().length == 1,
            'map route transition');
      }
    }

    Future<void> tapCampus(Campus campus) async {
      await tester.tap(find.text(campus.label(labels())).first);
      await until(() async => container().read(mapCampusProvider) == campus,
          'campus selection');
      await tester.pump(const Duration(milliseconds: 500));
    }

    void passed(String name) => debugPrint('E2E_PASS $name');

    await app.main();
    await tester.pump(const Duration(seconds: 6));
    await route('/map');
    await until(() async => find.byType(WebViewWidget).evaluate().isNotEmpty,
        'WebView creation');
    await until(() async {
      try {
        return (await markers()).isNotEmpty;
      } catch (_) {
        return false;
      }
    }, 'Kakao SDK and campus pins', seconds: 60);
    final all = await container().read(allFacilitiesProvider.future);
    final building = all.firstWhere((f) => f.buildingCode == 'S04');
    final locale = container().read(localeProvider);
    passed('map_boot');

    final emptyCategory = FacilityCategory.values.firstWhere((category) =>
        !all.any((f) =>
            f.category == category &&
            (f.campus == null || f.campus == Campus.seunghak)));
    final chip = find.byWidgetPredicate(
        (w) => w is CategoryChip && w.label == emptyCategory.label(labels()));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await until(
        () async => (await markers()).isEmpty, 'empty filter clears JS pins');
    passed('M1_empty_filter');

    // Use the actual dropdown, text field and submit button with filter active.
    final l = labels();
    await route('/classroom-search');
    await until(() async => find.byType(TextField).evaluate().length == 2,
        'classroom form');
    await tester.tap(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 500));
    final choice = find.text('S04 · ${building.name(locale)}').last;
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    final roomField = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == l.classroom_hint_room);
    await tester.enterText(roomField, '0306-1');
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pump(const Duration(milliseconds: 300));
    await tester
        .tap(find.widgetWithText(FilledButton, l.classroom_action_search));
    await until(() async => find.byType(RoomLocationCard).evaluate().isNotEmpty,
        'classroom result card');
    await until(
        () async => (await overlays())
            .any((o) => o['id'] == 'room-target-${building.id}'),
        'classroom red overlay');
    expect(container().read(facilityCategoryFilterProvider), isNull);
    expect(view().selectedId, building.id);
    expect(view().campus, Campus.seunghak);
    passed('H1_filtered_classroom_search');

    // Real route transitions must retain both the WebView and search form.
    final mapState = tester.state(find.byType(MapScreen));
    final camera = await js(
        '[map.getCenter().getLat(),map.getCenter().getLng(),map.getLevel()]');
    final plan = find.descendant(
        of: find.byType(RoomLocationCard),
        matching: find.byType(FloorPlanView));
    await until(() async => plan.evaluate().isNotEmpty, 'room floor plan');
    await tester.ensureVisible(plan);
    await tester.tap(plan);
    await until(() async => find.byType(FloorPlanScreen).evaluate().isNotEmpty,
        'full-screen plan');
    await tester.pump(const Duration(milliseconds: 500));
    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final focused = viewer.transformationController!.value.clone();
    await tester.drag(find.byType(InteractiveViewer), const Offset(90, 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(viewer.transformationController!.value, isNot(focused));
    await tester.tap(find.byTooltip(l.classroom_plan_recenter));
    await tester.pump(const Duration(milliseconds: 300));
    expect(viewer.transformationController!.value, focused);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    passed('M3_floor_plan_recenter');

    final detail = find.text(l.map_peek_viewDetail);
    await tester.scrollUntilVisible(detail, -200,
        scrollable: find
            .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(detail);
    await until(
        () async => find.byType(FacilityDetailScreen).evaluate().isNotEmpty,
        'facility detail');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.state(find.byType(MapScreen)), same(mapState));
    expect(
        await js(
            '[map.getCenter().getLat(),map.getCenter().getLng(),map.getLevel()]'),
        camera);
    expect(
        (await overlays()).any((o) => o['id'] == 'room-target-${building.id}'),
        isTrue);
    expect(find.byType(RoomLocationCard), findsOneWidget);
    passed('M13_detail_back_preserves_classroom_map');

    await tester.binding.handlePopRoute();
    await until(
        () async => find.byType(ClassroomSearchScreen).evaluate().isNotEmpty,
        'return to classroom form');
    expect(tester.widget<TextField>(roomField).controller!.text, '0306-1');
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        startsWith('S04'));
    await tester
        .tap(find.widgetWithText(FilledButton, l.classroom_action_search));
    await until(() async {
      try {
        return (await overlays())
            .any((o) => o['id'] == 'room-target-${building.id}');
      } catch (_) {
        return false;
      }
    }, 'resubmitted classroom target');
    passed('M11_classroom_back_and_resubmit');

    await tapCampus(Campus.bumin);
    await tapCampus(Campus.seunghak);
    expect(view().selectedId, isNull);
    expect(view().focusIds, isEmpty);
    expect(find.byType(RoomLocationCard), findsNothing);
    await until(
        () async => (await overlays())
            .every((o) => !(o['id'] as String).startsWith('room-target-')),
        'old target cleared');
    passed('M29_consumed_focus');

    await route('/map?focus=missing-e2e&t=missing');
    await until(
        () async =>
            find.text(labels().map_focus_notFound).evaluate().isNotEmpty,
        'missing building message');
    await tapCampus(Campus.bumin);
    expect(view().selectedId, isNull);
    final center = await js(
        '({lat:map.getCenter().getLat(),lng:map.getCenter().getLng()})');
    expect((center['lat'] as num).toDouble(), closeTo(35.104, 0.02));
    passed('M9_missing_focus_campus_recovery');

    for (final token in ['repeat-1', 'repeat-2']) {
      await web()
          .runJavaScript('map.setCenter(new kakao.maps.LatLng(35.2,129.1));');
      await route(
          '/map?focus=${building.id}&floor=03&room=0306-1&plan=S04&t=$token');
      await until(
          () async =>
              view().focusIds.isEmpty && view().selectedId == building.id,
          'focus consumed for $token');
      final c = await js(
          '({lat:map.getCenter().getLat(),lng:map.getCenter().getLng()})');
      expect((c['lng'] as num).toDouble(), closeTo(building.lng, 0.002));
    }
    passed('repeat_search_refocus');

    await route('/map?nearby=${Uri.encodeComponent('카페')}');
    await until(() async => view().places.isNotEmpty, 'live Kakao cafe search');
    await until(
        () async =>
            (await markers()).any((id) => (id as String).startsWith('place:')),
        'live nearby markers');
    passed('nearby_live_results');
    await route('/map');
    await until(
        () async =>
            view().places.isEmpty &&
            (await markers())
                .every((id) => !(id as String).startsWith('place:')),
        'nearby removal clears Flutter and JS state');
    await route('/map?nearby=${Uri.encodeComponent('은행')}');
    await until(
        () async => view().places.isNotEmpty, 'new nearby query in open map');
    expect(view().placeQueries, ['은행']);
    passed('M2_clear_and_new_nearby_query');

    await route('/map?nearby=${Uri.encodeComponent('편의점')}');
    await route('/map');
    await tester.pump(const Duration(seconds: 3));
    expect(view().places, isEmpty);
    expect((await markers()).where((id) => (id as String).startsWith('place:')),
        isEmpty);
    passed('nearby_late_response_ignored');

    // Native GPS: the host runner grants permission and injects each fix.
    debugPrint('E2E_GPS_PERMISSION');
    await until(() async {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    }, 'location permission from host');
    await tester.tap(find.byTooltip(labels().map_myLocation_tooltip));
    for (var i = 0; i < 3; i++) {
      final lat = 35.115 + i * 0.001;
      final lng = 128.968 + i * 0.001;
      debugPrint('E2E_GPS_FIX_$i');
      await until(() async {
        final dots = (await overlays())
            .where((o) => (o['id'] as String).startsWith('user-location-dot-'))
            .toList();
        if (dots.length != 1) return false;
        return ((dots.single['lat'] as num) - lat).abs() < 0.0001 &&
            ((dots.single['lng'] as num) - lng).abs() < 0.0001;
      }, 'native GPS dot fix $i');
      final c = await js(
          '({lat:map.getCenter().getLat(),lng:map.getCenter().getLng()})');
      expect((c['lat'] as num).toDouble(), closeTo(lat, 0.0001));
    }
    passed('H2_native_GPS_three_fixes');

    // Emulator GPS accuracy is usually 5m (the app deliberately hides halos
    // below 15m). Exercise wider accuracy fixes on the REAL WebView separately.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    Widget locationFixture(UserLocation? location) => MaterialApp(
          home: Scaffold(
              body: CampusMapView(
            facilities: [building],
            focusIds: const [],
            onMarkerTap: (_) {},
            userLocation: location,
            following: false,
          )),
        );
    for (var i = 0; i < 2; i++) {
      final lat = 35.118 + i * .001;
      final lng = 128.971 + i * .001;
      final accuracy = 60.0 + i * 60;
      await tester.pumpWidget(locationFixture(
          UserLocation(lat: lat, lng: lng, accuracyMeters: accuracy)));
      await until(() async {
        try {
          final rings =
              await js('circles.map(c => ({lat:c.getPosition().getLat(),'
                      'lng:c.getPosition().getLng(),radius:c.getRadius()}))')
                  as List;
          final dots = await overlays();
          return rings.length == 1 &&
              dots.length == 1 &&
              ((rings.single['lat'] as num) - lat).abs() < .0001 &&
              ((rings.single['lng'] as num) - lng).abs() < .0001 &&
              ((dots.single['lat'] as num) - lat).abs() < .0001 &&
              rings.single['radius'] == accuracy;
        } catch (_) {
          return false;
        }
      }, 'real WebView accuracy halo fix $i');
    }
    await tester.pumpWidget(locationFixture(null));
    await until(
        () async =>
            (await js('circles.length')) == 0 && (await overlays()).isEmpty,
        'location overlays removed');
    passed('H2_real_WebView_halo_update_and_clear');
    expect(tester.takeException(), isNull);
    debugPrint('E2E_MAP_COMPLETE');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
