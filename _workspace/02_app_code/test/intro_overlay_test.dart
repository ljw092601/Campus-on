import 'package:campus_on/app.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// M-7: while the intro plays, taps must not leak to the home UI underneath,
/// tapping the intro must skip it, and once it is gone the app is tappable.
/// [IntroOverlay] carries no video dependency, so it is exercised directly
/// with a plain button standing in for the app.

const _skipHintEn = 'Tap to skip';

/// Hosts [IntroOverlay] the way [BrandSplashOverlay] does: [dismissed] is
/// owned by the parent and flipped by `onSkip`, mirroring the real wiring.
class _Host extends StatefulWidget {
  const _Host({this.initiallyDismissed = false, this.skippable = true});

  final bool initiallyDismissed;

  /// False leaves `onSkip` unset, so taps are swallowed without dismissing.
  final bool skippable;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool dismissed = widget.initiallyDismissed;
  int belowTaps = 0;
  int skips = 0;
  int hiddenCalls = 0;

  void dismiss() => setState(() => dismissed = true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IntroOverlay(
        dismissed: dismissed,
        onSkip: !widget.skippable
            ? null
            : () {
                skips++;
                dismiss();
              },
        onHidden: () => hiddenCalls++,
        child: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => belowTaps++,
              child: const Text('Below'),
            ),
          ),
        ),
      ),
    );
  }
}

_HostState _host(WidgetTester tester) => tester.state(find.byType(_Host));

Future<void> _tapBelow(WidgetTester tester) async {
  // The button is covered while the intro shows, so silence the
  // "would not hit test" warning; the assertion is on the counter.
  await tester.tap(find.text('Below'), warnIfMissed: false);
  await tester.pump();
}

void main() {
  testWidgets('intro swallows taps meant for the app underneath',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());

    expect(find.text(_skipHintEn), findsOneWidget);
    // Accessible as a single button labelled with the skip hint.
    expect(find.bySemanticsLabel(_skipHintEn), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_skipHintEn)),
      matchesSemantics(
        label: _skipHintEn,
        isButton: true,
        hasTapAction: true,
      ),
    );
    // The home UI is hidden from assistive tech while the intro is up.
    expect(find.bySemanticsLabel('Below'), findsNothing);

    // A tap on the covered button is taken by the overlay (as a skip), never
    // by the button.
    await _tapBelow(tester);

    expect(_host(tester).belowTaps, 0);
    expect(_host(tester).skips, 1);
    semantics.dispose();
  });

  testWidgets('without a skip handler the intro still swallows every tap',
      (tester) async {
    await tester.pumpWidget(const _Host(skippable: false));

    await _tapBelow(tester);
    await _tapBelow(tester);

    expect(_host(tester).belowTaps, 0);
    expect(_host(tester).dismissed, isFalse);
    expect(find.text(_skipHintEn), findsOneWidget);
  });

  testWidgets('tapping the intro skips it: fade, then the overlay is gone',
      (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.byType(IntroOverlay));
    await tester.pump();

    final host = _host(tester);
    expect(host.skips, 1);
    expect(host.dismissed, isTrue);
    // Fade in progress: still in the tree, not yet reported hidden.
    expect(find.text(_skipHintEn), findsOneWidget);
    expect(host.hiddenCalls, 0);

    // Run the fade to completion.
    await tester.pumpAndSettle();

    expect(find.text(_skipHintEn), findsNothing);
    expect(host.hiddenCalls, 1);
    expect(host.skips, 1);
  });

  testWidgets('app underneath is tappable after the intro ends',
      (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.byType(IntroOverlay));
    await tester.pumpAndSettle();
    expect(find.text(_skipHintEn), findsNothing);

    await _tapBelow(tester);
    expect(_host(tester).belowTaps, 1);
    // Still exactly one skip: the overlay is gone, not merely transparent.
    expect(_host(tester).skips, 1);
  });

  testWidgets(
      'once dismissed by the parent (video finished), taps pass through '
      'even while the fade is still running', (tester) async {
    await tester.pumpWidget(const _Host());

    _host(tester).dismiss();
    await tester.pump();
    // Mid-fade: the sheet is still painted but no longer takes touches.
    expect(find.text(_skipHintEn), findsOneWidget);

    await _tapBelow(tester);
    expect(_host(tester).belowTaps, 1);
    expect(_host(tester).skips, 0);

    await tester.pumpAndSettle();
    expect(find.text(_skipHintEn), findsNothing);
    expect(_host(tester).hiddenCalls, 1);
  });

  testWidgets('born dismissed: no overlay, onHidden reported once',
      (tester) async {
    await tester.pumpWidget(const _Host(initiallyDismissed: true));
    await tester.pump();

    expect(find.text(_skipHintEn), findsNothing);
    expect(_host(tester).hiddenCalls, 1);
    await _tapBelow(tester);
    expect(_host(tester).belowTaps, 1);
  });

  testWidgets(
      'BrandSplashOverlay without a platform video player reveals the app '
      'and lets taps through once settled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BrandSplashOverlay(
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('Below'),
              ),
            ),
          ),
        ),
      ),
    );
    // The test binding has no video_player implementation, so initialize()
    // throws and the overlay fades straight away; settle through the fade.
    await tester.pumpAndSettle();

    expect(find.text(_skipHintEn), findsNothing);
    await tester.tap(find.text('Below'));
    await tester.pump();
    expect(taps, 1);
  });
}
