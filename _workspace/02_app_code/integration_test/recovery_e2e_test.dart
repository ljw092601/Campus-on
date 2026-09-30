import 'dart:convert';

import 'package:campus_on/bootstrap.dart';
import 'package:campus_on/core/config/app_config.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/classroom/widgets/room_location_card.dart';
import 'package:campus_on/presentation/facility/facility_list_screen.dart';
import 'package:campus_on/presentation/map/map_screen.dart';
import 'package:campus_on/presentation/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('startup retry and real SDK failure recover without losing focus',
      (tester) async {
    Future<void> until(Future<bool> Function() condition, String description,
        {int seconds = 40}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (await condition()) return;
      }
      fail('Timed out: $description');
    }

    final initializer = AppInitializer();
    var attempts = 0;
    await tester.pumpWidget(AppBootstrap(initialize: () async {
      if (++attempts == 1) throw StateError('Injected startup failure');
      return initializer.initialize();
    }));
    await until(() async => find.byType(ErrorStateView).evaluate().isNotEmpty,
        'startup error');
    final labels =
        AppLocalizations.of(tester.element(find.byType(ErrorStateView)));
    expect(find.text(labels.startup_error_failed), findsOneWidget);
    await tester.tap(find.text(labels.common_retry));
    await until(() async => find.byType(NavigationBar).evaluate().isNotEmpty,
        'real app startup retry');
    await tester.pump(const Duration(seconds: 6));
    expect(attempts, 2);
    debugPrint('E2E_PASS H5_startup_retry');

    // A rejected SDK key exercises the real WebView failure path, without
    // changing the user's emulator network settings or production data.
    kakao.AuthRepository.initialize(
        appKey: 'invalid-e2e-key', baseUrl: 'http://localhost');
    AppRouter.router
        .go('/map?focus=s04&floor=03&room=0306-1&plan=S04&t=recovery');
    await until(
        () async => find.byType(MapScreen).evaluate().isNotEmpty, 'map route');
    final l = AppLocalizations.of(tester.element(find.byType(MapScreen)));
    await until(
        () async => find.text(l.map_error_timeout).evaluate().isNotEmpty,
        'SDK timeout UI');
    expect(find.byType(WebViewWidget), findsNothing);
    expect(find.byType(RoomLocationCard), findsNothing);
    debugPrint('E2E_PASS M23_real_SDK_timeout');
    await tester.tap(find.text(l.map_error_openList));
    await until(
        () async => find.byType(FacilityListScreen).evaluate().isNotEmpty,
        'facility list fallback');
    await tester.pump(const Duration(seconds: 1));
    await tester.binding.handlePopRoute();
    await until(
        () async => find.text(l.map_error_timeout).evaluate().isNotEmpty,
        'return to map failure');
    kakao.AuthRepository.initialize(
        appKey: AppConfig.kakaoJsKey, baseUrl: 'http://localhost');
    await tester.tap(find.text(l.common_retry));
    await until(() async {
      try {
        final web = WebViewController.fromPlatform(tester
            .widget<WebViewWidget>(find.byType(WebViewWidget))
            .platform
            .params
            .controller);
        var result = await web.runJavaScriptReturningResult(
            "JSON.stringify(customOverlays.some(o => o.getMap() !== null && o.id === 'room-target-s04'))");
        for (var i = 0; i < 2 && result is String; i++) {
          result = jsonDecode(result);
        }
        return result == true;
      } catch (_) {
        return false;
      }
    }, 'real map and classroom overlay recovered');
    expect(find.byType(RoomLocationCard), findsOneWidget);
    expect(find.text(l.map_error_timeout), findsNothing);
    expect(tester.takeException(), isNull);
    debugPrint('E2E_PASS M23_retry_restores_classroom_target');
    debugPrint('E2E_RECOVERY_COMPLETE');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
