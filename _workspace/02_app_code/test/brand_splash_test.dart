import 'dart:io';
import 'dart:typed_data';

import 'package:campus_on/app.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_test/flutter_test.dart';

/// The intro overlay used to trap the user on a blank brand-blue screen.
///
/// `play()` resolving was treated as proof that the clip was running, and the
/// escape timer was cancelled at that moment. A browser that refuses autoplay
/// resolves `play()` and then leaves the clip paused at 0:00 with no error and
/// no completion event — so nothing ever faded the overlay and the app could
/// not be reached at all. Reproduced in Chrome with default settings.
///
/// The player itself cannot produce those states in a test, but they are all
/// just sequences of position samples, which is what [SplashWatchdog] consumes.

/// A player that behaves exactly like a browser that refuses autoplay:
/// `initialize()` succeeds, `play()` resolves — and the position never moves.
class _StalledPlayer extends VideoPlayerController {
  _StalledPlayer({this.advanceTo})
      : super.networkUrl(Uri.parse('https://example.invalid/intro.mp4'));

  /// Optional: play normally up to here, then freeze (a mid-clip stall).
  final Duration? advanceTo;

  bool disposed = false;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      duration: const Duration(seconds: 3),
      isInitialized: true,
    );
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    if (advanceTo != null) value = value.copyWith(position: advanceTo);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}

/// Plays through to the end and reports completion, like a healthy device.
class _HealthyPlayer extends VideoPlayerController {
  _HealthyPlayer()
      : super.networkUrl(Uri.parse('https://example.invalid/intro.mp4'));

  static const clip = Duration(seconds: 3);

