import 'package:campus_on/app.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/repositories/guide_repository.dart';
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

/// Opens the guide category hub (S5) from the home "Admin guide" card (the
/// Guide bottom tab was removed; /guide now lives inside the Home branch).
/// `AppRouter.router` is a static singleton, so a later test boots wherever the
/// previous one navigated to — tapping the Home tab first pops the home branch
/// back to its root so the card is on screen.
Future<void> _openGuideHub(WidgetTester tester, {bool ko = false}) async {
  await tester.tap(find.text(ko ? '홈' : 'Home'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(ko ? '행정 가이드' : 'Admin guide'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Guide tab: categories → item list → detail', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);

    // S5 — the 6 categories render (hardcoded).
    expect(find.text('Immigration & Stay'), findsOneWidget);
    expect(find.text('Emergency & Help'), findsOneWidget);

    // → S6 item list for Immigration.
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Residence Card (ARC)'), findsOneWidget);

    // → S7 detail: the published exemplar shows its sections.
    await tester.tap(find.text('Residence Card (ARC)'));
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    final arcLink = find.text('Guide — Residence Card (ARC)');
    await tester.scrollUntilVisible(arcLink, 400);
    await tester.pumpAndSettle();
    await tester.tap(arcLink);
    await tester.pumpAndSettle();
    expect(find.text('Residence Card (ARC)'), findsWidgets);

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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
    await tester.tap(find.text('Health & Insurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('National Health Insurance'));
    await tester.pumpAndSettle();

    // `/guide/item/...` is internal, so it opens the ARC guide in-app. The
    // health-insurance link keeps its own (older) label — the target page is
    // what carries the official card name.
    final arcLink = find.text('Guide — Alien Registration Card (ARC)');
    await tester.scrollUntilVisible(arcLink, 400);
    await tester.pumpAndSettle();
    await tester.tap(arcLink);
    await tester.pumpAndSettle();
    expect(find.text('Residence Card (ARC)'), findsWidgets);

    // Drain the ARC page's related-location lookup (mock repo delay) so no
    // timer outlives the widget tree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  // main's old "coming-soon item shows placeholder" test is gone: every real
  // guide is published now, so the coming-soon path is covered by the
  // stub-repository test near the end of this file instead.
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    expect(find.text('University Administration & College of Humanities (A)'), findsOneWidget);
    expect(find.text('General Lecture Building (BA-BD)'), findsOneWidget);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    expect(find.text('Hanlim Library (B)'), findsOneWidget);
    expect(find.text('International Hall'), findsOneWidget);
    expect(find.text('Law School (LS)'), findsOneWidget);
    expect(find.text('Gudeok Education Buildings 2 & 3'), findsOneWidget);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    expect(find.text('General Lecture Building (BA-BD)'), findsOneWidget);
  });

  testWidgets('Guide detail: OIA map link opens the map in-app', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    expect(find.text('Law School (LS)'), findsOneWidget);
    expect(find.text('Student Union Building (Q)'), findsOneWidget);
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

    await _openGuideHub(tester);
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
    expect(find.text('Dong-A University Hospital (Main)'), findsNothing);
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

    await _openGuideHub(tester);
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
    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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
    expect(find.text('Hanlim Dormitory Seunghak Hall 1'), findsOneWidget);
    expect(find.text('Hanlim Dormitory Seunghak Hall 2'), findsOneWidget);
  });

  testWidgets('Guide detail: dormitory map link opens the map in-app',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester);
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

    await _openGuideHub(tester, ko: true);
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

    await _openGuideHub(tester);
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

  // ── counseling ────────────────────────────────────────────────────────────
  // NOTE: this page carries real emergency and counselling numbers (112, 119,
  // 109 and four university lines). Nothing here taps a `tel:` row — the urls
  // are asserted as data and the widget tests only read the labels.
  test('Counseling guide: data-level guarantees (no judgement, no guessing)',
      () {
    final item = MockData.guideItems.firstWhere((g) => g.id == 'counseling');

    expect(item.status, GuideStatus.published);
    expect(item.categoryId, GuideCategory.emergency);
    expect(item.titleKo, '상담 창구');
    expect(item.titleEn, 'Counseling');
    expect(item.summaryKo, '심리·생활 상담 안내');
    expect(item.summaryEn, 'Wellbeing & life support');

    // The two counselling offices, and only those — the human rights centre
    // sits in s01 but stays out of the map cards on purpose.
    expect(item.relatedFacilityIds, ['s02', 'b04']);
    expect(item.relatedFacilityIds.contains('s01'), isFalse);

    // Safety block first, owning 112/119 and the emergency-contacts route.
    final urgent = item.topSections.single;
    expect(urgent.titleKo, '지금 즉시 위험한 상황이라면');
    expect(urgent.titleEn, 'If you are in immediate danger');
    expect(
      urgent.links.map((l) => l.url).toList(),
      const ['tel:112', 'tel:119', '/guide/item/emergency-contacts'],
    );

    // Section order, and the desk each one belongs to.
    expect(
      item.sections.map((s) => s.titleKo).toList(),
      const [
        '학생상담센터',
        '어디에서 상담받나요?',
        '상담 신청 방법',
        '유학생 학사 · 학교생활 문의',
        '인권침해 · 성희롱 · 성폭력 문제라면',
        '24시간 자살예방 상담',
      ],
    );

    // Every link on the page, section-level and bottom block.
    final allUrls = [
      for (final s in [...item.topSections, ...item.sections])
        ...s.links.map((l) => l.url),
      ...item.links.map((l) => l.url),
    ];
    // Each phone row the brief asks for is present, exactly as a tel: url.
    for (final tel in const [
      'tel:112',
      'tel:119',
      'tel:0512006070',
      'tel:0512008775',
      'tel:0512006447',
      'tel:0512005711',
      'tel:109',
    ]) {
      expect(allUrls.contains(tel), isTrue, reason: tel);
    }
    // No other tel: row slipped in.
    expect(allUrls.where((u) => u.startsWith('tel:')).length, 7);

    // Bottom block: four rows, in the agreed order.
    expect(
      item.links.map((l) => l.url).toList(),
      const [
        'https://guide.donga.ac.kr/',
        'https://human.donga.ac.kr/',
        '/guide/item/oia-visit',
        '/guide/item/emergency-contacts',
      ],
    );
    // incident-response is still a stub, and the campus clinic is not a
    // counselling desk — neither is linked from here.
    expect(allUrls.any((u) => u.contains('incident-response')), isFalse);
    expect(allUrls.any((u) => u.contains('campus-clinic')), isFalse);

    // Every renderable string of this item, both languages.
    final dump = [
      item.titleKo, item.titleEn, item.summaryKo, item.summaryEn,
      item.overviewKo, item.overviewEn,
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

    // No language support is claimed anywhere — no official source states
    // which languages any of these desks can work in.
    for (final banned in const [
      '영어 상담',
      '영어로 상담',
      '외국어 상담',
      '다국어',
      '통역',
      'English',
      'in your own language',
      'interpreter',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'language claim: $banned');
    }

    // Eligibility is quoted, never widened: the centre says "본교 구성원
    // 누구나", so the page never states that international students may use it.
    expect(item.overviewKo, contains('본교 구성원 누구나'));
    expect(item.overviewEn, contains('본교 구성원 누구나'));
    expect(item.sections.first.bodyKo, contains('본교 구성원 누구나'));
    for (final banned in const [
      '외국인 유학생도 이용',
      '유학생도 이용할 수 있',
      '유학생도 무료로',
      'international students can use',
      'open to international students',
      'available to international students',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'widened claim: $banned');
    }

    // The centre publishes no crisis service, so the page never implies one.
    for (final banned in const [
      '위기상담',
      '긴급상담',
      '24시간 상담을 제공',
      'crisis counselling',
      'crisis counseling',
      'emergency counselling',
      'emergency counseling',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'crisis claim: $banned');
    }

    // No diagnosis, no symptom list, no grading of how bad a problem is.
    for (final banned in const [
      '진단',
      '증상',
      '우울증',
      '불안장애',
      '자해',
      '위험도',
      '치료를 받으세요',
      '병원에 가야',
      'diagnos',
      'symptom',
      'self-harm',
      'risk assessment',
      'you should see a doctor',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'judgement: $banned');
    }
    // …and the page says so out loud, in both languages.
    expect(dump, contains('문제의 심각도나 필요한 도움의 종류를 판단하지 않습니다'));
    expect(dump, contains('does not judge how serious a problem is'));
    // The overview names no counselling topics: the centre publishes no such
    // list, so listing any would invent a scope for it.
    for (final banned in const [
      '학업이나 진로',
      '사람 사이의 관계',
      '한국 생활 적응',
      'coursework and career worries',
      'settling into',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'invented scope: $banned');
    }
    // No advice of the app's own making about when or whether to seek help.
    for (final banned in const [
      '먼저 이야기해',
      '얼마나 큰지',
      'Anything is worth bringing up',
      'how serious it is before you book',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'app advice: $banned');
    }

    // No counselling body beyond the five the brief settled on.
    for (final banned in const [
      '1345',
      '1600-0051',
      '1577-0199',
      '1577-1366',
      '1393',
      '정신건강복지센터',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'extra body: $banned');
    }

    // ── 학생상담센터 ────────────────────────────────────────────────────────
    final centre = item.sections[0];
    expect(centre.titleEn, 'Student counseling centre');
    // Only the five services the centre publishes.
    expect(
      centre.notes.first.linesKo,
      const ['개인상담', '집단상담', '심리검사와 해석상담', '상담 · 지원 프로그램', '예방교육'],
    );
    expect(centre.notes[1].linesKo,
        const ['주 1회', '한 회기 약 50분', '접수면접을 포함해 11회기 이내']);
    // Free, as officially stated.
    expect(centre.bodyKo, contains('무료'));
    expect(centre.bodyEn, contains('free'));
    // Confidentiality, with the safety exception the centre itself states.
    expect(centre.noticeKo, contains('비밀보장'));
    expect(centre.noticeKo, contains('안전'));
    expect(centre.noticeEn, contains('confidential'));
    expect(centre.noticeEn, contains('safety'));

    // ── 위치 · 운영시간 ─────────────────────────────────────────────────────
    final where = item.sections[1];
    expect(where.notes.map((n) => n.titleKo).toList(),
        const ['승학캠퍼스', '부민캠퍼스', '운영시간']);
    expect(where.notes[0].linesKo.first, contains('학생회관(Q) 3층 308호'));
    // Two official pages label the same Bumin building differently, so both
    // labels are printed. The map-facing one (종합강의동, matching facility
    // b04) leads, and the counselling centre's own wording follows it.
    expect(where.notes[1].linesKo.first, '종합강의동 BC-B102-1호');
    expect(where.notes[1].linesKo[1], contains('중앙강의동'));
    expect(where.notes[1].linesKo[1], contains('학생상담센터 안내 페이지'));
    expect(where.notes[1].linesEn.first,
        'General Lecture Building, room BC-B102-1');
    expect(where.notes[1].linesEn[1], contains('중앙강의동'));
    expect(where.notes[1].linesKo.any((l) => l.contains('BC-B102-1')), isTrue);
    // Neither label is presented as the old or the new one, and the two are
    // never treated as separate buildings.
    for (final banned in const [
      '구명칭',
      '옛 이름',
      '이전 명칭',
      '새 이름',
      '변경되었',
      'former name',
      'formerly',
      'renamed',
      'used to be called',
      'a different building',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'name claim: $banned');
    }
    expect(where.notes[2].linesKo,
        const ['학기 중: 평일 09:00~17:00', '방학 중: 평일 10:00~15:00', '점심시간 12:00~13:00']);
    // Hours are stated as changeable, with where to re-check them.
    expect(where.noticeKo, contains('최신 운영시간을 확인'));
    // 6070 is the centre office line, never described as a main university one.
    expect(dump.contains('대표전화'), isFalse);

    // ── 상담 신청 ───────────────────────────────────────────────────────────
    final booking = item.sections[2];
    // The one-to-one booking flow is published as an image only, so the page
    // points at the source instead of inventing steps.
    expect(booking.stepsKo, isEmpty);
    expect(booking.bodyKo, contains('최신 안내를 확인'));
    expect(booking.bodyKo, contains('DECO'));
    expect(booking.notes.single.titleKo, '고민 우체통');
    expect(booking.footnoteKo, contains('개인상담을 대신하는 것은 아닙니다'));

    // ── 국제교류과 ──────────────────────────────────────────────────────────
    final oia = item.sections[3];
    // Its stated counselling role is academic support, and the body says only
    // that — the split from wellbeing counselling is spelled out in the note.
    expect(oia.bodyKo, contains('유학생 학사 지원 및 상담'));
    expect(oia.bodyKo!.contains('심리'), isFalse);
    expect(oia.footnoteKo, contains('학생상담센터에서 진행합니다'));

    // ── 인권센터 ────────────────────────────────────────────────────────────
    final rights = item.sections[4];
    expect(rights.bodyKo, contains('상담과 신고를 접수'));
    expect(rights.notes.single.linesKo.first, contains('503호'));
    expect(rights.notes.single.linesKo, contains('전화 051-200-5711'));
    // The page does not restate an investigation or disciplinary procedure.
    expect(rights.footnoteKo, contains('이 페이지에서 다루지 않습니다'));

    // ── 109 ─────────────────────────────────────────────────────────────────
    final always = item.sections[5];
    expect(always.titleKo, '24시간 자살예방 상담');
    expect(always.titleEn, '24-hour suicide-prevention support');
    expect(always.bodyKo, contains('자살예방 관련 상담이 필요할 경우'));
    expect(always.bodyKo, contains('24시간'));
    expect(always.bodyEn, contains('suicide-prevention support'));
    expect(always.bodyEn, contains('24 hours a day'));
    // 109 is a suicide-prevention line, not an after-hours stand-in for the
    // counselling centre — nothing here frames it as one.
    for (final banned in const [
      '문을 닫는 시간',
      '학생상담센터가 문을 닫',
      'when the campus offices are closed',
      'after hours',
      'at any hour',
    ]) {
      expect(always.bodyKo!.contains(banned), isFalse, reason: '109: $banned');
      expect(always.bodyEn!.contains(banned), isFalse, reason: '109: $banned');
      expect(always.titleKo.contains(banned), isFalse, reason: '109: $banned');
      expect(always.titleEn.contains(banned), isFalse, reason: '109: $banned');
    }
    expect(always.links.map((l) => l.url).toList(),
        const ['tel:109', 'https://www.129.go.kr/109']);
    // Nothing about who may call it or in what language.
    final alwaysText = [
      always.bodyKo, always.bodyEn, always.noticeKo, always.noticeEn,
      for (final l in always.links)
        '${l.labelKo}${l.labelEn}${l.descriptionKo ?? ''}'
            '${l.descriptionEn ?? ''}',
    ].whereType<String>().join('\n');
    for (final banned in const ['영어', 'English', '외국인', '지원 언어']) {
      expect(alwaysText.contains(banned), isFalse, reason: '109: $banned');
    }
  });

  testWidgets('Guide detail: counseling guide renders its sections in order',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    expect(find.text('Wellbeing & life support'), findsOneWidget);

    await tester.tap(find.text('Counseling'));
    await tester.pumpAndSettle();
    // Published now — the placeholder must be gone.
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    const titles = [
      'Overview',
      'If you are in immediate danger',
      'Student counseling centre',
      'Where to go, and when',
      'How to book',
      'Academic support for international students',
      'Harassment, sexual violence and rights violations',
      '24-hour suicide-prevention support',
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

    // The safety rows sit in the top block, above the counselling centre.
    expect(find.text('Call 112'), findsOneWidget);
    expect(find.text('Call 119'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Call 119')).dy,
      lessThan(tester.getTopLeft(find.text('Student counseling centre')).dy),
    );

    // Eligibility is quoted, not widened, and the cost is the published one.
    expect(find.textContaining('본교 구성원 누구나'), findsWidgets);
    expect(find.textContaining('every programme it runs is free'), findsWidgets);
    expect(
      find.textContaining('does not judge how serious a problem is'),
      findsOneWidget,
    );
    // Both campuses are named rather than counted — the university has three.
    expect(
      find.text('The centre has offices on the Seunghak and Bumin campuses.'),
      findsOneWidget,
    );
    expect(find.textContaining('each of the two campuses'), findsNothing);

    // Both offices, with the building the floor guide lists them in.
    expect(
      find.text('Student Union Building (Q), 3rd floor, room 308'),
      findsOneWidget,
    );
    expect(
      find.text('General Lecture Building, room BC-B102-1'),
      findsOneWidget,
    );
    // …and the label the counselling centre's own page uses, so a student
    // who arrives from that page recognises the building.
    expect(
      find.textContaining('labels this building 중앙강의동'),
      findsOneWidget,
    );
    expect(find.text('Term time: weekdays 09:00–17:00'), findsOneWidget);
    expect(find.text('Lunch break 12:00–13:00'), findsOneWidget);

    // Rows that appear both in their own section and in the bottom block.
    expect(find.text('Guide — Emergency Contacts'), findsNWidgets(2));
    expect(find.text('Guide — International Affairs Office'), findsNWidgets(2));
    expect(find.text('Student counseling centre website'), findsNWidgets(2));
    expect(find.text('Human rights centre (인권센터) website'), findsNWidgets(2));

    // One related-location card per counselling office, and no third one.
    expect(find.text('Student Union Building (Q)'), findsOneWidget);
    expect(find.text('General Lecture Building (BA-BD)'), findsOneWidget);
    expect(find.text('University Administration & College of Humanities (A)'), findsNothing);
  });

  testWidgets('Guide detail: counseling guide in-app links route in-app',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counseling'));
    await tester.pumpAndSettle();

    // The emergency-contacts row inside the safety block. `pumpAndSettle`
    // returns while the mock repo's delayed load is still pending, so the
    // destination needs that time before it is asserted on.
    await tester.tap(find.text('Guide — Emergency Contacts').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('In an emergency'), findsOneWidget);

    // `_LinkRow` uses `context.go`, which replaces the route rather than
    // pushing one, so re-enter from the tab instead of popping.
    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counseling'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guide — International Affairs Office').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('What can I ask about?'), findsOneWidget);

    // Drain the OIA page's related-location lookup so no timer outlives the
    // widget tree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('Guide detail: counseling guide fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counseling'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scrolling only — no call row is ever tapped.
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
    expect(find.text('Emergency & Help'), findsOneWidget);
  });

  testWidgets('Guide detail: counseling guide renders in Korean',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await _openGuideHub(tester, ko: true);
    await tester.tap(find.text('긴급·도움'));
    await tester.pumpAndSettle();
    expect(find.text('심리·생활 상담 안내'), findsOneWidget);

    await tester.tap(find.text('상담 창구'));
    await tester.pumpAndSettle();

    for (final title in const [
      '지금 즉시 위험한 상황이라면',
      '학생상담센터',
      '어디에서 상담받나요?',
      '상담 신청 방법',
      '유학생 학사 · 학교생활 문의',
      '인권침해 · 성희롱 · 성폭력 문제라면',
      '24시간 자살예방 상담',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.text('112 전화하기'), findsOneWidget);
    expect(find.text('119 전화하기'), findsOneWidget);
    expect(find.text('109 전화하기'), findsOneWidget);
    expect(find.textContaining('본교 구성원 누구나'), findsWidgets);
    expect(find.text('학생회관(Q) 3층 308호'), findsOneWidget);
    // Both official labels for the same building, map-facing one first.
    expect(find.text('종합강의동 BC-B102-1호'), findsOneWidget);
    expect(
      find.textContaining('학생상담센터 안내 페이지에는 「중앙강의동」으로 표기'),
      findsOneWidget,
    );
    // The map card still carries the facility name (Korean here — ko locale),
    // so b04 is unambiguous.
    expect(find.text('종합강의동(BA-BD)'), findsOneWidget);
    expect(find.text('학기 중: 평일 09:00~17:00'), findsOneWidget);
    expect(find.textContaining('최신 운영시간을 확인'), findsOneWidget);
    expect(find.text('전화 051-200-5711'), findsOneWidget);
    expect(find.text('전화 051-200-6447'), findsOneWidget);

    // Nothing on the Korean page grades a problem or names a symptom.
    expect(find.textContaining('증상'), findsNothing);
    expect(find.textContaining('진단'), findsNothing);
    expect(find.textContaining('위기상담'), findsNothing);
    expect(find.textContaining('외국어 상담'), findsNothing);
    // …and the line stating that the app itself judges nothing is shown.
    expect(
      find.textContaining('문제의 심각도나 필요한 도움의 종류를 판단하지 않습니다'),
      findsOneWidget,
    );
    // 109 appears as a suicide-prevention line only.
    expect(find.textContaining('자살예방 관련 상담이 필요할 경우'), findsOneWidget);
    expect(find.textContaining('문을 닫는 시간'), findsNothing);
  });

  testWidgets('Favorite toggle works from the counseling guide',
      (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counseling'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Counseling'), findsOneWidget);
  });

  // ── incident-response ─────────────────────────────────────────────────────
  // NOTE: this page carries 112, 119 and 1345 as real `tel:` rows. Nothing here
  // taps one — the urls are asserted as data, the widget tests read labels only.
  test('Incident response: data-level guarantees (no judgement, no guessing)',
      () {
    final item =
        MockData.guideItems.firstWhere((g) => g.id == 'incident-response');

    expect(item.status, GuideStatus.published);
    expect(item.categoryId, GuideCategory.emergency);
    expect(item.titleKo, '사건·사고 대응');
    expect(item.titleEn, 'Incident Response');
    expect(item.summaryKo, '분실·도난·사고 시 대응');
    expect(item.summaryEn, 'Loss, theft, accidents');

    // No map card: there is no police facility in the data, and any card here
    // would read as "go to this one".
    expect(item.relatedFacilityIds, isEmpty);

    // Safety block first, owning 112/119 and the emergency-contacts route.
    final urgent = item.topSections.single;
    expect(urgent.titleKo, '지금 즉시 위험하다면');
    expect(urgent.titleEn, 'If you are in immediate danger');
    expect(
      urgent.links.map((l) => l.url).toList(),
      const ['tel:112', 'tel:119', '/guide/item/emergency-contacts'],
    );

    expect(
      item.sections.map((s) => s.titleEn).toList(),
      const [
        'If you lost an item',
        'If you were affected by theft or a crime',
        'If you lost your passport or Residence Card',
        'If an accident happens',
        'If you need support afterwards',
      ],
    );

    final allUrls = [
      for (final s in [...item.topSections, ...item.sections])
        ...s.links.map((l) => l.url),
      ...item.links.map((l) => l.url),
    ];
    // Exactly the three phone rows the brief settled on.
    expect(
      allUrls.where((u) => u.startsWith('tel:')).toSet(),
      {'tel:112', 'tel:119', 'tel:1345'},
    );
    expect(allUrls.where((u) => u.startsWith('tel:')).length, 3);
    // External links: the police portal and HiKorea only. The 외교부 mission
    // directory is absent on purpose — mofa.go.kr could not be reached to
    // verify the URL, and a broken link is worse than none.
    expect(
      allUrls.where((u) => u.startsWith('http')).toList(),
      const [
        'https://minwon24.police.go.kr/cvlcpt/cvlcptGdInfo.do?cvlcptId=MW-001',
        'https://www.hikorea.go.kr/info/InfoFrnReportLostPageR.pt',
        'https://minwon24.police.go.kr/',
        'https://www.hikorea.go.kr/info/InfoFrnReportLostPageR.pt',
      ],
    );
    expect(allUrls.any((u) => u.contains('mofa.go.kr')), isFalse);
    // In-app routes.
    for (final route in const [
      '/guide/item/emergency-contacts',
      '/guide/item/counseling',
      '/guide/item/hospital-guide',
    ]) {
      expect(allUrls.contains(route), isTrue, reason: route);
    }
    // arc-issue is the first-issue guide, not a replacement guide.
    expect(allUrls.any((u) => u.contains('arc-issue')), isFalse);
    // Bottom block, in the agreed order.
    expect(
      item.links.map((l) => l.url).toList(),
      const [
        'https://minwon24.police.go.kr/',
        'https://www.hikorea.go.kr/info/InfoFrnReportLostPageR.pt',
        '/guide/item/emergency-contacts',
        '/guide/item/counseling',
        '/guide/item/hospital-guide',
      ],
    );

    // Every renderable string of this item, both languages.
    final dump = [
      item.titleKo, item.titleEn, item.summaryKo, item.summaryEn,
      item.overviewKo, item.overviewEn,
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

    // No amount anywhere — the ARC replacement fee could not be confirmed.
    expect(RegExp(r'[0-9][0-9,]*\s*원').hasMatch(dump), isFalse);
    expect(dump.contains('₩'), isFalse);
    expect(dump.contains('KRW'), isFalse);

    // Retired or unverified services, and the desks the brief excluded.
    for (final banned in const [
      'LOST112',
      'lost112',
      '182',
      '02-2011-0700',
      '여신금융협회',
      '일괄',
      'Migrant Rights',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'excluded: $banned');
    }

    // No claim about which languages 112 or 119 can work in — the site's own
    // multilingual screen is the only language fact stated, and it is about
    // 경찰민원24, not about a call.
    for (final banned in const [
      '통역',
      'interpreter',
      'interpretation',
      '영어',
      'English',
      '중국어',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'language claim: $banned');
    }

    // No named organisation of any kind.
    for (final banned in const [
      '사하경찰서',
      '서부경찰서',
      '동아대학교병원',
      'SKT',
      'KT',
      'LG U+',
      '국민은행',
      '신한',
      '삼성',
      '현대',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'named org: $banned');
    }

    // No legal judgement, and no driver-only accident procedure.
    for (final banned in const [
      '과실',
      '합의',
      '보상',
      '책임 비율',
      'at fault',
      'liable',
      'settlement',
      'compensation',
      '삼각대',
      '갓길',
      'warning triangle',
      'hard shoulder',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'judgement: $banned');
    }

    // Nothing pressures a victim: no duty to report, no duty to keep evidence.
    for (final banned in const [
      '반드시',
      '증거',
      'you must',
      'be sure to',
      'make sure you report',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'pressure: $banned');
    }
    // …and the page says so out loud.
    // Reporting is described as situation-dependent, never as the victim's
    // burden and never as a blanket rule about every case.
    expect(dump, contains('신고 여부와 이후 절차는 사건의 상황에 따라 달라질 수 있습니다'));
    expect(dump, contains('피해자의 선택을 평가하지 않습니다'));
    expect(dump, contains('Whether and how to report can depend on the '
        'situation'));
    expect(dump, contains('does not judge the choices a victim makes'));
    for (final banned in const [
      '신고할지 여부는 본인이 정하는 일',
      'Whether to report is yours to decide',
      'does not judge what you should have done',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'superseded: $banned');
    }
    expect(dump, contains('법적인 판단을 하지 않습니다'));
    expect(dump, contains('makes no legal judgement'));

    // ── 분실 vs 도난, the distinction this page exists for ──────────────────
    final lost = item.sections[0];
    final theft = item.sections[1];
    expect(lost.noticeKo, contains('도난은 제외'));
    expect(lost.noticeKo, contains('112'));
    expect(lost.noticeEn, contains('theft is excluded'));
    expect(lost.bodyKo, contains('단순 분실'));
    expect(lost.bodyEn, contains('simply lost'));
    expect(lost.notes.single.linesKo, contains('신고에 수수료는 없습니다'));
    // The management number checks a report's status — it is not the
    // found-item search key, which the earlier wording implied.
    final numberKo =
        lost.notes.single.linesKo.singleWhere((l) => l.contains('관리번호'));
    expect(numberKo, contains('경찰관서에서 접수한 신고'));
    expect(numberKo, contains('신고 상태를 다시 확인'));
    final numberEn = lost.notes.single.linesEn
        .singleWhere((l) => l.contains('management number'));
    expect(numberEn, contains('filed at a police office'));
    expect(numberEn, contains('check its status online'));
    for (final banned in const [
      '관리번호로 습득물을 검색',
      'is what you search found items with',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'superseded: $banned');
    }
    // The found-item search itself still exists, stated in the body.
    expect(lost.bodyKo, contains('습득물을 검색'));
    expect(lost.bodyEn, contains('search what has been handed in'));
    expect(theft.bodyKo, contains('분실물 신고는 도난을 처리하는 경로가 아니'));
    expect(theft.bodyEn, contains('not used for theft'));
    expect(theft.bodyEn, contains('Even after the immediate danger has passed'));
    expect(theft.bodyEn, contains('contact the police instead'));
    for (final banned in const [
      'report it on 112',
      'the police are where it goes',
      'not the route for theft',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'superseded: $banned');
    }
    // Never send anyone after the person.
    expect(theft.noticeKo, contains('직접 쫓아가거나'));
    expect(theft.noticeEn, contains('Do not follow or confront'));

    // ── Naming: 경찰민원24 has no confirmed official English name ───────────
    // It is introduced once, descriptively, and referred to by its Korean
    // name after that. "Police Minwon 24" must never appear as if official.
    expect(dump.contains('Police Minwon 24'), isFalse);
    expect(dump.contains('Police Minwon24'), isFalse);
    expect(item.overviewEn,
        contains('경찰민원24, the national police civil-services portal'));
    expect(lost.bodyEn, contains('is handled by 경찰민원24.'));
    expect(lost.links.single.labelEn, '경찰민원24 — Lost-property reports');
    expect(item.links.first.labelEn, '경찰민원24 — Police civil-services portal');
    // Korean police-office types are explained rather than left untranslated.
    expect(
      lost.bodyEn,
      contains('a police station, district police unit (지구대), or police '
          'box (파출소)'),
    );

    // ── Residence Card ─────────────────────────────────────────────────────
    final ids = item.sections[2];
    final arc = ids.notes.first;
    expect(arc.titleEn, 'Residence Card (ARC)');
    expect(arc.linesKo.any((l) => l.contains('효력이 정지되거나 회복되는 것은 아닙니다')),
        isTrue);
    // The English must not promise that reporting makes misuse impossible.
    expect(
        arc.linesEn.any((l) =>
            l.contains('records that the card was lost to help prevent '
                'misuse') &&
            l.contains('does not, by itself, suspend or restore the card')),
        isTrue);
    for (final banned in const [
      'so it cannot be misused',
      'neither suspends nor restores',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'superseded: $banned');
    }
    expect(arc.linesKo.any((l) => l.contains('24시간 이내에는 철회')), isTrue);
    expect(arc.linesKo.any((l) => l.contains('14일 이내')), isTrue);
    expect(arc.linesEn.any((l) => l.contains('within 14 days')), isTrue);
    expect(arc.linesKo.any((l) => l.contains('하이코리아 또는 1345')), isTrue);
    expect(dump.contains('Residence Card (ARC)'), isTrue);
    expect(dump.toLowerCase().contains('alien registration'), isFalse);

    // ── Passport: nationality-dependent, never generalised ──────────────────
    final passport = ids.notes[1];
    expect(passport.linesKo.first, contains('국적마다 다릅니다'));
    expect(passport.linesEn.first, contains('depends on your nationality'));
    expect(passport.linesKo.any((l) => l.contains('주한 대사관 또는 영사관')), isTrue);
    expect(passport.linesKo.any((l) => l.contains('15일 이내')), isTrue);
    expect(passport.linesEn.any((l) => l.contains('within 15 days')), isTrue);
    // Korean police reporting is never stated as an obligation for a passport.
    for (final banned in const [
      '경찰에 분실신고를 해야',
      '경찰 신고가 필요합니다',
      'you must report it to the police',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'passport duty: $banned');
    }

    // 1345 only ever appears in the Residence Card / immigration context.
    final sectionsWithout1345 = [
      ...item.topSections,
      item.sections[0],
      item.sections[1],
      item.sections[3],
      item.sections[4],
    ];
    for (final s in sectionsWithout1345) {
      final text = [
        s.titleKo, s.titleEn, s.bodyKo, s.bodyEn, s.noticeKo, s.noticeEn,
        s.footnoteKo, s.footnoteEn,
        for (final l in s.links) '${l.labelKo}${l.labelEn}${l.url}',
        for (final n in s.notes) ...[n.titleKo, ...n.linesKo, ...n.linesEn],
      ].whereType<String>().join('\n');
      expect(text.contains('1345'), isFalse, reason: '1345 in ${s.titleEn}');
    }
    expect(item.overviewKo!.contains('1345'), isFalse);
    expect(item.tipsKo.join().contains('1345'), isFalse);

    // ── Accident: minimum response only ────────────────────────────────────
    final accident = item.sections[3];
    expect(accident.bodyKo, contains('119'));
    expect(accident.bodyKo, contains('112'));
    expect(accident.bodyKo, contains('보험사'));
    expect(accident.bodyEn, contains('your own insurer'));
    expect(accident.links.single.url, '/guide/item/hospital-guide');

    // ── Afterwards: counseling owns the detail, this page just points ───────
    final after = item.sections[4];
    expect(after.links.single.url, '/guide/item/counseling');
    // The human-rights centre's phone, room and role stay in the counseling
    // guide. It may be *named* once, in the link description that says what
    // that guide contains — but none of its details are repeated here.
    for (final banned in const [
      '051-200-5711',
      '503호',
      '대학본부',
      '상담과 신고를 접수',
      'human rights centre',
    ]) {
      expect(dump.contains(banned), isFalse, reason: 'duplicated: $banned');
    }
    expect(RegExp('인권센터').allMatches(dump).length, 1);
    expect(after.links.single.descriptionKo, contains('인권센터'));
    // The section body itself does not name it.
    expect(after.bodyKo!.contains('인권센터'), isFalse);
    expect(after.noticeKo, contains('112'));

    // Tips carry the phone/card advice, and no company is named.
    expect(item.tipsKo.length, 5);
    expect(item.tipsEn.length, 5);
    expect(item.tipsKo.first, contains('통신사'));
    expect(item.tipsKo[1], contains('카드사'));
    // The wallet tip splits the three actions explicitly.
    expect(item.tipsKo[2], contains('출입국기관'));
    expect(item.tipsKo[2], contains('해당 카드사'));
    expect(item.tipsKo[2], contains('가입한 통신사'));
    expect(item.tipsEn[2], contains('report each loss separately to '
        'immigration and the relevant card company'));
    expect(item.tipsEn[2], contains('contact your mobile carrier separately'));
    expect(dump.contains('phone details'), isFalse);
  });

  testWidgets('Guide detail: incident response renders its sections in order',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    expect(find.text('Loss, theft, accidents'), findsOneWidget);

    await tester.tap(find.text('Incident Response'));
    await tester.pumpAndSettle();
    // Published now — the placeholder must be gone.
    expect(find.textContaining('coming soon', findRichText: true), findsNothing);

    const titles = [
      'Overview',
      'If you are in immediate danger',
      'If you lost an item',
      'If you were affected by theft or a crime',
      'If you lost your passport or Residence Card',
      'If an accident happens',
      'If you need support afterwards',
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

    // Safety rows sit at the top, above the procedure.
    expect(find.text('Call 112'), findsOneWidget);
    expect(find.text('Call 119'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Call 119')).dy,
      lessThan(tester.getTopLeft(find.text('If you lost an item')).dy),
    );

    // The lost-vs-theft distinction is on screen in English.
    expect(
      find.textContaining('theft is excluded from it'),
      findsOneWidget,
    );
    expect(find.textContaining('not used for theft'), findsOneWidget);
    expect(find.textContaining('not the route for theft'), findsNothing);
    expect(find.textContaining('Do not follow or confront anyone'),
        findsOneWidget);

    // Residence Card facts, stated without a fee.
    expect(
      find.textContaining('does not, by itself, suspend or restore the card'),
      findsOneWidget,
    );
    expect(find.textContaining('so it cannot be misused'), findsNothing);
    // The English never presents a name for 경찰민원24 that is not official.
    expect(find.textContaining('Police Minwon 24'), findsNothing);
    expect(
      find.textContaining('the national police civil-services portal'),
      findsOneWidget,
    );
    expect(
      find.textContaining('district police unit (지구대)'),
      findsOneWidget,
    );
    expect(find.textContaining('within 24 hours'), findsOneWidget);
    expect(find.textContaining('within 14 days'), findsOneWidget);
    expect(find.textContaining('within 15 days'), findsOneWidget);
    expect(find.textContaining('depends on your nationality'), findsOneWidget);

    // Rows that appear both in their own section and in the bottom block.
    expect(find.text('HiKorea — report a lost Residence Card'),
        findsNWidgets(2));
    expect(find.text('Guide — Emergency Contacts'), findsNWidgets(2));
    expect(find.text('Guide — Counseling'), findsNWidgets(2));
    expect(find.text('Guide — Visiting a Hospital'), findsNWidgets(2));
    // …and the two police-portal rows, each appearing once.
    expect(find.text('경찰민원24 — Lost-property reports'), findsOneWidget);
    expect(
      find.text('경찰민원24 — Police civil-services portal'),
      findsOneWidget,
    );
    expect(find.text('Call 1345 for immigration enquiries'), findsOneWidget);

    // No related-location card at all.
    expect(find.text('Student Union Building (Q)'), findsNothing);
    expect(find.text('General Lecture Building (BA-BD)'), findsNothing);
  });

  testWidgets('Guide detail: incident response in-app links route in-app',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    Future<void> openGuide() async {
      await _openGuideHub(tester);
      await tester.tap(find.text('Emergency & Help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Incident Response'));
      await tester.pumpAndSettle();
    }

    // `pumpAndSettle` returns while the mock repo's delayed load is still
    // pending, so each destination needs that time before it is asserted on.
    // `_LinkRow` uses `context.go`, which replaces the route rather than
    // pushing one, so re-enter from the tab instead of popping.
    await openGuide();
    await tester.tap(find.text('Guide — Counseling').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Student counseling centre'), findsOneWidget);

    await openGuide();
    await tester.tap(find.text('Guide — Visiting a Hospital').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('At the reception desk'), findsOneWidget);

    await openGuide();
    await tester.tap(find.text('Guide — Emergency Contacts').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('In an emergency'), findsOneWidget);

    // Drain the destination's related-location lookup so no timer outlives
    // the widget tree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('Guide detail: incident response fits a 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incident Response'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scrolling only — no call row is ever tapped.
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
    expect(find.text('Emergency & Help'), findsOneWidget);
  });

  testWidgets('Guide detail: incident response renders in Korean',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app(locale: 'ko'));
    await tester.pumpAndSettle();

    await _openGuideHub(tester, ko: true);
    await tester.tap(find.text('긴급·도움'));
    await tester.pumpAndSettle();
    expect(find.text('분실·도난·사고 시 대응'), findsOneWidget);

    await tester.tap(find.text('사건·사고 대응'));
    await tester.pumpAndSettle();

    for (final title in const [
      '지금 즉시 위험하다면',
      '물건을 잃어버렸다면',
      '도난이나 범죄 피해를 입었다면',
      '여권 · 외국인등록증을 잃어버렸다면',
      '사고가 났다면',
      '사건 이후 도움이 필요하다면',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.text('112 전화하기'), findsOneWidget);
    expect(find.text('119 전화하기'), findsOneWidget);
    expect(find.text('1345 출입국 문의'), findsOneWidget);
    // The distinction, in Korean.
    expect(find.textContaining('도난은 제외됩니다'), findsOneWidget);
    expect(find.textContaining('단순 분실'), findsWidgets);
    expect(find.textContaining('신고에 수수료는 없습니다'), findsOneWidget);
    expect(find.textContaining('국적마다 다릅니다'), findsOneWidget);
    expect(find.textContaining('14일 이내'), findsOneWidget);
    expect(find.textContaining('15일 이내'), findsOneWidget);
    // Nothing pressures, judges or names a company.
    expect(find.textContaining('반드시'), findsNothing);
    expect(find.textContaining('증거'), findsNothing);
    expect(find.textContaining('과실'), findsNothing);
    expect(find.textContaining('LOST112'), findsNothing);
    expect(
      find.textContaining('신고 여부와 이후 절차는 사건의 상황에 따라 달라질 수 있습니다'),
      findsOneWidget,
    );
    expect(find.textContaining('피해자의 선택을 평가하지 않습니다'), findsOneWidget);
    expect(find.textContaining('신고할지 여부는 본인이 정하는 일'), findsNothing);
    // The management number is described as a status check, not a search key.
    expect(find.textContaining('신고 상태를 다시 확인'), findsOneWidget);
    expect(find.textContaining('관리번호로 습득물을 검색'), findsNothing);
    // The wallet tip separates the three actions.
    expect(find.textContaining('출입국기관과 해당 카드사에 각각 별도로'), findsOneWidget);
  });

  testWidgets('Favorite toggle works from the incident response guide',
      (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incident Response'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Incident Response'), findsOneWidget);
  });

  // Every real guide is written now, so no production item can exercise the
  // coming-soon path any more. The path itself still ships — a Firestore
  // document with no body renders it — so it is covered here with a synthetic
  // item served by a test-only repository. Nothing about this fixture exists
  // in mock_data or in the seed.
  testWidgets('Guide detail: an item with no content shows the placeholder',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          guideRepositoryProvider.overrideWithValue(_StubGuideRepository()),
        ],
        child: const CampusOnApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Emergency & Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Coming Soon'));
    await tester.pumpAndSettle();

    // No sectioned content → the standard coming-soon copy is shown.
    expect(
      find.textContaining('coming soon', findRichText: true),
      findsWidgets,
    );
  });

  test('hasNoContent drives the placeholder, and no real guide hits it', () {
    // The fixture the widget test above renders: title and summary only.
    expect(_StubGuideRepository.stub.hasNoContent, isTrue);
    expect(_StubGuideRepository.stub.isComingSoon, isTrue);

    // Anything with a body is not empty, whatever its status says.
    const withOverview = AdminGuideItem(
      id: 'x',
      categoryId: GuideCategory.emergency,
      titleKo: 'ㄱ',
      titleEn: 'x',
      summaryKo: 'ㄱ',
      summaryEn: 'x',
      overviewKo: '내용',
    );
    expect(withOverview.hasNoContent, isFalse);

    // …and every shipped guide is written and published: 18 / 18.
    expect(MockData.guideItems.length, 18);
    for (final g in MockData.guideItems) {
      expect(g.hasNoContent, isFalse, reason: g.id);
      expect(g.status, GuideStatus.published, reason: g.id);
      expect(g.isComingSoon, isFalse, reason: g.id);
    }
  });

  testWidgets('Favorite toggle from guide detail persists to Favorites (S10)',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _openGuideHub(tester);
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Residence Card (ARC)'));
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

    expect(find.text('Residence Card (ARC)'), findsOneWidget);
  });

  // ── 입국·체류 accuracy guards ────────────────────────────────────────────
  // These three guides restate published rules, so their wording IS the
  // contract: the 90-day duty only binds stays over 90 days, the registration
  // fee is the 2025 one, an extension cannot be filed from abroad (but can be
  // filed by a representative otherwise), and part-time work needs permission
  // first. Each assertion below is a fact a future edit must not quietly undo.

  test('ARC issue: conditional 90-day duty, 2025 fee, no invented timeline',
      () {
    final item = MockData.guideItems.firstWhere((g) => g.id == 'arc-issue');
    expect(item.status, GuideStatus.published);
    expect(item.categoryId, GuideCategory.immigration);

    // 법무부 renamed the card's English designation; "Alien" is gone from every
    // user-facing string on this page.
    expect(item.titleKo, '외국인등록증(ARC) 발급');
    expect(item.titleEn, 'Residence Card (ARC)');
    expect(_guideTextEn(item), isNot(contains('Alien Registration Card')));

    // The duty is conditional: "over 90 days" must travel with "within 90
    // days", in both languages, or the page reads as binding everyone.
    final ko = _guideTextKo(item);
    final en = _guideTextEn(item);
    expect(ko, contains('90일을 초과해'));
    expect(ko, contains('90일 이내'));
    expect(en, contains('more than 90 days'));
    expect(en, contains('within 90 days of entry'));

    // Core documents, per HiKorea's 외국인등록 제출서류 list. The form is named by its
    // statutory title, not as a generic "신청서".
    expect(item.checklistKo, contains('통합신청서(신고서)'));
    expect(item.checklistEn, contains('Application Form (Report Form)'));
    expect(item.checklistKo, contains('여권'));
    expect(item.checklistEn, contains('Passport'));
    // Every condition of the 표준 사진규격: age, size, background, color, pose.
    final photoKo = item.checklistKo.singleWhere((s) => s.contains('사진'));
    for (final spec in const [
      '6개월 이내 촬영한',
      '흰색 배경',
      '3.5×4.5cm',
      '컬러',
      '정면사진',
    ]) {
      expect(photoKo, contains(spec), reason: spec);
    }
    final photoEn = item.checklistEn.singleWhere((s) => s.contains('photo'));
    for (final spec in const [
      'within the last 6 months',
      'white background',
      '3.5×4.5cm',
      'color',
      'front-facing',
    ]) {
      expect(photoEn, contains(spec), reason: spec);
    }
    // 재학증명서 has to be the one issued after entry; 연구생증명서 is named as the
    // research-course variant, not as a second requirement.
    expect(
      item.checklistKo.any(
          (s) => s.contains('입국 후 발급된 재학증명서') && s.contains('연구생증명서')),
      isTrue,
    );
    expect(item.checklistKo.any((s) => s.contains('체류지 입증서류')), isTrue);
    expect(
      item.checklistEn.any((s) => s.contains('Proof of where you live in Korea')),
      isTrue,
    );

    // 표준입학허가서 is not a general 외국인등록 document — it must not be back in the
    // core list.
    expect(item.checklistKo, isNot(contains('재학증명서 또는 표준입학허가서')));
    expect(item.checklistKo.any((s) => s.contains('표준입학허가서')), isFalse);

    // Fee: 35,000원 since 2025-01-01, with the effective date stated.
    expect(item.checklistKo.any((s) => s.contains('35,000원')), isTrue);
    expect(item.checklistEn.any((s) => s.contains('KRW 35,000')), isTrue);
    expect(item.checklistNoteKo, contains('2025년 1월 1일'));
    expect(item.checklistNoteEn, contains('1 January 2025'));
    // 1345 is a paid call; if the page tells you to ring it, it says so — in
    // both languages, everywhere it is named.
    for (final line in ko.split('\n').where((l) => l.contains('1345'))) {
      expect(line, contains('1345(유료)'), reason: line);
    }
    for (final line in en.split('\n').where((l) => l.contains('1345'))) {
      expect(line, contains('1345 (paid call)'), reason: line);
    }
    for (final stale in const ['30,000', '3만원', '3만 원']) {
      expect(ko, isNot(contains(stale)), reason: stale);
      expect(en, isNot(contains(stale)), reason: stale);
    }

    // Tuberculosis paperwork is for whoever it applies to — never a blanket
    // student requirement.
    // …and it is the narrow document (결핵검진 확인서), never a broad "health check"
    // bucket that would read as a general student requirement.
    expect(item.checklistKo.where((s) => s.contains('결핵')), isEmpty);
    final tbKo = item.checklistOptionalKo.singleWhere((s) => s.contains('결핵'));
    expect(tbKo, '결핵검진 확인서(공식 안내상 해당자만)');
    expect(tbKo, contains('해당자만'));
    final tbEn = item.checklistOptionalEn
        .singleWhere((s) => s.contains('Tuberculosis'));
    expect(
      tbEn,
      'Tuberculosis examination confirmation (only if it applies under the '
          'current official guidance)',
    );
    expect(tbEn, contains('only if it applies'));
    for (final broad in const ['건강진단', '건강검진']) {
      expect(ko, isNot(contains(broad)), reason: broad);
    }
    for (final broad in const ['health-check', 'health check']) {
      expect(en, isNot(contains(broad)), reason: broad);
    }
    // Whether it applies is something to confirm, and the note says where.
    expect(item.checklistNoteKo, contains('관할 출입국·외국인관서 또는 공식 안내에서 확인'));
    expect(item.checklistNoteEn,
        contains('whether this applies to you'));

    // No processing time is published as one national figure, so the page
    // states none — neither as a duration chip nor as a step.
    expect(item.durationKo, isNull);
    expect(item.durationEn, isNull);
    for (final invented in const [
      '2–3주',
      '2-3주',
      '2~3주',
      '2–3 weeks',
      '2-3 weeks',
    ]) {
      expect(ko, isNot(contains(invented)), reason: invented);
      expect(en, isNot(contains(invented)), reason: invented);
    }

    // The application is filed at a 지방출입국·외국인관서, not on campus: no map card,
    // and the 국제교류과 link says what that office actually does.
    expect(item.relatedFacilityIds, isEmpty);
    // CAT_SEQ=180 is HiKorea's 변경신고 page, not the registration one, and
    // CAT_SEQ=176 still shows an image quoting the old 30,000원 fee — neither
    // belongs on this page.
    for (final l in item.links) {
      expect(l.url, isNot(contains('CAT_SEQ=180')), reason: l.url);
      expect(l.url, isNot(contains('CAT_SEQ=176')), reason: l.url);
      expect(l.url, isNot(contains('CAT_SEQ=177')), reason: l.url);
    }
    // The plain page URL: the site honours no `tab` parameter, and the
    // registration block is the first thing on the page.
    final sik = item.links.singleWhere(
        (l) => l.url.startsWith('https://www.studyinkorea.go.kr'));
    expect(
      sik.url,
      'https://www.studyinkorea.go.kr/eng/life/residenceAndStayInfo.do',
    );
    expect(sik.url, isNot(contains('?tab=foreigner-registration')));
    expect(sik.url, isNot(contains('#foreigner-registration')));
    expect(sik.labelKo, 'Study in Korea 외국인등록 안내');
    expect(sik.labelEn, 'Study in Korea — Foreigner Registration');
    expect(sik.descriptionKo, '등록 대상 · 신청 시기 · 준비서류');
    expect(sik.descriptionEn,
        'Who must register, when to apply, and what to prepare');
    // The fee figure above has to be traceable to the notice it came from.
    expect(
      item.links.any((l) =>
          l.url == 'https://www.moj.go.kr/bbs/immigration/47/590299/artclView.do'),
      isTrue,
      reason: 'Ministry of Justice fee notice link missing',
    );
    // The reservation link points at the 방문예약 guidance page, not the portal
    // front door.
    final resv = item.links
        .singleWhere((l) => l.url.startsWith('https://www.hikorea.go.kr'));
    expect(resv.url, 'https://www.hikorea.go.kr/resv/ResvIntroR.pt');
    final oia =
        item.links.firstWhere((l) => l.url == '/guide/item/oia-visit');
    expect(oia.descriptionKo, '학교 서류와 유학생 행정 절차를 문의할 때');
    expect(
      oia.descriptionEn,
      'For questions about university documents and '
          'international-student administration',
    );
    for (final claim in const [
      '국제교류과에서 신청',
      '국제교류과에 신청',
      '국제교류과에서 외국인등록',
    ]) {
      expect(ko, isNot(contains(claim)), reason: claim);
    }
  });

  test('Stay extension: filing window, being in Korea, and the 15-day move',
      () {
    final item =
        MockData.guideItems.firstWhere((g) => g.id == 'stay-extension');
    expect(item.status, GuideStatus.published);

    final ko = _guideTextKo(item);
    final en = _guideTextEn(item);

    // Kept: the 4-months-before window and the fine after expiry.
    expect(ko, contains('만료 4개월 전부터 만료일까지'));
    expect(en, contains('four months before'));
    expect(ko, contains('범칙금'));

    // Added: the applicant has to be in Korea on the filing day.
    expect(ko, contains('신청 당일에는 본인이 한국에 체류 중이어야 합니다'));
    expect(en, contains('You must be in Korea on the day the application is filed'));

    // …and the reason it matters: no online or proxy filing FROM ABROAD. Every
    // mention of 대리/representative has to carry that condition, so the page
    // never reads as "a representative can never file".
    expect(ko, contains('해외에'));
    expect(en, contains('while the applicant is overseas'));
    for (final line in ko.split('\n').where((l) => l.contains('대리'))) {
      expect(line, contains('해외'), reason: line);
    }
    for (final line
        in en.split('\n').where((l) => l.contains('representative'))) {
      expect(line, contains('overseas'), reason: line);
    }

    // Change of address: an obligation with a deadline, not a "check whether".
    final moved = item.sections
        .expand((s) => s.notes)
        .firstWhere((n) => n.titleKo.contains('체류지가 바뀌었다면'));
    expect(moved.titleKo, contains('15일 이내'));
    expect(moved.titleEn, contains('within 15 days'));
    expect(moved.linesKo.first, contains('전입한 날부터 15일 이내'));
    expect(moved.linesEn.first, contains('within 15 days of moving'));
    expect(moved.linesKo.first, contains('해야 합니다'));
    expect(moved.linesEn.first, contains('must be reported'));
    // Both places you can report it, in both languages.
    expect(moved.linesKo[1], contains('출입국·외국인관서'));
    expect(moved.linesKo[1], contains('읍·면·동'));
    expect(moved.linesEn[1], contains('immigration office'));
    expect(moved.linesEn[1], contains('local administrative office'));
    // KO and EN say the same number of things.
    expect(moved.linesEn, hasLength(moved.linesKo.length));
    expect(ko, isNot(contains('체류지 변경 신고가 필요한지 확인')));
  });

  test('Visa types: official D-2 name, the 90-day rule, and work permission',
      () {
    final item = MockData.guideItems.firstWhere((g) => g.id == 'visa-types');
    expect(item.status, GuideStatus.published);

    final ko = _guideTextKo(item);
    final en = _guideTextEn(item);

    // Study in Korea's own labels — "Study Abroad (D-2)" is not one of them.
    expect(en, contains('Study (D-2)'));
    expect(en, contains('General Training (D-4)'));
    expect(en, isNot(contains('Study Abroad (D-2)')));
    expect(en, isNot(contains('Alien Registration Card')));

    // The sub-type breakdown this page is built around stays intact.
    for (final sub in const [
      'D-2-2',
      'D-2-3',
      'D-2-4',
      'D-2-6',
      'D-4-1',
      'D-4-2',
    ]) {
      expect(ko, contains(sub), reason: sub);
      expect(en, contains(sub), reason: sub);
    }

    // Registration: the same conditional rule the ARC guide states.
    expect(ko, contains('90일을 초과해'));
    expect(ko, contains('90일 이내'));
    expect(en, contains('more than 90 days'));
    expect(en, contains('within 90 days of entry'));
    final arcLink =
        item.links.firstWhere((l) => l.url == '/guide/item/arc-issue');
    expect(arcLink.labelKo, '가이드 — 외국인등록증(ARC) 발급');
    expect(arcLink.labelEn, 'Guide — Residence Card (ARC)');

    // Part-time work: not automatic, permission first, eligibility conditional
    // — and no bare "D-2/D-4 students can work" claim, and no hour or
    // proficiency figures this guide is not the source for.
    final work = item.sections
        .expand((s) => s.notes)
        .firstWhere((n) => n.titleKo.contains('아르바이트'));
    expect(work.linesKo.first, contains('자동으로 허용되는 것은 아닙니다'));
    expect(work.linesEn.first, contains('does not automatically allow'));
    expect(
      work.linesKo.any((l) => l.contains('일을 시작하기 전에 허가를 받아야')),
      isTrue,
    );
    expect(
      work.linesEn.any((l) => l.contains('need permission before starting')),
      isTrue,
    );
    expect(
      work.linesKo.any((l) => l.contains('여러 조건에 따라 달라질 수 있습니다')),
      isTrue,
    );
    expect(
      work.linesEn.any((l) => l.contains('Eligibility and permitted hours can depend')),
      isTrue,
    );
    expect(work.linesEn, hasLength(work.linesKo.length));
    expect(RegExp(r'\d+\s*시간').hasMatch(ko), isFalse, reason: 'hour figure');
    expect(RegExp(r'\d+\s*hours').hasMatch(en), isFalse, reason: 'hour figure');
    expect(ko, isNot(contains('TOPIK')));

    // Visa documents. 사증발급신청서 is the form filed at the 재외공관 — a different
    // form from the ARC guide's 통합신청서(신고서), which is filed inside Korea.
    expect(item.checklistKo, contains('사증발급신청서'));
    expect(item.checklistEn, contains('Visa application form'));
    expect(item.checklistKo, isNot(contains('통합신청서(신고서)')));
    expect(item.checklistEn, isNot(contains('Application Form (Report Form)')));

    // …the photo spec, and the school-issued institution certificate — in the
    // core list, labelled as something the school provides.
    expect(item.checklistKo, isNot(contains('증명사진')));
    expect(item.checklistKo, contains('6개월 이내 촬영한 증명사진'));
    expect(
      item.checklistEn,
      contains('One passport-size photo taken within the last 6 months'),
    );
    final institutionKo = item.checklistKo
        .singleWhere((s) => s.contains('사업자등록증 또는 고유번호증 사본'));
    expect(institutionKo, contains('학교에서 제공하는 서류'));
    final institutionEn = item.checklistEn.singleWhere(
        (s) => s.contains('business registration') && s.contains('registration-number'));
    expect(institutionEn, contains('provided by the school'));
    // Kept: documents differ by sub-type, nationality and mission.
    expect(item.checklistNoteKo, contains('재외공관'));

    // The reading time read as the visa's processing time, so it is gone.
    expect(item.durationKo, isNull);
    expect(item.durationEn, isNull);
  });

  test('Guide catalogue: 18 items, all published, reterm scoped to three', () {
    expect(MockData.guideItems, hasLength(18));
    expect(
      MockData.guideItems.where((g) => g.status == GuideStatus.comingSoon),
      isEmpty,
    );
    expect(
      MockData.guideItems.where((g) => g.status == GuideStatus.published),
      hasLength(18),
    );
    // The Residence Card reterm covers the immigration trio only; the other
    // guides are corrected in their own category reviews.
    for (final id in const ['arc-issue', 'stay-extension', 'visa-types']) {
      final g = MockData.guideItems.firstWhere((g) => g.id == id);
      expect(_guideTextEn(g), isNot(contains('Alien Registration Card')),
          reason: id);
      expect(_guideTextEn(g), isNot(contains('Study Abroad (D-2)')),
          reason: id);
    }
  });
}

