import 'package:campus_on/app.dart';
import 'package:campus_on/data/mock/mock_data.dart';
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

  testWidgets('Guide detail: health insurance renders its sections in order',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('National Health Insurance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    // Fuller detail heading than the list row.
    expect(
      find.text('National Health Insurance for International Students'),
      findsOneWidget,
    );

    // This item overrides the shared checklist heading: its list is what to
    // verify before an automatic enrolment, not documents to bring.
    expect(find.text('Before you enroll'), findsOneWidget);
    expect(find.text('What to prepare'), findsNothing);

    // "When does coverage start?" is a topSection — above the checklist.
    final whenY = tester.getTopLeft(find.text('When does coverage start?')).dy;
    final prepareY = tester.getTopLeft(find.text('Before you enroll')).dy;
    expect(whenY, lessThan(prepareY));

    for (final title in const [
      'Overview',
      'D-2 Student Visa',
      'D-4 General Training Visa',
      'Steps',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // The tail of the page (past the viewport even on the tall test surface).
    for (final title in const [
      'Premiums and the student reduction',
      'What does the insurance cover?',
      'Unpaid premiums can restrict your benefits',
      'Where to ask',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 400);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Contact block carries the NHIS foreign-language line — still on screen,
    // "Where to ask" being the last section scrolled to.
    expect(find.textContaining('033-811-2000'), findsOneWidget);

    for (final title in const ['Good to know', 'Links & Locations']) {
      await tester.scrollUntilVisible(find.text(title), 400);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Both official sources are linked (the in-app ARC row is covered by its
    // own test below).
    expect(find.text('NHIS — Guidance for foreigners'), findsOneWidget);
    expect(
      find.text('Study in Korea — National Health Insurance'),
      findsOneWidget,
    );
  });

  // Deliberately says nothing about whether a premium figure appears: a dated
  // example ("about ₩XX,XXX as of 2026") may be added from official sources
  // later, and that is allowed. What has to survive any such edit is the safety
  // notice — premiums change, so the student is pointed at their own NHIS bill
  // or the official guidance rather than at a number in this app.
  testWidgets(
      'Guide detail: health insurance premiums keep the check-latest-guidance '
      'notice', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('National Health Insurance'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.text('Premiums and the student reduction'), 400);
    await tester.pumpAndSettle();

    // "Premiums and reduction rules may change. Always check your latest NHIS
    // bill or official NHIS guidance." — one notice card, asserted in halves so
    // a failure says which half went missing.
    expect(
      find.textContaining('Premiums and reduction rules may change'),
      findsOneWidget,
      reason: 'premiums must still be described as subject to change',
    );
    expect(
      find.textContaining('check your latest NHIS bill'),
      findsOneWidget,
      reason: 'the guide must still send the student to the official source',
    );
  });

  testWidgets('Guide detail: health insurance ARC link opens in-app',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('National Health Insurance'));
    await tester.pumpAndSettle();

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

  testWidgets('Guide detail: course registration renders its sections in order',
      (tester) async {
    // Taller than the shared surface: this guide runs to twelve section cards.
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('School admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course Registration'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.textContaining('10–30 minutes'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    // Login is a topSection: a new student cannot open the registration system
    // at all without the exam-number rule, so it has to precede the checklist.
    final loginY = tester.getTopLeft(find.text('How to log in')).dy;
    final beforeY = tester.getTopLeft(find.text('Before registration')).dy;
    final howY = tester.getTopLeft(find.text('How to register')).dy;
    expect(loginY, lessThan(beforeY));
    expect(beforeY, lessThan(howY));

    for (final title in const [
      'Overview',
      'How to log in',
      'Maximum course load',
      'Credit carryover',
      'Before registration',
      'Check what the course actually covers',
      'How to register',
      'Confirmation & rejection',
      'Course add/drop',
      'Check your final registration',
      'Required courses for international students',
      'Register within the period',
      'Good to know',
      'Links & Locations',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // The new-student login rule, and the two cards that cost the most to miss.
    expect(
      find.textContaining('the last 4 digits of the mobile number'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Check your registration result'),
      findsOneWidget,
    );
    expect(
      find.textContaining('No registration means no credits'),
      findsOneWidget,
    );
    // 2024-only figures are attributed to the booklet, never stated as current.
    expect(
      find.textContaining('2024 international-student booklet'),
      findsWidgets,
    );

    // Carryover: the worked example, the exclusion the notice names, and the
    // expiry warning. The nationality question is answered explicitly so the
    // page never implies international students are excluded.
    expect(
      find.textContaining('You registered for 16 credits'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Part-time registered students'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Carried credits expire if you do not use them'),
      findsOneWidget,
    );
    expect(find.text('What about international students?'), findsOneWidget);
    // The credit cap is never stated as a flat rule for everyone.
    expect(find.textContaining('Not every student gets 19 credits'),
        findsOneWidget);
  });

  testWidgets('Guide detail: campus clinic shows both campuses and their maps',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campus Health Center'));
    await tester.pumpAndSettle();

    // Published, so the coming-soon placeholder must be gone.
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    for (final title in const [
      'Overview',
      'Where can I find it?',
      'Before you visit',
      'Opening hours',
      'What services are available?',
      'In an emergency',
      'If you need to see a doctor',
      'Contact',
      'Links & Locations',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Which campus you are on decides the rest of the page, so the locations
    // are rendered above the checklist and the hours.
    final whereY = tester.getTopLeft(find.text('Where can I find it?')).dy;
    final beforeY = tester.getTopLeft(find.text('Before you visit')).dy;
    final hoursY = tester.getTopLeft(find.text('Opening hours')).dy;
    expect(whereY, lessThan(beforeY));
    expect(beforeY, lessThan(hoursY));

    // Both campuses, each with its own building and phone number.
    expect(find.text('Seunghak campus'), findsOneWidget);
    expect(find.text('Bumin campus'), findsOneWidget);
    expect(
      find.textContaining('Student Union Building (Q), basement floor 1'),
      findsWidgets,
    );
    expect(
      find.textContaining('Law School Building (LS), 1st floor'),
      findsWidgets,
    );
    expect(find.textContaining('051-200-6331'), findsWidgets);
    expect(find.textContaining('051-200-8465'), findsWidgets);

    // Hours are stated with the lunch break, and the emergency card sends the
    // student to 119 rather than to the clinic.
    expect(find.textContaining('09:00 – 17:00'), findsOneWidget);
    expect(find.textContaining('Lunch break 12:00 – 13:00'), findsOneWidget);
    expect(find.textContaining('Call 119 straight away'), findsOneWidget);

    // Only the six services the clinic actually publishes.
    for (final service in const [
      'First aid',
      'Treatment for wounds and burns',
      'Over-the-counter medication',
      'Health counselling',
      'Health education',
      'Health promotion programmes',
    ]) {
      expect(find.text(service), findsOneWidget, reason: service);
    }

    // One related-location card per campus, each pointing at the building the
    // floor guide lists the clinic in.
    final clinic =
        MockData.guideItems.firstWhere((g) => g.id == 'campus-clinic');
    expect(clinic.relatedFacilityIds, ['b02', 's02']);
    expect(find.text('법학전문대학원(LS)'), findsOneWidget);
    expect(find.text('학생회관(Q)'), findsOneWidget);
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
