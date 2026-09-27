import 'package:campus_on/app.dart';
import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/presentation/providers/locale_provider.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picking a language in Settings and keeping it across a restart.

Future<(ProviderScope, SharedPreferences)> _app({String? saved}) async {
  SharedPreferences.setMockInitialValues(
      saved == null ? {} : {'app_locale': saved});
  final prefs = await SharedPreferences.getInstance();
  return (
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const CampusOnApp(),
    ),
    prefs
  );
}

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Settings lists the four languages, each written in itself',
      (tester) async {
    _tallPhone(tester);
    final (app, _) = await _app(saved: 'ko');
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    for (final name in appLanguageNames.values) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.byType(RadioListTile<String>), findsNWidgets(4));
  });

  testWidgets('picking 简体中文 switches the app and is saved', (tester) async {
    _tallPhone(tester);
    final (app, prefs) = await _app(saved: 'ko');
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.text(appLanguageNames['zh']!));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
        listen: false);
    expect(container.read(localeProvider).languageCode, 'zh');
    expect(prefs.getString('app_locale'), 'zh');
  });

  testWidgets('a saved language is used on the next start', (tester) async {
    _tallPhone(tester);
    final (app, _) = await _app(saved: 'vi');
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
        listen: false);
    expect(container.read(localeProvider).languageCode, 'vi');
    // The Vietnamese radio is the selected one.
    final selected = tester
        .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
        .map((t) => t.value)
        .toList();
    expect(selected, appLanguageCodes);
  });

  testWidgets('a language the app does not ship falls back to English',
      (tester) async {
    _tallPhone(tester);
    final (app, _) = await _app(saved: 'ja');
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
        listen: false);
    expect(container.read(localeProvider).languageCode, 'en');
  });
}
