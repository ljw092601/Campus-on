import 'package:campus_on/app.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Week-3 guide flow (S5 categories → S6 item list → S7 detail) + favorites
/// persistence, exercised on the mock repositories. Locale defaults to English
/// in the test binding, so assertions use the English strings.
Future<ProviderScope> _app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const CampusOnApp(),
  );
}

/// Lays a guide detail page out at full height. The section cards run past the
/// default 800×600 test surface, and the lazy list never builds what falls
/// below it — so assertions on later sections need the taller viewport.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Guide tab: categories → item list → detail', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Open the Guide tab (bottom navigation label).
    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();

    // S5 — the 6 categories render (hardcoded).
    expect(find.text('Immigration & Stay'), findsOneWidget);
    expect(find.text('Emergency & Help'), findsOneWidget);

    // → S6 item list for Immigration.
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Alien Registration Card (ARC)'), findsOneWidget);

    // → S7 detail: the published exemplar shows its sections.
    await tester.tap(find.text('Alien Registration Card (ARC)'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('What to prepare'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('Guide detail: bank account renders its full content',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open a Bank Account'));
    await tester.pumpAndSettle();

    // Meta row under the title (same component as the ARC page).
    expect(find.textContaining('Approx. 30 min'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    // The placeholder copy is gone; the real sections render instead.
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('What to prepare'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('Good to know'), findsOneWidget);
    expect(find.text('Useful phrases'), findsOneWidget);
    expect(find.text('I would like to open a bank account.'), findsOneWidget);
  });

  testWidgets('Guide detail: coming-soon item shows placeholder', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();

    // Living → "Get a Mobile Plan" is still a coming-soon placeholder.
    await tester.tap(find.text('Living'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get a Mobile Plan'));
    await tester.pumpAndSettle();

    // No sectioned content → the standard coming-soon copy is shown.
    expect(
      find.textContaining('coming soon', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('Favorite toggle from guide detail persists to Favorites (S10)',
      (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alien Registration Card (ARC)'));
    await tester.pumpAndSettle();

    // Star it from the detail app bar.
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    // Settings → Favorites → Guides segment shows the saved item.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Alien Registration Card (ARC)'), findsOneWidget);
  });
}