  @override
  Future<void> initialize() async {
    value = value.copyWith(duration: clip, isInitialized: true);
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  /// Drives playback the way a real player's ticker would.
  void advance(Duration to) {
    value = value.copyWith(
      position: to,
      isPlaying: to < clip,
      isCompleted: to >= clip,
    );
  }

}

void main() {
  const tick = BrandSplashOverlay.watchInterval;

  /// Feeds [samples] one tick apart and returns how long it took to reveal, or
  /// null if the watchdog never asked to reveal.
  Duration? revealAfter(
    Iterable<Duration> samples, {
    bool completedAtEnd = false,
    bool errorAt = false,
    Duration? duration,
  }) {
    final w = SplashWatchdog();
    for (final p in samples) {
      final done = duration != null && p >= duration;
      if (w.reveal(
        tick: tick,
        position: p,
        completed: completedAtEnd && done,
        hasError: errorAt,
      )) {
        return w.elapsed;
      }
    }
    return null;
  }

  /// Positions for a clip playing normally at real time for [length].
  List<Duration> playing(Duration length) => [
        for (var t = tick; t <= length; t += tick) t,
      ];

  group('SplashWatchdog', () {
    test('normal playback runs to the end and through completion', () {
      // The real clip is 3.234s (its mvhd box). Play it out past the end so the
      // completed samples are exercised too — stopping at 3.200s only proved
      // that an advancing position is left alone (감사 05/039 NIT-3).
      const clip = Duration(milliseconds: 3234);
      final samples = [
        ...playing(clip),
        for (var i = 0; i < 3; i++) clip, // the last frame, briefly held
      ];
      expect(revealAfter(samples, duration: clip, completedAtEnd: true), isNull,
          reason: 'a clip that keeps advancing, then finishes, must not be '
              'interrupted — the hold and fade are the widget\'s job');
    });

    test('autoplay refused: parked at 0:00 reveals within the warm-up budget',
        () {
      // What Chrome actually does: play() resolves, position never moves.
      final stuck = [for (var i = 0; i < 100; i++) Duration.zero];
      final took = revealAfter(stuck);
      expect(took, isNotNull, reason: 'the app must not stay covered');
      expect(took!, lessThanOrEqualTo(BrandSplashOverlay.warmupTimeout + tick),
          reason: 'revealed about when the warm-up budget says, not later');
      expect(took, greaterThan(BrandSplashOverlay.stallTimeout),
          reason: 'a decoder warming up looks the same as autoplay refused, so '
              'it gets the longer budget — cutting at 1.5s would chop the intro '
              'off a slow phone (감사 05/039 SF-1)');
    });

    test('playback that stalls halfway still reveals', () {
      final half = playing(const Duration(milliseconds: 1600));
      final frozen = [
        ...half,
        for (var i = 0; i < 100; i++) const Duration(milliseconds: 1600),
      ];
      final took = revealAfter(frozen);
      expect(took, isNotNull);
      expect(
          took!,
          lessThanOrEqualTo(const Duration(milliseconds: 1600) +
              BrandSplashOverlay.stallTimeout +
              tick),
          reason: 'the stall is measured from where it froze, not from zero');
    });

    test('a player error reveals immediately', () {
      expect(revealAfter([Duration.zero], errorAt: true), equals(tick));
    });

    test('the cap bounds the overlay even while the clip keeps advancing', () {
      // A clip far longer than ours (or a position that creeps forever) must
      // still hand the screen over.
      final long = playing(const Duration(seconds: 30));
      final took = revealAfter(long, duration: const Duration(seconds: 30));
      expect(took, isNotNull, reason: 'the absolute cap has to apply');
      expect(took!, lessThanOrEqualTo(BrandSplashOverlay.maxSplash + tick));
    });

    test('a finished clip is not counted as a stall', () {
      // The widget holds the last frame; the watchdog must not race that hold,
      // so completion resets the stall counter. Hold for longer than the stall
      // limit, or deleting that reset would leave this test green
      // (감사 05/039 SF-3).
      const clip = Duration(seconds: 1);
      final holdTicks = (BrandSplashOverlay.stallTimeout.inMilliseconds ~/
              tick.inMilliseconds) +
          5; // comfortably past the limit
      final held = [
        ...playing(clip),
        for (var i = 0; i < holdTicks; i++) clip,
      ];
      expect(
          held.length * tick.inMilliseconds,
          greaterThan(clip.inMilliseconds +
              BrandSplashOverlay.stallTimeout.inMilliseconds),
          reason: 'the held stretch has to outlast the stall limit, or this '
              'test cannot fail');
      expect(revealAfter(held, duration: clip, completedAtEnd: true), isNull,
          reason: 'holding the last frame is the normal ending, not a stall');
    });

    test('the cap still applies to a clip that is held forever', () {
      const clip = Duration(seconds: 1);
      final stuckOnLastFrame = [
        ...playing(clip),
        for (var i = 0; i < 200; i++) clip,
      ];
      final took = revealAfter(stuckOnLastFrame,
          duration: clip, completedAtEnd: true);
      expect(took, isNotNull,
          reason: 'a hold that never ends must not keep the app covered');
      // When, not just whether: if the completed reset were removed this would
      // fire at the stall limit instead, and 'isNotNull' would not notice
      // (감사 05/039 SF-3).
      expect(took!, greaterThanOrEqualTo(BrandSplashOverlay.maxSplash),
          reason: 'it is the absolute cap that ends this, not a stall');
    });
  });

  group('BrandSplashOverlay widget', () {
    testWidgets('the app underneath is reachable when there is no player',
        (tester) async {
      // Widget tests have no platform video player, so initialize() throws —
      // the same path as a device with no decoder.
      await tester.pumpWidget(const MaterialApp(
        home: BrandSplashOverlay(child: Text('home screen')),
      ));
      // The overlay never swallows touches, so the child is in the tree at once.
      expect(find.text('home screen'), findsOneWidget);

      await tester.pump(BrandSplashOverlay.startTimeout);
      await tester.pump(BrandSplashOverlay.fadeDuration);
      await tester.pumpAndSettle();

      // Fully revealed: opacity back to 1 and the blue gone.
      final opacity = tester.widgetList<AnimatedOpacity>(
          find.byType(AnimatedOpacity));
      expect(opacity.where((o) => o.opacity != 0), isEmpty,
          reason: 'the overlay must have faded out, not stayed at opacity 1');
    });


    testWidgets('autoplay refused: the overlay still gets out of the way',
        (tester) async {
      // The defect, end to end. Before the fix the start timer was cancelled the
      // moment play() resolved, so this player kept the app covered forever.
      final player = _StalledPlayer();
      await tester.pumpWidget(MaterialApp(
        home: BrandSplashOverlay(
          createPlayer: () => player,
          child: const Text('home screen'),
        ),
      ));
      await tester.pump();           // let initialize()/play() settle
      await tester.pump();

      // Still covered right after playback 'starts'.
      expect(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .any((o) => o.opacity == 1),
          isTrue,
          reason: 'the splash is up while we think the clip is starting');

      await tester.pump(BrandSplashOverlay.warmupTimeout);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(BrandSplashOverlay.fadeDuration);
      await tester.pumpAndSettle();

      expect(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .where((o) => o.opacity != 0),
          isEmpty,
          reason: 'a player that never advances must not keep the app covered');
      expect(find.text('home screen'), findsOneWidget);
    });

    testWidgets('a stall halfway through is caught too', (tester) async {
      final player = _StalledPlayer(advanceTo: const Duration(seconds: 1));
      await tester.pumpWidget(MaterialApp(
        home: BrandSplashOverlay(
          createPlayer: () => player,
          child: const Text('home screen'),
        ),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(BrandSplashOverlay.stallTimeout +
          const Duration(milliseconds: 400));
      await tester.pump(BrandSplashOverlay.fadeDuration);
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .where((o) => o.opacity != 0),
          isEmpty);
    });

    testWidgets('normal playback keeps the intro and its hold', (tester) async {
      final player = _HealthyPlayer();
      await tester.pumpWidget(MaterialApp(
        home: BrandSplashOverlay(
          createPlayer: () => player,
          child: const Text('home screen'),
        ),
      ));
      await tester.pump();
      await tester.pump();

      // Drive the clip the way a real player would, in watchdog-sized steps.
      for (var t = BrandSplashOverlay.watchInterval;
          t < _HealthyPlayer.clip;
          t += BrandSplashOverlay.watchInterval) {
        player.advance(t);
        await tester.pump(BrandSplashOverlay.watchInterval);
        expect(
            tester
                .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
                .any((o) => o.opacity == 1),
            isTrue,
            reason: 'the intro must not be cut short at $t while it is playing');
      }

      player.advance(_HealthyPlayer.clip);
      await tester.pump(BrandSplashOverlay.watchInterval);
      // The last frame is held, then it fades — the ending as designed.
      await tester.pump(BrandSplashOverlay.holdDuration);
      await tester.pump(BrandSplashOverlay.fadeDuration);
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .where((o) => o.opacity != 0),
          isEmpty);
      expect(find.text('home screen'), findsOneWidget);
    });

    testWidgets('no timer outlives the widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: BrandSplashOverlay(child: Text('home screen')),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      // Tearing down mid-splash must not leave a timer to fire into a disposed
      // state; the test framework fails the test if one is pending.
      await tester.pumpWidget(const MaterialApp(home: Text('elsewhere')));
      expect(find.text('elsewhere'), findsOneWidget);
    });
  });

