// Audit Low fixes for the map (L-8, L-19, L-20, L-21, L-35, L-36, M-22 memo).
// Fake WebView bridge pattern mirrors map_state_test.dart.
import 'dart:async';
import 'dart:convert';

import 'package:campus_on/core/config/app_config.dart';
import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/data/services/location_service.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/entities/user_location.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/map/campus_proximity.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/map/widgets/campus_map_view.dart';
import 'package:campus_on/presentation/map/widgets/marker_icons.dart';
import 'package:campus_on/presentation/map/widgets/peek_sheet.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/location_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  void reply(int id, String place, {String? url}) =>
      send('onCustomOverlayTap', {
        'latitude': 0.1,
        'longitude': 0.1,
        'customOverlayId': 'campus-nearby:${jsonEncode({
              'id': id,
              'status': 'OK',
              'rows': [
                {
                  'id': place,
                  'place_name': place,
                  'x': '128.97',
                  'y': '35.11',
                  if (url != null) 'place_url': url,
                }
              ]
            })}',
      });

  List<String> get markerScripts => scripts
      .where((s) => s.startsWith('addMarker(') || s.startsWith('clearMarker('))
      .toList();
  int get setCenterCount =>
      scripts.where((s) => s.startsWith('setCenter(')).length;
  int get fitBoundsCount =>
      scripts.where((s) => s.startsWith('fitBounds(')).length;
}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.positions, {this.access = const LocationReady()});
  final Stream<UserLocation> positions;
  final LocationResult access;
  @override
  Future<LocationResult> ensureAccess() async => access;
  @override
  Stream<UserLocation> positionUpdates() => positions;
  @override
  Stream<double> headingUpdates() => const Stream.empty();
}

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Future<void> _flush(WidgetTester tester) async {
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

  ProviderContainer container(
      {LocationResult access = const LocationReady(),
      Stream<UserLocation>? positions}) {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allFacilitiesProvider.overrideWith((ref) async => const [_s, _b]),
      locationServiceProvider.overrideWithValue(_FakeLocationService(
          positions ?? const Stream.empty(),
          access: access)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  // ── L-20: stale last-known fix is ignored ────────────────────────────────

  test('L-20: last-known fix counts only within two minutes', () {
    final now = DateTime(2026, 10, 8, 12, 0, 0);
    expect(LocationService.lastKnownMaxAge, const Duration(minutes: 2));
    expect(
        LocationService.isRecentFix(now.subtract(const Duration(seconds: 30)),
            now: now),
        isTrue);
    expect(
        LocationService.isRecentFix(now.subtract(const Duration(minutes: 2)),
            now: now),
        isTrue);
    expect(
        LocationService.isRecentFix(
            now.subtract(const Duration(minutes: 2, seconds: 1)),
            now: now),
        isFalse);
    expect(
        LocationService.isRecentFix(now.subtract(const Duration(hours: 3)),
            now: now),
        isFalse);
    // A clock skewed into the future is not "recent" either.
    expect(
        LocationService.isRecentFix(now.add(const Duration(minutes: 1)),
            now: now),
        isFalse);
  });

  // ── L-36 helper: nearest campus within the follow radius ─────────────────

  test('L-36: nearestWithin picks the closest campus inside the radius', () {
    const centers = {
      Campus.seunghak: (lat: 35.115, lng: 128.968),
      Campus.bumin: (lat: 35.104, lng: 129.019),
    };
    expect(
        CampusProximity.nearestWithin(
            lat: 35.105, lng: 129.02, centers: centers),
        Campus.bumin);
    expect(
        CampusProximity.nearestWithin(
            lat: 35.12, lng: 128.97, centers: centers),
        Campus.seunghak);
    // Googleplex: nothing within 3 km.
    expect(
        CampusProximity.nearestWithin(
            lat: 37.422, lng: -122.084, centers: centers),
        isNull);
    expect(
        CampusProximity.nearestWithin(
            lat: 35.105, lng: 129.02, centers: centers, radiusMeters: 10),
        isNull);
    expect(
        CampusProximity.nearestWithin(
            lat: 35.105,
            lng: 129.02,
            centers: const <Campus, ({double lat, double lng})>{}),
        isNull);
  });

  // ── L-35 ids ─────────────────────────────────────────────────────────────

  test('L-35: selected marker id round-trips through the #sel suffix', () {
    expect(CategoryMarkerIcons.selectedMarkerId('s04'), 's04#sel');
    expect(CategoryMarkerIcons.baseMarkerId('s04#sel'), 's04');
    expect(CategoryMarkerIcons.baseMarkerId('s04'), 's04');
    expect(CategoryMarkerIcons.baseMarkerId('place:123#sel'), 'place:123');
    expect(CategoryMarkerIcons.selectedWidth,
        (CategoryMarkerIcons.width * CategoryMarkerIcons.selectedScale)
            .round());
    expect(CategoryMarkerIcons.selectedHeight,
        (CategoryMarkerIcons.height * CategoryMarkerIcons.selectedScale)
            .round());
    expect(CategoryMarkerIcons.selectedOffsetY,
        CategoryMarkerIcons.selectedHeight); // tip stays on the coordinate
  });

  // ── L-35 + M-22: marker memo and selected-pin swap on the view ───────────

  testWidgets(
      'M-22/L-35: markers are re-sent only when the list changes; selection '
      'swaps the pin to <id>#sel with the big icon and back', (tester) async {
    final taps = <String>[];
    Widget view({String? selectedId, UserLocation? location}) =>
        _app(CampusMapView(
          facilities: const [_s, _b],
          focusIds: const [],
          onMarkerTap: taps.add,
          selectedId: selectedId,
          userLocation: location,
        ));
    await tester.pumpWidget(view());
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    final initial = web.markerScripts;
    expect(initial.where((s) => s.startsWith("addMarker('s',")), hasLength(1));
    expect(initial.where((s) => s.startsWith("addMarker('b',")), hasLength(1));
    expect(initial.only((s) => s.startsWith("addMarker('s',")),
        contains("'${CategoryMarkerIcons.width}', "
            "'${CategoryMarkerIcons.height}'"));

    // Unrelated rebuilds (GPS fixes) must not re-send 48 pins + icons.
    await tester.pumpWidget(
        view(location: const UserLocation(lat: 35.11, lng: 128.96)));
    await _flush(tester);
    await tester.pumpWidget(
        view(location: const UserLocation(lat: 35.112, lng: 128.961)));
    await _flush(tester);
    expect(web.markerScripts.length, initial.length);

    // Select "s": the plain pin is dropped and "s#sel" added, larger, on top.
    await tester.pumpWidget(view(
        selectedId: 's',
        location: const UserLocation(lat: 35.112, lng: 128.961)));
    await _flush(tester);
    final afterSelect = web.markerScripts.sublist(initial.length);
    expect(afterSelect, isNotEmpty);
    final clear = afterSelect.first;
    expect(clear, startsWith('clearMarker('));
    expect(clear, contains('"s#sel"'));
    expect(clear, isNot(contains('"s"')));
    final selScript =
        afterSelect.only((s) => s.startsWith("addMarker('s#sel',"));
    expect(
        selScript,
        contains("'${CategoryMarkerIcons.selectedWidth}', "
            "'${CategoryMarkerIcons.selectedHeight}', "
            "'${CategoryMarkerIcons.selectedOffsetX}', "
            "'${CategoryMarkerIcons.selectedOffsetY}'"));
    expect(selScript, contains(', 10, ')); // zIndex above the neighbours
    expect(afterSelect.where((s) => s.startsWith("addMarker('s',")), isEmpty);

    // A tap on the emphasised pin reports the original facility id.
    web.send('onMarkerTap', {
      'markerId': 's#sel',
      'latitude': 35.115,
      'longitude': 128.968,
      'zoomLevel': 3,
    });
    expect(taps, ['s']);

    // Same selection again → nothing new goes over the bridge.
    final beforeNoop = web.markerScripts.length;
    await tester.pumpWidget(view(
        selectedId: 's',
        location: const UserLocation(lat: 35.113, lng: 128.962)));
    await _flush(tester);
    expect(web.markerScripts.length, beforeNoop);

    // Deselect → plain "s" is restored (and "s#sel" dropped).
    await tester.pumpWidget(view());
    await _flush(tester);
    final afterDeselect = web.markerScripts.sublist(beforeNoop);
    expect(afterDeselect.first, startsWith('clearMarker('));
    expect(afterDeselect.first, isNot(contains('#sel')));
    expect(afterDeselect.where((s) => s.startsWith("addMarker('s',")),
        hasLength(1));
  });

  // ── L-21: permission denied → camera to the campus centre ────────────────

  testWidgets('L-21: denied permission shows the notice AND centres on campus',
      (tester) async {
    final c = container(
        access: const LocationPermissionDenied(permanent: false));
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: _app(const MapScreen())));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    final l = AppLocalizations.of(tester.element(find.byType(MapScreen)));
    final before = web.setCenterCount;
    await tester.tap(find.byTooltip(l.map_myLocation_tooltip));
    await _flush(tester);
    expect(find.text(l.map_myLocation_denied), findsOneWidget);
    expect(web.setCenterCount, before + 1);
    // Seunghak is selected → its facility-average centre.
    final center = RegExp(r"setCenter\('([\d.-]+)', '([\d.-]+)'\)")
        .firstMatch(web.scripts.lastWhere((s) => s.startsWith('setCenter(')))!;
    expect(double.parse(center[1]!), closeTo(35.115, 0.0001));
    expect(double.parse(center[2]!), closeTo(128.968, 0.0001));
    await tester.pumpWidget(const SizedBox());
  }, skip: !AppConfig.hasKakaoKey);

  // ── L-36: followed fix moves the campus selector, not the user's state ───

  testWidgets(
      'L-36: a followed fix on another campus switches the selector without '
      'refitting the camera; an unfollowed fix leaves it alone',
      (tester) async {
    final positions = StreamController<UserLocation>.broadcast();
    addTearDown(positions.close);
    final c = container(positions: positions.stream);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: _app(const MapScreen())));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    final l = AppLocalizations.of(tester.element(find.byType(MapScreen)));
    CampusMapView map() =>
        tester.widget<CampusMapView>(find.byType(CampusMapView));
    expect(c.read(mapCampusProvider), Campus.seunghak);

    await tester.tap(find.byTooltip(l.map_myLocation_tooltip));
    await _flush(tester);
    expect(map().following, isTrue);
    final fits = web.fitBoundsCount;
    positions.add(const UserLocation(lat: 35.105, lng: 129.02));
    await _flush(tester);
    expect(c.read(mapCampusProvider), Campus.bumin);
    expect(map().campus, Campus.bumin);
    expect(map().following, isTrue);
    expect(web.fitBoundsCount, fits); // camera stayed on the fix
    expect(map().userLocation?.lat, 35.105);

    // Off-campus fix: no switch (follow drops, selector untouched).
    positions.add(const UserLocation(lat: 37.422, lng: -122.084));
    await _flush(tester);
    expect(c.read(mapCampusProvider), Campus.bumin);
    expect(map().following, isFalse);

    // Panned away (not following): a fix near Seunghak must not switch.
    positions.add(const UserLocation(lat: 35.116, lng: 128.969));
    await _flush(tester);
    expect(map().following, isFalse);
    expect(c.read(mapCampusProvider), Campus.bumin);
    await tester.pumpWidget(const SizedBox());
  }, skip: !AppConfig.hasKakaoKey);

  // ── L-19: GPS stream stops while the map tab is hidden ───────────────────

  testWidgets(
      'L-19: leaving the map tab (other branch, pushed detail) stops the GPS '
      'stream and returning resumes it with the last dot intact',
      (tester) async {
    final positions = StreamController<UserLocation>.broadcast();
    addTearDown(positions.close);
    final c = container(positions: positions.stream);
    final router = GoRouter(initialLocation: '/map', routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: Text('home'))),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/map',
              builder: (_, __) => const MapScreen(),
              routes: [
                GoRoute(
                    path: 'detail',
                    builder: (_, __) =>
                        const Scaffold(body: Text('detail'))),
              ],
            ),
          ]),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    final l = AppLocalizations.of(tester.element(find.byType(MapScreen)));
    CampusMapView map() =>
        tester.widget<CampusMapView>(find.byType(CampusMapView));

    await tester.tap(find.byTooltip(l.map_myLocation_tooltip));
    await _flush(tester);
    expect(positions.hasListener, isTrue);
    positions.add(const UserLocation(lat: 35.116, lng: 128.969));
    await _flush(tester);
    expect(map().userLocation?.lat, 35.116);
    expect(map().following, isTrue);

    // 1. Another tab: branch goes Offstage/TickerMode(false) → unsubscribed.
    router.go('/home');
    await tester.pumpAndSettle();
    expect(positions.hasListener, isFalse);

    // Back to the map: resubscribed, dot still there, follow kept.
    router.go('/map');
    await tester.pumpAndSettle();
    await _flush(tester);
    expect(positions.hasListener, isTrue);
    expect(map().userLocation?.lat, 35.116);
    expect(map().following, isTrue);

    // 2. A detail pushed over the map within the branch.
    unawaited(router.push('/map/detail'));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(positions.hasListener, isFalse);
    router.pop();
    await tester.pumpAndSettle();
    await _flush(tester);
    expect(positions.hasListener, isTrue);
    expect(map().userLocation?.lat, 35.116);

    // Not tracking when hidden → nothing to resume.
    await tester.tap(find.byTooltip(l.map_myLocation_tooltip)); // still on
    await _flush(tester);
    positions.add(const UserLocation(lat: 35.117, lng: 128.97));
    await _flush(tester);
    await tester.pumpWidget(const SizedBox());
  }, skip: !AppConfig.hasKakaoKey);

  // ── L-8: failed place link launch is reported ────────────────────────────

  testWidgets('L-8: opening a nearby place page that cannot launch shows '
      'common_openFailed', (tester) async {
    final c = container();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: _app(const MapScreen(nearbyQueries: ['bank']))));
    await _flush(tester);
    final web = platform.controller;
    web.send('onMapCreated', {});
    await _flush(tester);
    web.reply(web.searches.last['id'] as int, 'bank-1',
        url: 'https://place.map.kakao.com/1');
    await _flush(tester);
    web.send('onMarkerTap', {
      'markerId': 'place:bank-1',
      'latitude': 35.11,
      'longitude': 128.97,
      'zoomLevel': 3,
    });
    await _flush(tester);
    expect(find.byType(PlacePeekSheet), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(MapScreen)));
    // No url_launcher implementation answers in tests: the platform reply is
    // an error delivered on the real event loop, so drive it with runAsync.
    // openExternal must turn that into the failure snackbar.
    await tester.runAsync(() async {
      await tester.tap(find.descendant(
          of: find.byType(PlacePeekSheet),
          matching: find.byType(FilledButton)));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await _flush(tester);
    expect(find.text(l.common_openFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: !AppConfig.hasKakaoKey);
}

extension on List<String> {
  /// The one element matching [test] (fails loudly if 0 or 2+).
  String only(bool Function(String) test) => where(test).single;
}
