import 'dart:async';
import 'dart:convert';

import 'package:campus_on/core/config/app_config.dart';
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/entities/nearby_place.dart';
import 'package:campus_on/domain/entities/user_location.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/map/widgets/campus_map_view.dart';
import 'package:campus_on/presentation/map/widgets/campus_selector.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

const _s = Facility(
    id: 's',
    nameKo: '승학',
    nameEn: 'Seunghak',
    category: FacilityCategory.building,
    lat: 35.115,
    lng: 128.968,
    campus: Campus.seunghak);
const _b = Facility(
    id: 'b',
    nameKo: '부민',
    nameEn: 'Bumin',
    category: FacilityCategory.building,
    lat: 35.104,
    lng: 129.019,
    campus: Campus.bumin);

class _WebPlatform extends WebViewPlatform {
  late _WebController controller;
  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      controller = _WebController(params);
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _WebWidget(params);
}

class _WebWidget extends PlatformWebViewWidget {
  _WebWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _WebController extends PlatformWebViewController {
  _WebController(super.params) : super.implementation();
  final scripts = <String>[];
  final channels = <String, JavaScriptChannelParams>{};
  Completer<void>? markerBlock;
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    channels[params.name] = params;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    scripts.add(javaScript);
    if (javaScript.startsWith('addMarker(')) await markerBlock?.future;
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async =>
      jsonEncode({
        'sw': {'latitude': 35.10, 'longitude': 128.96},
        'ne': {'latitude': 35.12, 'longitude': 128.98}
      });

  void send(String name, Map<String, dynamic> data) => channels[name]!
      .onMessageReceived(JavaScriptMessage(message: jsonEncode(data)));

  List<Map<String, dynamic>> get searches => [
        for (final script in scripts)
          if (script.contains('const request = '))
            jsonDecode(RegExp(r'const request = (.*);').firstMatch(script)![1]!)
                as Map<String, dynamic>,
      ];
  void reply(int id, String place, {String status = 'OK'}) =>
      send('onCustomOverlayTap', {
        'latitude': 0.1,
        'longitude': 0.1,
        'customOverlayId': 'campus-nearby:${jsonEncode({
              'id': id,
              'status': status,
              'rows': [
                {'id': place, 'place_name': place, 'x': '128.97', 'y': '35.11'}
              ]
            })}',
      });
}

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Future<void> _flush(WidgetTester tester) async {
  // Allow asset reads and post-frame request preparation without waiting on
  // network-backed nearby requests or pulsing classroom animations.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  late _WebPlatform platform;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    kakao.AuthRepository.initialize(appKey: 'test-key');
    platform = _WebPlatform();
    WebViewPlatform.instance = platform;
  });

  testWidgets('SDK timeout offers retry; late callbacks cannot revive old map',
      (tester) async {
    final failures = <bool>[];
    var openedList = false;
    final taps = <String>[];
    await tester.pumpWidget(_app(CampusMapView(
      facilities: const [_s],
      focusIds: const [],
      onMarkerTap: taps.add,
      loadTimeout: const Duration(seconds: 1),
      onLoadFailureChanged: failures.add,
      onOpenList: () => openedList = true,
    )));
    await _flush(tester);
    final old = platform.controller;
    final oldMap = tester.widget<kakao.KakaoMap>(find.byType(kakao.KakaoMap));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(kakao.KakaoMap), findsNothing);
    old.send('onMapCreated', {});
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(CampusMapView)));
    await tester.tap(find.text(l.map_error_openList));
    expect(openedList, isTrue);
    await tester.tap(find.text('Retry'));
    await _flush(tester);
    expect(platform.controller, isNot(same(old)));
    platform.controller.send('onMapCreated', {});
    oldMap.onMarkerTap?.call('stale', kakao.LatLng(35, 129), 3);
    expect(taps, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(kakao.KakaoMap), findsOneWidget);
    expect(failures, [true, false, false]);
  });

  testWidgets('disposing a loading map cancels its timeout', (tester) async {
    final failures = <bool>[];
    await tester.pumpWidget(_app(CampusMapView(
      facilities: const [_s],
      focusIds: const [],
      onMarkerTap: (_) {},
      loadTimeout: const Duration(seconds: 1),
      onLoadFailureChanged: failures.add,
    )));
    await _flush(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(failures, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS moves dot and halo even when camera follow is off',
      (tester) async {
    Widget view(UserLocation location) => _app(CampusMapView(
          facilities: const [_s],
          focusIds: const [],
          onMarkerTap: (_) {},
          userLocation: location,
        ));
    await tester.pumpWidget(
        view(const UserLocation(lat: 35.11, lng: 128.96, accuracyMeters: 40)));
    await _flush(tester);
    platform.controller.send('onMapCreated', {});
    await _flush(tester);
    final first = tester.widget<kakao.KakaoMap>(find.byType(kakao.KakaoMap));
    await tester.pumpWidget(
        view(const UserLocation(lat: 35.12, lng: 128.97, accuracyMeters: 70)));
    await _flush(tester);
    final second = tester.widget<kakao.KakaoMap>(find.byType(kakao.KakaoMap));
    expect(second.customOverlays!.single.customOverlayId,
        isNot(first.customOverlays!.single.customOverlayId));
    expect(second.customOverlays!.single.latLng.latitude, 35.12);
    expect(
        second.circles!.single.circleId, isNot(first.circles!.single.circleId));
    expect(second.circles!.single.radius, 70);
    expect(platform.controller.scripts.where((s) => s.startsWith('setCenter(')),
        isEmpty);
  });

  testWidgets('empty markers clear after an older in-flight marker batch',
      (tester) async {
    Widget view(List<Facility> facilities) => _app(CampusMapView(
          facilities: facilities,
          focusIds: const [],
          onMarkerTap: (_) {},
        ));
    await tester.pumpWidget(view(const [_s, _b]));
    await _flush(tester);
    final web = platform.controller;
    web.markerBlock = Completer<void>();
    web.send('onMapCreated', {});
    await tester.pump();
    await tester.pumpWidget(view(const []));
    await tester.pump();
    web.markerBlock!.complete();
    await _flush(tester);
    final markerCommands = web.scripts
        .where(
            (s) => s.startsWith('addMarker(') || s.startsWith('clearMarker('))
        .toList();
    expect(markerCommands.last, 'clearMarker();');
  });

  testWidgets('new nearby request wins; clearing ignores late responses',
      (tester) async {
    final results = <List<NearbyPlace>>[];
    Widget view(List<String> queries) => _app(CampusMapView(
          facilities: const [_s],
          focusIds: const [],
          onMarkerTap: (_) {},
          placeQueries: queries,
          onPlacesFound: results.add,
        ));
    await tester.pumpWidget(view(const ['old']));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    await tester.pumpWidget(view(const ['new']));
    await _flush(tester);
    expect(web.searches.length, 2);
    web.reply(web.searches[1]['id'] as int, 'new-result');
    await _flush(tester);
    web.reply(web.searches[0]['id'] as int, 'old-result');
    await _flush(tester);
    expect(results.map((r) => r.single.id), ['new-result']);
    await tester.pumpWidget(view(const ['third']));
    await _flush(tester);
    final third = web.searches.last['id'] as int;
    await tester.pumpWidget(view(const []));
    web.reply(third, 'stale');
    await _flush(tester);
    expect(results.length, 1);
  });

  testWidgets('nearby timeout and zero results finish without hanging',
      (tester) async {
    var failures = 0;
    List<NearbyPlace>? results;
    Widget view(String query) => _app(CampusMapView(
          facilities: const [_s],
          focusIds: const [],
          onMarkerTap: (_) {},
          placeQueries: [query],
          onPlacesFailed: () => failures++,
          onPlacesFound: (value) => results = value,
        ));
    await tester.pumpWidget(view('timeout'));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    final old = web.searches.single['id'] as int;
    await tester.pump(const Duration(seconds: 11));
    expect(failures, 1);
    await tester.pumpWidget(view('empty'));
    await _flush(tester);
    web.reply(old, 'late');
    web.reply(web.searches.last['id'] as int, '', status: 'ZERO_RESULT');
    await _flush(tester);
    expect(results, isEmpty);
    expect(failures, 1);
  });

  testWidgets(
      'focus resets filter, switches campus and stays consumed after user changes',
      (tester) async {
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allFacilitiesProvider.overrideWith((ref) async => const [_s, _b]),
    ]);
    addTearDown(container.dispose);
    container.read(facilityCategoryFilterProvider.notifier).state =
        FacilityCategory.dining;
    Widget screen(String token) => UncontrolledProviderScope(
        container: container,
        child: _app(MapScreen(focusIds: const ['b'], focusToken: token)));
    await tester.pumpWidget(screen('1'));
    await _flush(tester);
    expect(container.read(facilityCategoryFilterProvider), isNull);
    expect(container.read(mapCampusProvider), Campus.bumin);
    if (AppConfig.hasKakaoKey) {
      platform.controller.send('onMapCreated', {});
      await _flush(tester);
      final map = tester.widget<CampusMapView>(find.byType(CampusMapView));
      expect(map.focusIds, isEmpty); // consumed, even if WebView is recreated
      expect(map.selectedId, 'b'); // result sheet stays visible
    }
    // This provider assertion also runs without a map API key.
    final selector = tester.widget<CampusSelector>(find.byType(CampusSelector));
    selector.onSelected!(Campus.seunghak);
    await _flush(tester);
    selector.onSelected!(Campus.bumin);
    await _flush(tester);
    expect(container.read(mapCampusProvider), Campus.bumin);
    final maps = find.byType(CampusMapView);
    if (maps.evaluate().isNotEmpty) {
      expect(tester.widget<CampusMapView>(maps).focusIds, isEmpty);
      expect(tester.widget<CampusMapView>(maps).selectedId, isNull);
    }
    await tester.pumpWidget(screen('2'));
    await _flush(tester);
    if (maps.evaluate().isNotEmpty) {
      final map = tester.widget<CampusMapView>(maps);
      expect(map.focusIds, isEmpty);
      expect(map.selectedId, 'b');
      expect(map.focusKey.toString(), endsWith('|2'));
    }
  });

  testWidgets(
      'missing focus reports failure and cannot hijack campus selection',
      (tester) async {
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allFacilitiesProvider.overrideWith((ref) async => const [_s, _b]),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: _app(const MapScreen(focusIds: ['missing']))));
    await _flush(tester);
    expect(find.text("Couldn't find this building. Please search again."),
        findsOneWidget);
    tester
        .widget<CampusSelector>(find.byType(CampusSelector))
        .onSelected!(Campus.bumin);
    await _flush(tester);
    expect(container.read(mapCampusProvider), Campus.bumin);
  });

  testWidgets(
      'screen clears nearby pins on query removal and searches a new query',
      (tester) async {
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allFacilitiesProvider.overrideWith((ref) async => const [_s, _b]),
    ]);
    addTearDown(container.dispose);
    Widget screen(List<String> queries) => UncontrolledProviderScope(
        container: container, child: _app(MapScreen(nearbyQueries: queries)));
    await tester.pumpWidget(screen(const ['bank']));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    web.reply(web.searches.last['id'] as int, 'bank-1');
    await _flush(tester);
    CampusMapView map() =>
        tester.widget<CampusMapView>(find.byType(CampusMapView));
    expect(map().places.single.id, 'bank-1');
    await tester.pumpWidget(screen(const []));
    await _flush(tester);
    expect(map().places, isEmpty);
    await tester.pumpWidget(screen(const ['cafe']));
    await _flush(tester);
    expect(web.searches.last['keyword'], 'cafe');
    web.reply(web.searches.last['id'] as int, 'cafe-1');
    await _flush(tester);
    expect(map().places.single.id, 'cafe-1');
    await tester.pumpWidget(const SizedBox());
  }, skip: !AppConfig.hasKakaoKey);
}