  group('the intro asset', () {
    /// Length of an mp4 from its `mvhd` box — duration / timescale.
    Duration mp4Duration(Uint8List bytes) {
      for (var i = 0; i + 24 < bytes.length; i++) {
        if (bytes[i] != 0x6d /* m */ ||
            bytes[i + 1] != 0x76 /* v */ ||
            bytes[i + 2] != 0x68 /* h */ ||
            bytes[i + 3] != 0x64 /* d */) {
          continue;
        }
        final version = bytes[i + 4];
        final at = i + 4 + 4 + (version == 1 ? 16 : 8);
        int be32(int o) =>
            (bytes[o] << 24) | (bytes[o + 1] << 16) | (bytes[o + 2] << 8) | bytes[o + 3];
        final timescale = be32(at);
        final duration = version == 1 ? be32(at + 8) : be32(at + 4);
        if (timescale == 0) continue;
        return Duration(milliseconds: (duration * 1000 / timescale).round());
      }
      throw StateError('no mvhd box found');
    }

    test('is short enough that the splash never has to cut it off', () {
      // Swapping in a longer clip would otherwise be silently truncated by the
      // absolute cap, and nothing would say so (감사 05/039 NIT-6).
      final file = File('assets/branding/${BrandSplashOverlay.asset.split('/').last}');
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
      final clip = mp4Duration(file.readAsBytesSync());

      // Floor as well as ceiling: a parser that silently returned 0 would make
      // the real assertion below pass no matter what the clip is.
      expect(clip, greaterThan(const Duration(seconds: 1)),
          reason: 'mvhd parsed as ${clip.inMilliseconds}ms — that is not a '
              'plausible intro length, so the parse is wrong');

      final budget = BrandSplashOverlay.maxSplash -
          BrandSplashOverlay.holdDuration -
          BrandSplashOverlay.fadeDuration;
      expect(clip, lessThan(budget),
          reason: 'the intro is ${clip.inMilliseconds}ms but only '
              '${budget.inMilliseconds}ms fits before the cap ends the splash. '
              'Either shorten the clip or raise BrandSplashOverlay.maxSplash — '
              'and check the worst-case wait in its doc comment.');
    });
  });
}
