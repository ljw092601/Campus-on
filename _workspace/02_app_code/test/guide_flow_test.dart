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

  testWidgets('Guide detail: mobile plan renders its full content',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get a Mobile Plan'));
    await tester.pumpAndSettle();

    // Header meta (same component as the ARC page).
    expect(find.textContaining('Same day'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    // Fixed template sections + the item-specific ones, in order.
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('What to prepare'), findsOneWidget);
    expect(find.text('You may also need'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('With or without an ARC'), findsOneWidget);
    expect(find.text('Prepaid plans'), findsOneWidget);
    expect(find.text('Postpaid plans'), findsOneWidget);
    expect(find.text('Best for'), findsNWidgets(2));
    expect(find.text('Good to know'), findsOneWidget);
    expect(find.text('Links & Locations'), findsOneWidget);
    expect(find.text('Find a nearby carrier store'), findsOneWidget);
  });

  testWidgets('Guide detail: transit card renders its full content',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living'));
    await tester.pumpAndSettle();
    // The list row keeps the short title; the detail heading is the fuller one.
    await tester.tap(find.text('Transit Card'));
    await tester.pumpAndSettle();
    expect(find.text('Buying & Recharging a Transit Card'), findsOneWidget);

    expect(find.textContaining('Approx. 10'), findsOneWidget);
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    // Fixed template sections + the transit-specific ones, in order.
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('What to prepare'), findsOneWidget);
    expect(find.text('How to buy one'), findsOneWidget);
    expect(find.text('How to recharge'), findsOneWidget);
    expect(find.text('How to use it'), findsOneWidget);
    expect(find.text('Transfers'), findsOneWidget);
    expect(find.text('Which card should I buy?'), findsOneWidget);
    expect(find.text('Good to know'), findsOneWidget);
    expect(find.text('Links & Locations'), findsOneWidget);

    // The transfer warning card.
    expect(
      find.textContaining('tap your card when getting off the bus'),
      findsOneWidget,
    );
  });

  testWidgets('Guide detail: stay extension renders its sections in order',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extension of Stay'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    // "When should I apply?" is a topSection — it must sit above the checklist.
    final whenY = tester.getTopLeft(find.text('When should I apply?')).dy;
    final prepareY = tester.getTopLeft(find.text('What to prepare')).dy;
    expect(whenY, lessThan(prepareY));

    for (final title in const [
      'Overview',
      'How to apply',
      'The documents differ from student to student',
      'Good to know',
      'Links & Locations',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // Twice: the online-application section, and the link row of the same name.
    expect(find.text('HiKorea e-Application'), findsNWidgets(2));

    // Item-specific heading for the second checklist group.
    expect(
      find.text('You may also need these depending on your visa and situation'),
      findsOneWidget,
    );
    // Expiry warning card.
    expect(
      find.textContaining('Apply before your current stay period expires'),
      findsOneWidget,
    );
  });

  testWidgets('Guide detail: nearby-store link opens the map in-app',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get a Mobile Plan'));
    await tester.pumpAndSettle();

    // Internal route (`/map?nearby=`) → stays in the app on the Map tab
    // instead of launching a browser.
    final link = find.text('Find a nearby carrier store');
    await tester.scrollUntilVisible(link, 400);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Map'), findsOneWidget);
  });

  testWidgets('Guide detail: visa types renders sections and in-app links',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visa Types'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    // The two visa sections and the comparison sit above the checklist.
    final compareY =
        tester.getTopLeft(find.text('D-2 vs. D-4 at a glance')).dy;
    final prepareY = tester.getTopLeft(find.text('What to prepare')).dy;
    expect(compareY, lessThan(prepareY));

    for (final title in const [
      'Overview',
      'D-2 Student Visa',
      'D-4 General Training Visa',
      'How applying for a visa usually works',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // The one-line takeaway of the comparison, and a section footnote.
    expect(find.textContaining('Degree program → D-2'), findsOneWidget);
    expect(
      find.textContaining('There are other D-2 sub-types as well'),
      findsOneWidget,
    );

    // The tail of the page (past the viewport even on the tall test surface).
    for (final title in const [
      'Good to know',
      'Check your exact visa status',
      'Links & Locations',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 400);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // `/guide/item/...` is internal, so it opens the ARC guide in-app.
    final arcLink = find.text('Guide — Alien Registration Card (ARC)');
    await tester.scrollUntilVisible(arcLink, 400);
    await tester.pumpAndSettle();
    await tester.tap(arcLink);
    await tester.pumpAndSettle();
    expect(find.text('Alien Registration Card (ARC)'), findsWidgets);

    // Drain the ARC page's related-location lookup (mock repo delay) so no
    // timer outlives the widget tree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('Guide detail: coming-soon item shows placeholder', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();

    // Housing → "Dormitory Application" is still a coming-soon placeholder.
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dormitory Application'));
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