/// Every Korean user-facing string an item carries, newline-joined — the
/// immigration guides restate published rules, so their assertions are about
/// the text a reader actually sees rather than any one field.
String _guideTextKo(AdminGuideItem g) => _guideText(g, ko: true);

/// English counterpart of [_guideTextKo].
String _guideTextEn(AdminGuideItem g) => _guideText(g, ko: false);

String _guideText(AdminGuideItem g, {required bool ko}) => <String?>[
      ko ? g.titleKo : g.titleEn,
      ko ? g.detailTitleKo : g.detailTitleEn,
      ko ? g.summaryKo : g.summaryEn,
      ko ? g.overviewKo : g.overviewEn,
      ko ? g.checklistTitleKo : g.checklistTitleEn,
      ...(ko ? g.checklistKo : g.checklistEn),
      ko ? g.checklistOptionalTitleKo : g.checklistOptionalTitleEn,
      ...(ko ? g.checklistOptionalKo : g.checklistOptionalEn),
      ko ? g.checklistNoteKo : g.checklistNoteEn,
      ...(ko ? g.stepsKo : g.stepsEn),
      ...(ko ? g.tipsKo : g.tipsEn),
      for (final p in g.phrases) ko ? p.ko : p.en,
      for (final l in g.links) ...[
        ko ? l.labelKo : l.labelEn,
        ko ? l.descriptionKo : l.descriptionEn,
      ],
      for (final s in [...g.topSections, ...g.sections]) ...[
        ko ? s.titleKo : s.titleEn,
        ko ? s.bodyKo : s.bodyEn,
        ...(ko ? s.stepsKo : s.stepsEn),
        for (final l in s.links) ...[
          ko ? l.labelKo : l.labelEn,
          ko ? l.descriptionKo : l.descriptionEn,
        ],
        for (final n in s.notes) ...[
          ko ? n.titleKo : n.titleEn,
          ...(ko ? n.linesKo : n.linesEn),
        ],
        ko ? s.noticeKo : s.noticeEn,
        ko ? s.footnoteKo : s.footnoteEn,
      ],
    ].whereType<String>().join('\n');

/// Test-only repository serving a single content-free guide, so the
/// coming-soon render path stays covered now that every shipped guide is
/// written. This fixture lives in the test file on purpose: it is never in
/// `MockData`, and never in the Firestore seed.
class _StubGuideRepository implements GuideRepository {
  static const stub = AdminGuideItem(
    id: 'test-coming-soon',
    categoryId: GuideCategory.emergency,
    titleKo: '테스트 준비 중 항목',
    titleEn: 'Test Coming Soon',
    summaryKo: '테스트 픽스처',
    summaryEn: 'Test fixture',
  );

  @override
  Future<List<AdminGuideItem>> getAllItems() async => const [stub];

  @override
  Future<List<AdminGuideItem>> getByCategory(GuideCategory category) async =>
      category == GuideCategory.emergency ? const [stub] : const [];

  @override
  Future<AdminGuideItem?> getById(String id) async =>
      id == stub.id ? stub : null;

  @override
  Future<List<AdminGuideItem>> search(String query) async => const [];
}
