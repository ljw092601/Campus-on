import 'dart:convert';

import 'package:campus_on/app.dart' show IntroOverlay;
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/main.dart' as app;
import 'package:campus_on/presentation/home/home_screen.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/map/widgets/campus_map_view.dart';
import 'package:campus_on/presentation/map/widgets/peek_sheet.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Device check for the audit Medium fixes M-7, M-8, M-10, M-20 and M-24.
// Run via tool/run_map_e2e.py --test medium: it grants location permission and
// injects the far-away / on-campus GPS fixes at the E2E_GPS_* checkpoints.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('intro skip, sheet dismiss, link refocus, favorites migration, '
      'far GPS', (tester) async {
    Future<void> until(Future<bool> Function() condition, String description,
        {int seconds = 35}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (await condition()) return;
      }
      fail('Timed out: $description');
    }

    ProviderContainer containerOf(Type screen) =>
        ProviderScope.containerOf(tester.element(find.byType(screen)));
    CampusMapView view() =>
        tester.widget<CampusMapView>(find.byType(CampusMapView));
    AppLocalizations labels() =>
        AppLocalizations.of(tester.element(find.byType(MapScreen)));
    WebViewController web() => WebViewController.fromPlatform(tester
        .widget<WebViewWidget>(find.byType(WebViewWidget))
        .platform
        .params
        .controller);
    Future<dynamic> js(String expression) async {
      dynamic value = await web()
          .runJavaScriptReturningResult('JSON.stringify($expression)');
      for (var i = 0; i < 2 && value is String; i++) {
        value = jsonDecode(value);
      }
      return value;
    }

    Future<Map<String, double>> center() async {
      final c = await js(
          '({lat:map.getCenter().getLat(),lng:map.getCenter().getLng()})');
      return {
        'lat': (c['lat'] as num).toDouble(),
        'lng': (c['lng'] as num).toDouble()
      };
    }

    Future<List<dynamic>> overlays() async => (await js(
            'customOverlays.filter(o => o.getMap() !== null).map(o => ({'
            'id:o.id, lat:o.getPosition().getLat(), lng:o.getPosition().getLng()}))'))
        as List<dynamic>;
    Future<void> mapReady() => until(() async {
          try {
            await center();
            return true;
          } catch (_) {
            return false;
          }
        }, 'Kakao SDK ready', seconds: 60);

    void passed(String name) => debugPrint('E2E_PASS $name');

    // M-20: seed a legacy favorite (old S12 id "p4") before the app boots.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'favorites_v1',
        jsonEncode([
          {
            'type': 'facility',
            'id': 'p4',
            'savedAt': '2026-09-01T09:00:00.000Z',
          }
        ]));

    // M-7: the intro absorbs taps and a tap skips it well before the clip ends.
    final booted = DateTime.now();
    await app.main();
    await until(
        () async => find
            .descendant(
                of: find.byType(IntroOverlay),
                matching: find.byType(AnimatedOpacity))
            .evaluate()
            .isNotEmpty,
        'intro overlay', seconds: 20);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(IntroOverlay));
    // IntroOverlay stays in the tree as the app's host; its fading sheet
    // (the AnimatedOpacity layer) is what disappears once the intro is gone.
    final sheet = find.descendant(
        of: find.byType(IntroOverlay), matching: find.byType(AnimatedOpacity));
    await until(() async => sheet.evaluate().isEmpty, 'intro skipped by tap',
        seconds: 5);
    final skippedAfter = DateTime.now().difference(booted);
    expect(find.byType(HomeScreen), findsOneWidget);
    debugPrint('E2E_INFO intro gone ${skippedAfter.inMilliseconds}ms after boot');
    passed('M7_intro_tap_to_skip');

    // M-20: the legacy id was migrated in memory and on disk, exactly once.
    final favorites =
        await containerOf(HomeScreen).read(favoritesProvider.future);
    expect(favorites, contains('facility:s12'));
    expect(favorites, isNot(contains('facility:p4')));
    await until(() async {
      final raw = prefs.getString('favorites_v1') ?? '';
      return raw.contains('"s12"') && !raw.contains('"p4"');
    }, 'favorites store rewritten with s12');
    passed('M20_legacy_favorite_migrated');

    // M-10: "view on map" from a facility detail carries a fresh token, so a
    // second visit to the same building re-focuses after the sheet was closed.
    final all =
        await containerOf(HomeScreen).read(allFacilitiesProvider.future);
    final building = all.firstWhere((f) => f.buildingCode == 'S04');
    Future<void> viewOnMapFromDetail() async {
      AppRouter.router.go('/map/facility/${building.id}');
      await tester.pump(const Duration(milliseconds: 400));
      final l = AppLocalizations.of(tester.element(find.byType(Scaffold).last));
      final button = find.text(l.facility_action_viewOnMap);
      await until(() async => button.evaluate().isNotEmpty, 'detail map button');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await until(() async => find.byType(MapScreen).evaluate().length == 1,
          'map route');
      await mapReady();
      await until(() async => view().selectedId == building.id,
          'building focused from detail');
      await until(() async => find.byType(PeekSheet).evaluate().isNotEmpty,
          'peek sheet for focused building');
    }

    await viewOnMapFromDetail();
    passed('M10_detail_link_focuses');

    // M-8: a bare-map tap (real Kakao click event) dismisses the sheet.
    await web().runJavaScript(
        "kakao.maps.event.trigger(map, 'click', {latLng: map.getCenter()})");
    await until(() async => view().selectedId == null, 'map tap deselects');
    await until(() async => find.byType(PeekSheet).evaluate().isEmpty,
        'sheet gone after map tap');
    passed('M8_map_tap_dismisses_sheet');

    // Same building again: without the token the map would ignore this link.
    await viewOnMapFromDetail();
    passed('M10_same_building_refocuses');

    // M-8: the close button on the sheet.
    final close = find.byTooltip(labels().common_close);
    await tester.ensureVisible(close);
    await tester.tap(close);
    await until(() async => view().selectedId == null, 'close button deselects');
    await until(() async => find.byType(PeekSheet).evaluate().isEmpty,
        'sheet gone after close button');
    passed('M8_close_button_dismisses_sheet');

    // M-24: a fix far from every campus keeps the camera and shows the notice.
    final before = await center();
    debugPrint('E2E_GPS_PERMISSION');
    await until(() async {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    }, 'location permission from host');
    debugPrint('E2E_GPS_FAR');
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byTooltip(labels().map_myLocation_tooltip));
    await until(
        () async =>
            find.text(labels().map_location_farFromCampus).evaluate().isNotEmpty,
        'far-from-campus notice');
    await until(() async {
      final dots = (await overlays())
          .where((o) => (o['id'] as String).startsWith('user-location-dot-'))
          .toList();
      return dots.length == 1 && ((dots.single['lat'] as num) - 37.5).abs() < .01;
    }, 'blue dot drawn at the far fix');
    final after = await center();
    expect(after['lat'], closeTo(before['lat']!, 0.01),
        reason: 'camera must not leave campus for a far fix');
    expect(after['lng'], closeTo(before['lng']!, 0.01));
    expect(view().following, isFalse);
    passed('M24_far_fix_keeps_campus_camera');

    // Back on campus: an explicit FAB press follows again.
    debugPrint('E2E_GPS_FIX_0');
    await until(() async {
      final dots = (await overlays())
          .where((o) => (o['id'] as String).startsWith('user-location-dot-'))
          .toList();
      return dots.length == 1 && ((dots.single['lat'] as num) - 35.115).abs() < .001;
    }, 'blue dot back on campus');
    await tester.tap(find.byTooltip(labels().map_myLocation_tooltip));
    await until(() async {
      final c = await center();
      return (c['lat']! - 35.115).abs() < .001 && (c['lng']! - 128.968).abs() < .001;
    }, 'camera follows the on-campus fix');
    passed('M24_near_fix_follows_again');

    expect(tester.takeException(), isNull);
    debugPrint('E2E_MEDIUM_COMPLETE');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
