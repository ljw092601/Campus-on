import 'package:campus_on/app.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Week-3 guide flow (S5 categories → S6 item list → S7 detail) + favorites
/// persistence, exercised on the mock repositories. Locale defaults to English
/// in the test binding, so assertions use the English strings.
/// [locale] seeds the persisted language so a test can start in Korean —
/// [LocaleNotifier] reads `app_locale` from prefs on build.
Future<ProviderScope> _app({String? locale}) async {
  SharedPreferences.setMockInitialValues(
      locale == null ? {} : {'app_locale': locale});
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

  testWidgets('Guide detail: certificate issuance renders its sections in order',
      (tester) async {
    // Nine section cards plus links — taller than the shared surface.
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
    await tester.tap(find.text('Certificate Issuance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.textContaining('Instant to a few days'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    for (final title in const [
      'Overview',
      'Certificates you can issue',
      'The simplest way — issue it online',
      'Certificate kiosks on campus',
      'Other ways to get a certificate',
      'Need an English certificate?',
      'When you need something special',
      'Documents available through the Integrated Information System',
      'Good to know',
      'Links & Locations',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Online issuance is recommended first, then the kiosk, then the rest.
    final onlineY =
        tester.getTopLeft(find.text('The simplest way — issue it online')).dy;
    final kioskY =
        tester.getTopLeft(find.text('Certificate kiosks on campus')).dy;
    final otherY =
        tester.getTopLeft(find.text('Other ways to get a certificate')).dy;
    expect(onlineY, lessThan(kioskY));
    expect(kioskY, lessThan(otherY));

    // Kiosk locations follow the current official kiosk page. The 2024 booklet
    // put the 승학 machine in the 본부 basement — that figure may only appear as
    // an attributed footnote, never as the current location.
    expect(
      find.textContaining('lobby of the College of Humanities'),
      findsOneWidget,
    );
    expect(
      find.textContaining('lobby of the College of Social Sciences'),
      findsOneWidget,
    );
    expect(
      find.textContaining('basement of the main administration building'),
      findsOneWidget,
    );
    expect(
      find.textContaining('2024 international-student booklet'),
      findsWidgets,
    );

    // 24/7 is stated together with the caveat that a locked building overrides
    // it, so nobody walks across campus at night for nothing.
    expect(
      find.textContaining('You cannot use a kiosk in a locked building'),
      findsOneWidget,
    );
    // English certificates hinge on the registered English name.
    expect(
      find.textContaining('The spelling has to match your passport'),
      findsOneWidget,
    );
    // No 2024 fee is restated as a current amount.
    expect(find.textContaining('₩'), findsNothing);

    // Both kiosk buildings are linked as map locations.
    expect(find.text('대학본부 및 인문과학대학(A)'), findsOneWidget);
    expect(find.text('종합강의동(BA-BD)'), findsOneWidget);
  });

  testWidgets('Guide detail: certificate issuance fits a 360dp phone',
      (tester) async {
    // Narrowest phone width the app targets — scroll the whole page and let any
    // RenderFlex overflow surface as an exception.
    tester.view.physicalSize = const Size(360, 800);
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
    await tester.tap(find.text('Certificate Issuance'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).last;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();

    // Reached the end of the page: the links section is on screen.
    expect(find.text('Links & Locations'), findsOneWidget);

    // Back out of the detail page — lands on the guide category screen.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('School admin'), findsOneWidget);
  });

  testWidgets('Guide detail: library guide renders its sections in order',
      (tester) async {
    // Nine section cards plus tips and links — taller than the shared surface.
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
    await tester.tap(find.text('Library Guide'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.textContaining('5–10 minutes'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    const titles = [
      'Overview',
      'Where the libraries are',
      'Using the library for the first time',
      'Borrowing Books',
      'Returns & Overdue Items',
      'Study Room & Seat Reservation',
      'Inter-Campus Loan',
      'E-resources & Papers',
      'Opening Hours',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // The order in the brief: locations and first-time setup lead, hours close.
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // All four libraries are listed with the building the site gives them.
    expect(find.textContaining('Building: S10'), findsOneWidget);
    expect(find.textContaining('floors 5–10'), findsOneWidget);
    expect(find.textContaining('Building: B02'), findsOneWidget);
    expect(find.textContaining('Building: G05'), findsOneWidget);

    // Mobile ID setup, borrowing limits, return boxes, the overdue rule.
    expect(find.textContaining('Set up your mobile library ID'), findsOneWidget);
    expect(find.textContaining('Undergraduate students: 10 books for 14 days'),
        findsOneWidget);
    expect(find.textContaining('Graduate students: 10 books for 30 days'),
        findsOneWidget);
    expect(find.textContaining('renew once'), findsOneWidget);
    expect(find.textContaining('2nd floor of the library'), findsOneWidget);
    expect(
      find.textContaining('one day of suspension per book per day overdue'),
      findsOneWidget,
    );

    // Seat booking: the 20-minute check-in is the thing people get wrong.
    expect(find.textContaining('Check in within 20 minutes'), findsOneWidget);
    expect(find.textContaining('20 minutes to check in'), findsOneWidget);
    // Inter-campus loan + off-campus access for papers.
    expect(find.textContaining('request an inter-campus loan'), findsOneWidget);
    expect(find.textContaining('off-campus access'), findsWidgets);

    // Hours: the live-hours instruction is present and the 2024 booklet's
    // figures appear only as an attributed footnote, never as current hours.
    expect(
      find.textContaining('Check opening hours before visiting'),
      findsOneWidget,
    );
    expect(find.textContaining('As listed in August 2026'), findsOneWidget);
    // Two attributed footnotes: the student-ID note and the old hours.
    expect(
      find.textContaining('2024 international-student booklet'),
      findsNWidgets(2),
    );
    expect(find.textContaining('go by the live hours'), findsOneWidget);
    expect(find.textContaining('05:00–24:00'), findsOneWidget); // footnote only

    // Official library links only, and all four libraries as map cards.
    expect(find.text('Dong-A University Library'), findsOneWidget);
    expect(find.text('DAU Library English'), findsOneWidget);
    expect(find.text('Mobile library ID'), findsOneWidget);
    expect(find.text('Seat reservation'), findsOneWidget);
    expect(find.text('Inter-campus loan'), findsOneWidget);
    expect(find.text('한림도서관(B)'), findsOneWidget);
    expect(find.text('국제관'), findsOneWidget);
    expect(find.text('법학전문대학원(LS)'), findsOneWidget);
    expect(find.text('구덕교육동 2,3호관'), findsOneWidget);
  });

  testWidgets('Guide detail: library guide fits a 360dp phone', (tester) async {
    // Narrowest phone width the app targets — scroll the whole page and let any
    // RenderFlex overflow surface as an exception.
    tester.view.physicalSize = const Size(360, 800);
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
    await tester.tap(find.text('Library Guide'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).last;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    // Back out of the detail page — lands on the guide category screen.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('School admin'), findsOneWidget);
  });

  testWidgets('Guide detail: library guide renders in Korean', (tester) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학교 행정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('도서관 이용안내'));
    await tester.pumpAndSettle();

    for (final title in const [
      '개요',
      '도서관 위치',
      '처음 이용한다면',
      '도서 대출',
      '반납 · 연체',
      '열람실 이용',
      '캠퍼스간 대출',
      '전자자료 · 논문 이용',
      '운영시간',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.textContaining('모바일 이용증을 준비하세요'), findsOneWidget);
    expect(find.textContaining('학부 재학생: 10책 / 14일'), findsOneWidget);
    expect(find.textContaining('운영시간은 방문 전에 확인하세요'), findsOneWidget);
    expect(find.textContaining('5~10분'), findsOneWidget);
  });

  testWidgets('Favorite toggle works from the library guide', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('School admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library Guide'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Library Guide'), findsOneWidget);
  });

  testWidgets('Guide detail: OIA guide renders its sections in order',
      (tester) async {
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
    await tester.tap(find.text('International Affairs Office'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.text('International Affairs Office Guide'), findsOneWidget);
    expect(find.textContaining('10–30 minutes'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    const titles = [
      'Overview',
      'What can I ask about?',
      'Where the office is',
      'Before You Visit',
      'Steps',
      'Contact',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // The four service groups a student picks between.
    expect(find.text('🪪 Stay & visa'), findsOneWidget);
    expect(find.text('🎓 Academics & student life'), findsOneWidget);
    expect(find.text('💰 Scholarships & living support'), findsOneWidget);
    expect(find.text('🌏 Exchange programmes'), findsOneWidget);
    // Immigration work is framed as university support, never as the office
    // filing the application itself.
    expect(find.textContaining('It is not an immigration office'), findsOneWidget);

    // Location + transport, from the office's own directions page.
    expect(find.textContaining('room BC-0116-3'), findsOneWidget);
    expect(find.textContaining('225 Gudeok-ro'), findsOneWidget);
    expect(find.textContaining('3-minute walk from Exit 2'), findsOneWidget);
    expect(find.textContaining('express bus 58-1'), findsOneWidget);

    // Contact: the published main numbers only, no invented duty split.
    expect(find.textContaining('051-200-6442~4, 6446~8'), findsOneWidget);
    expect(find.textContaining('Fax: 051-200-6445'), findsOneWidget);
    expect(find.textContaining('051-200-6447'), findsOneWidget);
    // Opening hours are not published, so none are stated as fact.
    expect(
      find.textContaining('does not list its opening hours'),
      findsOneWidget,
    );
    expect(find.textContaining('09:00'), findsNothing);

    // Passport/ARC are never presented as required for every visit.
    expect(
      find.textContaining('not required for every visit'),
      findsOneWidget,
    );

    // Official links only, plus the in-app map row.
    expect(find.text('Dong-A University Office of International Affairs'),
        findsOneWidget);
    expect(find.text('Directions to the office'), findsOneWidget);
    expect(find.text('Notices for international students'), findsOneWidget);
    expect(find.text('Office Q&A board'), findsOneWidget);
    expect(find.text('Exchange programme counseling'), findsOneWidget);
    expect(find.text('View the International Affairs Office on the map'),
        findsOneWidget);
    expect(find.text('종합강의동(BA-BD)'), findsOneWidget);
  });

  testWidgets('Guide detail: OIA map link opens the map in-app', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('School admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('International Affairs Office'));
    await tester.pumpAndSettle();

    // Internal route (`/map?focus=b04`) → stays in the app on the Map tab.
    final link = find.text('View the International Affairs Office on the map');
    await tester.scrollUntilVisible(link, 400);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Map'), findsOneWidget);
  });

  testWidgets('Guide detail: OIA guide fits a 360dp phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
    await tester.tap(find.text('International Affairs Office'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).last;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('School admin'), findsOneWidget);
  });

  testWidgets('Guide detail: OIA guide renders in Korean', (tester) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학교 행정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('국제교류과 방문 안내'));
    await tester.pumpAndSettle();

    // The list row is short; the detail heading carries the full 공식 명칭.
    expect(find.text('대외국제처 국제교류과 방문 안내'), findsOneWidget);
    for (final title in const [
      '개요',
      '어떤 일로 방문할 수 있나요?',
      '위치',
      '방문 전 확인',
      '단계',
      '연락처',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.textContaining('종합강의동 1층 BC-0116-3'), findsOneWidget);
    expect(find.textContaining('051-200-6442~4, 6446~8'), findsOneWidget);
    expect(find.text('지도에서 국제교류과 위치 보기'), findsOneWidget);
    expect(find.textContaining('10~30분'), findsOneWidget);
  });

  testWidgets('Favorite toggle works from the OIA guide', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('School admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('International Affairs Office'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('International Affairs Office'), findsOneWidget);
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

  // ── hospital-guide ────────────────────────────────────────────────────────
  // NOTE: the emergency section carries a real `tel:119` row. Nothing here taps
  // it — the url is asserted as data and the widget tests only read the label.
  // Never add a tap on "Call 119".

  test('Hospital guide: data-level guarantees (no recommendation, no price)',
      () {
    final item =
        MockData.guideItems.firstWhere((g) => g.id == 'hospital-guide');

    expect(item.status, GuideStatus.published);
    expect(item.categoryId, GuideCategory.health);

    // No hospital is presented as a related location: the university publishes
    // no designated-hospital scheme, so a location card would read as advice.
    expect(item.relatedFacilityIds, isEmpty);

    // The emergency block is the first thing on the page and owns the 119 row.
    final urgent = item.topSections.single;
    expect(urgent.titleKo, '응급이라면 먼저');
    expect(urgent.titleEn, 'If it is an emergency');
    expect(urgent.links.single.url, 'tel:119');
    expect(urgent.links.single.labelKo, '119 전화하기');
    expect(urgent.links.single.labelEn, 'Call 119');
    expect(urgent.links.single.url.startsWith('/'), isFalse);
    expect(urgent.noticeKo, isNotNull);
    expect(urgent.noticeEn, isNotNull);

    // Bottom links: E-Gen plus the three in-app guides, no duplicates.
    expect(
      item.links.map((l) => l.url).toList(),
      const [
        'https://www.e-gen.or.kr/',
        '/guide/item/campus-clinic',
        '/guide/item/health-insurance',
        '/guide/item/emergency-contacts',
      ],
    );
    // campus-clinic links here, so the pair is symmetric.
    final clinic =
        MockData.guideItems.firstWhere((g) => g.id == 'campus-clinic');
    expect(
      clinic.links.any((l) => l.url == '/guide/item/hospital-guide'),
      isTrue,
    );

    // The campus clinic is linked exactly once, from the bottom block — never
    // from inside the language section, where it would read as a language
    // service rather than general help.
    final allLinkUrls = [
      for (final s in [...item.topSections, ...item.sections])
        ...s.links.map((l) => l.url),
      ...item.links.map((l) => l.url),
    ];
    expect(
      allLinkUrls.where((u) => u == '/guide/item/campus-clinic').length,
      1,
    );
    final language = item.sections
        .firstWhere((s) => s.titleEn == 'If you are worried about the language');
    expect(language.links, isEmpty);
    // …and the section does not name the clinic in prose either. It is not a
    // foreign-language service, so mentioning it here would mislead.
    final languageText = [
      language.titleKo, language.titleEn, language.bodyKo, language.bodyEn,
      language.noticeKo, language.noticeEn,
      language.footnoteKo, language.footnoteEn,
      ...language.stepsKo, ...language.stepsEn,
      for (final n in language.notes) ...[
        n.titleKo, n.titleEn, ...n.linesKo, ...n.linesEn,
      ],
    ].whereType<String>().join('\n');
    for (final banned in const [
      '보건진료소',
      '보건소',
      'campus health clinic',
      'Campus Health Center',
      'campus-clinic',
    ]) {
      expect(languageText.contains(banned), isFalse, reason: banned);
    }
    // It says exactly one thing: languages differ, so ring ahead and ask.
    expect(language.bodyKo, contains('전화해 어떤 언어가 가능한지 확인'));
    expect(language.bodyEn, contains('call ahead and ask'));
    // One paragraph only — the clinic paragraph was removed from both.
    expect(language.bodyKo!.contains('\n\n'), isFalse);
    expect(language.bodyEn!.contains('\n\n'), isFalse);

    // The section-level links that do remain: 119, the insurance guide, E-Gen.
    expect(
      [
        for (final s in [...item.topSections, ...item.sections])
          ...s.links.map((l) => l.url),
      ],
      const [
        'tel:119',
        '/guide/item/health-insurance',
        'https://www.e-gen.or.kr/',
      ],
    );

    // Every string this item renders, in both languages.
    final dump = [
      item.titleKo, item.titleEn, item.summaryKo, item.summaryEn,
      item.overviewKo, item.overviewEn,
      item.checklistTitleKo, item.checklistTitleEn,
      item.checklistNoteKo, item.checklistNoteEn,
      ...item.checklistKo, ...item.checklistEn,
      ...item.stepsKo, ...item.stepsEn,
      ...item.tipsKo, ...item.tipsEn,
      for (final s in [...item.topSections, ...item.sections]) ...[
        s.titleKo, s.titleEn, s.bodyKo, s.bodyEn, s.noticeKo, s.noticeEn,
        s.footnoteKo, s.footnoteEn,
        ...s.stepsKo, ...s.stepsEn,
        for (final l in s.links)
          '${l.labelKo}${l.labelEn}${l.url}'
              '${l.descriptionKo ?? ''}${l.descriptionEn ?? ''}',
        for (final n in s.notes) ...[
          n.titleKo, n.titleEn, ...n.linesKo, ...n.linesEn,
        ],
      ],
      for (final l in item.links)
        '${l.labelKo}${l.labelEn}${l.url}'
            '${l.descriptionKo ?? ''}${l.descriptionEn ?? ''}',
    ].whereType<String>().join('\n');

    // No money anywhere — amounts depend on the treatment and the clinic, and
    // the insurance guide owns premiums.
    expect(RegExp(r'[0-9][0-9,]*\s*원').hasMatch(dump), isFalse);
    expect(dump.contains('₩'), isFalse);
    expect(dump.contains('KRW'), isFalse);
    expect(dump.contains('%'), isFalse);

    // No named hospital, and no Dong-A hospital building in particular.
    expect(dump.contains('동아대학교병원'), isFalse);
    expect(dump.contains('대신요양병원'), isFalse);

    // No medical judgement: no symptom triage, no department steering. The
    // page never grades how severe anything is — "증상이 가볍" in particular was
    // removed from the language section for exactly that reason.
    for (final banned in const [
      '가벼운 증상',
      '증상이 가벼우면',
      '증상이 가볍',
      '경미한',
      '내과',
      '피부과',
      '이비인후과',
      '정형외과',
      'if it is mild',
      'minor symptoms',
    ]) {
      expect(dump.contains(banned), isFalse, reason: banned);
    }

    // English ARC wording matches the rest of the app ("Residence Card (ARC)",
    // as used by the ARC / visa / stay-extension guides).
    expect(dump.toLowerCase().contains('alien registration'), isFalse);
    expect(dump.contains('Residence Card (ARC)'), isTrue);
    // Korean keeps 외국인등록증.
    expect(item.checklistKo.join('\n'), contains('외국인등록증'));

    // The overview states the ID check as conditional, so it cannot contradict
    // the waivers spelled out further down.
    expect(item.overviewKo, contains('경우가 있습니다'));
    expect(item.overviewKo!.contains('본인확인을 합니다'), isFalse);
    expect(item.overviewEn, contains('may need to'));
    expect(item.overviewEn!.contains('you will be asked for ID'), isFalse);

    // The ID rule is stated as an insurance condition, never as a bar to care:
    // no document is called mandatory, and wherever "cannot be treated" appears
    // it is inside a negation ("…있는 것은 아니며 / 아닙니다").
    expect(dump.contains('반드시 필요'), isFalse);
    for (final m in RegExp(r'진료를? ?자체를? ?받을 수 없[^.\n]*')
        .allMatches(dump)) {
      expect(m.group(0), contains('것은 아'), reason: m.group(0));
    }
    expect(item.checklistNoteKo, contains('면제'));

    // ID is offered as alternatives, not a single mandatory document.
    final checklistKo = item.checklistKo.join('\n');
    expect(checklistKo, contains('외국인등록증'));
    expect(checklistKo, contains('여권'));
    expect(checklistKo, contains('모바일 건강보험증'));

    // Nothing claims E-Gen has an English site — that was never verified.
    expect(dump.contains('English version'), isFalse);
    final egen = item.links.first;
    expect(egen.descriptionEn, contains('in Korean'));

    // Dropped on purpose: dated Busan pharmacy hours and the surcharge figure.
    expect(dump.contains('야간약국'), isFalse);
    expect(dump.contains('할증'), isFalse);
    // And no nearby-map buttons: the search is pinned to the Seunghak campus.
    expect(dump.contains('/map?nearby='), isFalse);
    expect(dump.contains('/map?focus='), isFalse);
  });

  testWidgets('Guide detail: hospital guide renders its sections in order',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
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
    expect(
      find.text('Care, prescriptions & after-hours help'),
      findsOneWidget,
    );

    await tester.tap(find.text('Visiting a Hospital'));
    await tester.pumpAndSettle();
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    const titles = [
      'Overview',
      'If it is an emergency',
      'Before you go',
      'Steps',
      'At the reception desk',
      'Before going to a tertiary hospital',
      'Insurance and what you pay',
      'Prescriptions and pharmacies',
      'Nights, weekends and holidays',
      'If you are worried about the language',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // The 119 row sits inside the emergency block, above the procedure.
    expect(find.text('Call 119'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Call 119')).dy,
      lessThan(tester.getTopLeft(find.text('Steps')).dy),
    );

    // The ID rule reads as an insurance condition, with the waiver stated.
    expect(
      find.textContaining('not a condition for being seen at all'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Turning up without ID does not mean you will be '
          'turned away'),
      findsOneWidget,
    );
    // Referral rule present, with the app explicitly declining to judge.
    expect(
      find.textContaining('This app does not tell you which hospitals are '
          'tertiary hospitals'),
      findsOneWidget,
    );
    // Non-covered care is acknowledged rather than glossed over (stated in the
    // section, repeated once in the tips).
    expect(find.textContaining('Not everything is covered'), findsNWidgets(2));

    // E-Gen and the insurance guide appear twice — once in the section that
    // needs them, once in the bottom links block.
    expect(find.text('E-Gen emergency medical portal'), findsNWidgets(2));
    expect(find.text('Guide — National Health Insurance'), findsNWidgets(2));
    // The campus clinic and emergency contacts are bottom-block only.
    expect(find.text('Guide — Campus Health Center'), findsOneWidget);
    expect(find.text('Guide — Emergency Contacts'), findsOneWidget);

    // The language section carries no link rows and never names the clinic —
    // it only says to ring ahead and ask, so nothing there reads as a
    // foreign-language service.
    final languageY =
        tester.getTopLeft(find.text('If you are worried about the language')).dy;
    final tipsY = tester.getTopLeft(find.text('Good to know')).dy;
    final clinicRowY =
        tester.getTopLeft(find.text('Guide — Campus Health Center')).dy;
    expect(clinicRowY, greaterThan(tipsY),
        reason: 'the clinic row must sit in the bottom links, not the '
            'language section');
    expect(languageY, lessThan(tipsY));
    // Nothing between the language heading and the tips heading mentions it.
    expect(
      find.textContaining('campus health clinic'),
      findsNothing,
      reason: 'the clinic is only ever a link label, never prose',
    );

    // English ARC wording matches the rest of the app.
    expect(find.textContaining('Residence Card (ARC)'), findsWidgets);
    expect(find.textContaining('Alien registration card'), findsNothing);
    // The overview no longer states the ID check unconditionally.
    expect(
      find.textContaining('you may need to verify your identity at reception'),
      findsOneWidget,
    );

    // No related-location card, so no hospital looks recommended.
    expect(find.text('동아대학교병원(본관)'), findsNothing);
  });

  testWidgets('Guide detail: hospital guide in-app links route in-app',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
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
    await tester.tap(find.text('Visiting a Hospital'));
    await tester.pumpAndSettle();

    // Both rows appear twice — once inside their own section, once in the
    // bottom links block. `.first` is the section copy, which is what this
    // test exercises (the bottom block is covered by the ARC guide's test).
    expect(find.text('Guide — National Health Insurance'), findsNWidgets(2));

    // The insurance row inside "Insurance and what you pay" opens that guide
    // without leaving the app. `pumpAndSettle` returns while the mock repo's
    // delayed load is still pending (a Future schedules no frames), so the
    // destination has to be given that time before it is asserted on.
    await tester.tap(find.text('Guide — National Health Insurance').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.text('National Health Insurance for International Students'),
      findsOneWidget,
    );

    // Back to the hospital guide. `_LinkRow` uses `context.go`, which replaces
    // the route rather than pushing one, so re-enter from the tab instead of
    // popping.
    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visiting a Hospital'));
    await tester.pumpAndSettle();

    // …and so does the campus-clinic row in the bottom links block (the only
    // place it appears).
    expect(find.text('Guide — Campus Health Center'), findsOneWidget);
    await tester.tap(find.text('Guide — Campus Health Center'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Where can I find it?'), findsOneWidget);

    // Drain the clinic page's related-location lookup so no timer outlives
    // the widget tree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('Guide detail: hospital guide fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
    await tester.tap(find.text('Visiting a Hospital'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scrolling only — the 119 row is never tapped.
    final list = find.byType(ListView).last;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('Health & Insurance'), findsOneWidget);
  });

  testWidgets('Guide detail: hospital guide renders in Korean', (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('건강·보험'));
    await tester.pumpAndSettle();
    expect(find.text('접수 · 진료 · 처방전 · 야간 진료'), findsOneWidget);

    await tester.tap(find.text('병원 이용'));
    await tester.pumpAndSettle();

    for (final title in const [
      '응급이라면 먼저',
      '병원에 가기 전 확인',
      '접수할 때',
      '상급종합병원에 가기 전에',
      '건강보험과 진료비',
      '처방전과 약국',
      '야간 · 휴일에 병원이 필요할 때',
      '언어가 걱정될 때',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('119 전화하기'), findsOneWidget);
    expect(find.textContaining('판단이 어렵다면 기다리지 말고 119에 연락하세요'), findsOneWidget);
    expect(
      find.textContaining('신분증을 가져가지 않았다고 해서 진료 자체를 받을 수 없는 것은 아닙니다'),
      findsOneWidget,
    );
    expect(
      find.textContaining('어떤 병원이 상급종합병원인지는 이 앱이 판단하지 않습니다'),
      findsOneWidget,
    );
    expect(find.textContaining('요양급여의뢰서'), findsWidgets);
    expect(find.text('응급의료포털 E-Gen'), findsNWidgets(2));

    // The overview states the ID check as conditional, matching the waivers.
    expect(
      find.textContaining('접수할 때 본인확인이 필요한 경우가 있습니다'),
      findsOneWidget,
    );
    // The language section grades nothing, carries no link rows, and does not
    // mention the campus clinic; the clinic appears once, as a link label in
    // the bottom block.
    expect(find.textContaining('증상이 가볍'), findsNothing);
    expect(find.textContaining('보건진료소'), findsNothing);
    expect(
      find.textContaining('전화해 어떤 언어가 가능한지 확인해 보세요'),
      findsOneWidget,
    );
    expect(find.text('가이드 — 교내 보건소'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('가이드 — 교내 보건소')).dy,
      greaterThan(tester.getTopLeft(find.text('알아두면 좋은 점')).dy),
    );

    // No amounts leak onto the Korean page either.
    expect(find.textContaining('원)'), findsNothing);
  });

  testWidgets('Favorite toggle works from the hospital guide', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visiting a Hospital'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Visiting a Hospital'), findsOneWidget);
  });

  // NOTE: the two call rows carry real emergency numbers. Nothing in this file
  // taps them — the urls are asserted as data, and the widget tests only ever
  // look at the labels. Never add a tap on "Call 112" / "Call 119".
  test('Emergency contacts: call rows are tel: links, and 1345 is gone', () {
    final item =
        MockData.guideItems.firstWhere((g) => g.id == 'emergency-contacts');

    final police = item.topSections.firstWhere((s) => s.titleEn == '112 — Police');
    final fire = item.topSections
        .firstWhere((s) => s.titleEn == '119 — Fire · Rescue · Ambulance');
    expect(police.links.single.url, 'tel:112');
    expect(police.links.single.labelKo, '112 전화하기');
    expect(police.links.single.labelEn, 'Call 112');
    expect(fire.links.single.url, 'tel:119');
    expect(fire.links.single.labelKo, '119 전화하기');
    expect(fire.links.single.labelEn, 'Call 119');

    // `tel:` is external, so it hands off to the phone app instead of routing
    // in-app. It is never auto-dialled: _LinkRow only launches from onTap.
    expect(police.links.single.url.startsWith('/'), isFalse);
    expect(fire.links.single.url.startsWith('/'), isFalse);

    expect(item.summaryKo, '112 · 119 긴급신고 안내');
    expect(item.summaryEn, 'Police 112 · Fire & Ambulance 119');

    // 1345 is immigration counselling, not an emergency line — it must not
    // appear anywhere in this item, in either language.
    final dump = [
      item.summaryKo, item.summaryEn, item.overviewKo, item.overviewEn,
      ...item.tipsKo, ...item.tipsEn,
      for (final s in [...item.topSections, ...item.sections]) ...[
        s.titleKo, s.titleEn, s.bodyKo, s.bodyEn, s.noticeKo, s.noticeEn,
        s.footnoteKo, s.footnoteEn,
        ...s.stepsKo, ...s.stepsEn,
        for (final l in s.links) '${l.labelKo}${l.labelEn}${l.url}',
        for (final n in s.notes) ...[
          n.titleKo, n.titleEn, ...n.linesKo, ...n.linesEn,
        ],
      ],
      for (final l in item.links)
        '${l.labelKo}${l.labelEn}${l.url}${l.descriptionKo}${l.descriptionEn}',
    ].whereType<String>().join('\n');
    expect(dump.contains('1345'), isFalse);

    // ...but the visa guides that legitimately cite 1345 keep it.
    final elsewhere = MockData.guideItems
        .where((g) => g.id != 'emergency-contacts')
        .any((g) => g.sections.any((s) => (s.noticeKo ?? '').contains('1345')));
    expect(elsewhere, isTrue);
  });

  testWidgets('Guide detail: emergency contacts renders 112 and 119',
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
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();

    // S6 row subtitle no longer advertises 1345.
    expect(find.text('Police 112 · Fire & Ambulance 119'), findsOneWidget);
    expect(find.textContaining('1345'), findsNothing);

    await tester.tap(find.text('Emergency Contacts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    const titles = [
      'In an emergency',
      '112 — Police',
      '119 — Fire · Rescue · Ambulance',
      'What to tell the operator',
      'Emergency phrases',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // The 112/119 split is the first thing on the page, above both sections.
    final splitY = tester.getTopLeft(
        find.textContaining('Are you in immediate danger?')).dy;
    expect(splitY, lessThan(tester.getTopLeft(find.text('112 — Police')).dy));

    // Call rows are present (NOT tapped) inside their own number's section.
    expect(find.text('Call 112'), findsOneWidget);
    expect(find.text('Call 119'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Call 112')).dy,
      lessThan(tester.getTopLeft(find.text('119 — Fire · Rescue · Ambulance')).dy),
    );

    // Location is the emphasised part of what to tell the operator.
    expect(find.textContaining('Tell them your location first'), findsOneWidget);
    expect(
      find.textContaining('Dong-A University, Seunghak Campus'),
      findsOneWidget,
    );
    // Phrases show both languages at once.
    expect(find.text('I need the police.'), findsOneWidget);
    expect(find.text('경찰이 필요합니다'), findsOneWidget);
    expect(find.text("I don't speak Korean well."), findsOneWidget);

    // Official links only.
    expect(find.text('Korean National Police — 112'), findsOneWidget);
    expect(find.text('National Fire Agency — 119'), findsOneWidget);

    // No duration/difficulty clutter on an emergency page.
    expect(find.textContaining('Difficulty'), findsNothing);
    // And no trace of 1345 on the detail page either.
    expect(find.textContaining('1345'), findsNothing);
  });

  testWidgets('Guide detail: emergency contacts fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emergency Contacts'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scrolling only — the call rows are never tapped.
    final list = find.byType(ListView).last;
    for (var i = 0; i < 30; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('Emergency & Help'), findsOneWidget);
  });

  testWidgets('Guide detail: emergency contacts renders in Korean',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('긴급·도움'));
    await tester.pumpAndSettle();
    expect(find.text('112 · 119 긴급신고 안내'), findsOneWidget);

    await tester.tap(find.text('긴급 연락처'));
    await tester.pumpAndSettle();

    for (final title in const [
      '긴급상황 안내',
      '112 — 경찰',
      '119 — 화재 · 구조 · 구급',
      '신고할 때 알려주세요',
      '긴급상황 표현',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.textContaining('지금 즉시 위험한 상황인가요?'), findsOneWidget);
    expect(find.text('112 전화하기'), findsOneWidget);
    expect(find.text('119 전화하기'), findsOneWidget);
    expect(find.textContaining('위치를 먼저 알려주세요'), findsOneWidget);
    expect(find.textContaining('1345'), findsNothing);
  });

  testWidgets('Favorite toggle works from the emergency contacts guide',
      (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emergency Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency Contacts'), findsOneWidget);
  });

  testWidgets('Guide detail: dormitory guide renders its sections in order',
      (tester) async {
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
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dormitory Application'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.text('Check the dates'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    // Hall names repeat as link labels further down, so position is taken from
    // the first (section-heading) occurrence.
    const titles = [
      'Overview',
      'Which dormitory can I use?',
      'Hanlim Residence Hall',
      'Seokdang Global House',
      'Before You Apply',
      'Steps',
      'Before Moving In',
      'After Moving In',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title).first).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // The two halls a student picks between.
    expect(find.text('🏫 Hanlim Residence Hall'), findsOneWidget);
    expect(find.text('🌏 Seokdang Global House'), findsOneWidget);

    // Hanlim — current recruitment notice, not the 2024 booklet's routes.
    expect(find.textContaining('apply online on the Hanlim website'),
        findsOneWidget);
    expect(find.textContaining('send them by email'), findsOneWidget);
    expect(
      find.textContaining('The application period changes every semester'),
      findsOneWidget,
    );
    // Seokdang — a separate application IS required per the official page.
    expect(find.textContaining('Hand the form in at the Seokdang Global House '
        'office'), findsOneWidget);
    // The 2024 "no separate application / compulsory 3 months" line is offered
    // as something to verify, never as the current rule.
    expect(
      find.textContaining('may be told something different'),
      findsOneWidget,
    );

    // No 2024 figure is restated as today's price.
    expect(find.textContaining('756,000'), findsNothing);
    expect(find.textContaining('800,000'), findsNothing);
    expect(find.textContaining('For the exact amount'), findsOneWidget);

    // Bedding / meals / health certificate are conditional, never universal.
    expect(find.textContaining('Some dormitories do not provide bedding'),
        findsOneWidget);
    expect(find.textContaining('You may need a health-check certificate'),
        findsOneWidget);

    // Official Dong-A links only, plus the in-app map row.
    expect(find.text('Hanlim recruitment notice'), findsOneWidget);
    expect(find.text('Seokdang Global House — moving in and out'),
        findsOneWidget);
    expect(find.text('International Affairs Office — student support'),
        findsOneWidget);
    expect(find.text('View the dormitories on the map'), findsOneWidget);
    // Related locations resolve to real campus facilities.
    expect(find.text('한림생활관 승학1관'), findsOneWidget);
    expect(find.text('한림생활관 승학2관'), findsOneWidget);
  });

  testWidgets('Guide detail: dormitory map link opens the map in-app',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dormitory Application'));
    await tester.pumpAndSettle();

    // Internal route (`/map?focus=s15,s19`) → stays in the app on the Map tab.
    final link = find.text('View the dormitories on the map');
    await tester.scrollUntilVisible(link, 400);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Map'), findsOneWidget);
  });

  testWidgets('Guide detail: dormitory guide fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dormitory Application'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).last;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('Housing'), findsOneWidget);
  });

  testWidgets('Guide detail: dormitory guide renders in Korean',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주거'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기숙사 신청'));
    await tester.pumpAndSettle();

    for (final title in const [
      '개요',
      '어떤 기숙사가 있나요?',
      '한림생활관',
      '석당글로벌하우스',
      '신청 전에 확인하세요',
      '단계',
      '입사 전 준비',
      '입사 후 해야 할 일',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    expect(find.textContaining('신청기간 확인 필요'), findsOneWidget);
    expect(find.textContaining('한림생활관 최신 모집공고를 확인하세요'), findsOneWidget);
    expect(find.textContaining('입사신청서를 작성'), findsWidgets);
    expect(find.text('지도에서 기숙사 위치 보기'), findsOneWidget);
    // 2024 booklet figures stay out of the body copy.
    expect(find.textContaining('756,000'), findsNothing);
  });

  testWidgets('Favorite toggle works from the dormitory guide', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dormitory Application'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Dormitory Application'), findsOneWidget);
  });

  testWidgets('Guide detail: off-campus housing renders its sections in order',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 20000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finding Off-Campus Housing'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon', findRichText: true), findsNothing);
    expect(find.text('A few days to weeks'), findsOneWidget);
    expect(find.textContaining('Difficulty'), findsOneWidget);

    const titles = [
      'Overview',
      'Types of Housing in Korea',
      'How to Find a Room',
      'Looking Near Dong-A University',
      'What to Check During a Viewing',
      'Before You Sign',
      'What to Check in the Lease',
      'Steps',
      'Moving In',
      'Reporting Your Address & Protecting Your Deposit',
      'Deposits, Rent & Fees',
      'Using a Licensed Agent',
      'Avoiding Rental Scams & Disputes',
      'Words You Will See in the Lease',
      'Good to know',
      'Links & Locations',
    ];
    for (final title in titles) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title).first).dy;
      expect(y, greaterThan(previous), reason: title);
      previous = y;
    }

    // Housing types and payment models are separated, jeonse is explained but
    // not pushed at newly-arrived students.
    expect(find.text('🏠 Kinds of room'), findsOneWidget);
    expect(find.text('💳 Ways of paying'), findsOneWidget);
    expect(find.textContaining('Jeonse means a very large deposit'),
        findsOneWidget);

    // Campus-relative advice, with the three in-app map rows.
    expect(find.text('View the Seunghak campus on the map'), findsOneWidget);
    expect(find.text('View the Bumin campus on the map'), findsOneWidget);
    expect(find.text('View the Gudeok campus on the map'), findsOneWidget);
    expect(find.textContaining('Travel time matters more than distance'),
        findsOneWidget);

    // Pre-signing checks, sourced from the property register.
    expect(find.textContaining('property register'), findsWidgets);
    expect(find.textContaining('Korean Court Internet Registry Office'),
        findsWidgets);
    expect(find.textContaining('third party account'), findsOneWidget);
    expect(find.textContaining('Do not sign what you do not understand'),
        findsOneWidget);

    // The maintenance fee is framed as "what does it cover", not a number.
    expect(find.text('What does the maintenance fee cover?'), findsOneWidget);

    // Address reporting: the 15-day deadline and the deposit link, from the
    // official guidance.
    expect(find.textContaining('within 15 days of moving in'), findsOneWidget);
    expect(find.textContaining('the day AFTER you take possession'),
        findsOneWidget);
    expect(find.textContaining('fixed date'), findsWidgets);
    expect(find.textContaining('Immigration Control Act arts. 36 and 88-2'),
        findsOneWidget);

    // Commission: ceiling explained, no rate table baked into the app.
    expect(find.textContaining('There is a ceiling on the commission'),
        findsOneWidget);
    expect(find.textContaining('no fixed table is built into the app'),
        findsOneWidget);

    // Scam prevention, and HUG framed as "not every contract qualifies".
    expect(find.textContaining('Do not send money for a place you have not'),
        findsOneWidget);
    expect(find.textContaining('Not every contract qualifies'), findsOneWidget);

    // No invented prices or rates anywhere on the page.
    expect(find.textContaining('만원'), findsNothing);
    expect(find.textContaining('0.3%'), findsNothing);
    expect(find.textContaining('0.5%'), findsNothing);

    // Official public-body links only, plus the in-app ARC guide.
    expect(find.text('Korean Court Internet Registry Office'), findsOneWidget);
    expect(find.text('HUG safe-lease portal'), findsOneWidget);
    expect(find.text('Busan Foreign Resident Call Center'), findsOneWidget);
    expect(find.text('Korea Legal Aid Corporation'), findsOneWidget);
    expect(find.text('HiKorea e-application — change of residence'),
        findsOneWidget);
    expect(find.text('Guide — Alien Registration Card'), findsOneWidget);
  });

  testWidgets('Guide detail: off-campus housing campus map link opens in-app',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finding Off-Campus Housing'));
    await tester.pumpAndSettle();

    // Internal route (`/map?focus=s01`) → stays in the app on the Map tab.
    final link = find.text('View the Seunghak campus on the map');
    await tester.scrollUntilVisible(link, 400);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Map'), findsOneWidget);
  });

  testWidgets('Guide detail: off-campus housing fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finding Off-Campus Housing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).last;
    for (var i = 0; i < 80; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Links & Locations'), findsNothing);
    expect(find.text('Housing'), findsOneWidget);
  });

  testWidgets('Guide detail: off-campus housing renders in Korean',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 20000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주거'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('교외주거 구하기'));
    await tester.pumpAndSettle();

    for (final title in const [
      '개요',
      '한국의 주거 형태',
      '방을 찾는 방법',
      '동아대학교 주변에서 찾을 때',
      '집을 보러 갈 때 확인',
      '계약 전에 확인하세요',
      '계약서에서 확인할 내용',
      '단계',
      '입주 전 · 입주 후 확인',
      '이사 후 신고와 보증금 보호',
      '보증금 · 월세 이해하기',
      '부동산 중개 이용',
      '사기 · 분쟁 예방',
      '계약에서 자주 나오는 말',
      '알아두면 좋은 점',
      '관련 링크 · 위치',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    expect(find.text('수일~수주'), findsOneWidget);
    expect(find.textContaining('전입한 날부터 15일 이내'), findsOneWidget);
    expect(find.textContaining('등기사항증명서'), findsWidgets);
    expect(find.textContaining('보증금 — Deposit'), findsOneWidget);
    expect(find.text('지도에서 승학캠퍼스 보기'), findsOneWidget);
    // No invented market prices.
    expect(find.textContaining('만원'), findsNothing);
  });

  testWidgets('Favorite toggle works from the off-campus housing guide',
      (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finding Off-Campus Housing'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Finding Off-Campus Housing'), findsOneWidget);
  });

  testWidgets('Guide detail: coming-soon item shows placeholder', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();

    // Emergency & Help → "Counseling" is still a placeholder. (Health &
    // Insurance no longer has one — its last stub, the hospital guide, is
    // written.)
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counseling'));
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
