import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';

class CampusOnApp extends ConsumerWidget {
  const CampusOnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
      builder: (context, child) => BrandSplashOverlay(child: child!),
    );
  }
}

/// Opening overlay: plays the DONG-A MATE intro video once over the first
/// frames, holds its last frame briefly, then fades out. The native launch
/// screens use the same brand blue as the video's first frame, so the
/// hand-off from system splash to animation is seamless.
class BrandSplashOverlay extends StatefulWidget {
  const BrandSplashOverlay({super.key, required this.child, this.createPlayer});

  final Widget child;

  /// Test seam. The interesting failures — autoplay refused, playback stalling
  /// — cannot be produced with the real player in a test, and a browser check
  /// cannot force them either (the clip does not even initialize in a headless
  /// profile). Injecting a controller lets the widget's own timers be tested
  /// against a player that says yes and then does nothing.
  @visibleForTesting
  final VideoPlayerController Function()? createPlayer;

  static const asset = 'assets/branding/donga_mate_intro.mp4';

  /// Brand blue for the bars around the 9:16 video on taller screens. The
  /// clip's blue decodes within a couple of RGB steps of this depending on
  /// the device decoder, so no seam is visible.
  static const background = Color(0xFF2F6FED);
  static const holdDuration = Duration(milliseconds: 500);
  static const fadeDuration = Duration(milliseconds: 400);

  /// Give up and reveal the app if the video hasn't started by then (e.g. no
  /// decoder, or widget tests where the platform player doesn't exist).
  static const startTimeout = Duration(seconds: 3);

  /// How often the watchdog samples the playback position once playing.
  ///
  /// The controller republishes its position roughly every 500ms, so sampling
  /// at 200ms sees every update; [stallTimeout] is then three of those updates,
  /// which is what makes it safe against ordinary jitter. Shortening either
  /// value without that margin would cut healthy playback short.
  static const watchInterval = Duration(milliseconds: 200);

  /// Playback that was advancing and then stops for this long counts as stuck.
  static const stallTimeout = Duration(milliseconds: 1500);

  /// How long playback may sit at 0:00 before we give up on it.
  ///
  /// Autoplay being refused and a slow decoder warming up look identical from
  /// here — both leave the position at zero — so this is deliberately the same
  /// budget the app already allowed for starting up ([startTimeout]) rather
  /// than the shorter [stallTimeout]. A phone that takes 2.5s to get the first
  /// frame out still gets to show its intro (감사 05/039 SF-1).
  static const warmupTimeout = Duration(seconds: 3);

  /// Hard ceiling from the moment playback starts. The clip is ~3.2s plus
  /// [holdDuration], so this only fires when something is wrong — but it
  /// guarantees the app is reachable in bounded time whatever the player does.
  ///
  /// Worst case end to end is not this number alone: [startTimeout] to get
  /// playback going, then this, then [fadeDuration] — about 9.4s if every
  /// stage takes its maximum.
  static const maxSplash = Duration(seconds: 6);

  @override
  State<BrandSplashOverlay> createState() => _BrandSplashOverlayState();
}

/// Decides when the splash has to get out of the way.
///
/// Kept apart from the widget because the interesting cases — autoplay refused,
/// playback stalling halfway, a clip that never reports completion — cannot be
/// produced with a real player in a test, but they are all just sequences of
/// position samples.
@visibleForTesting
class SplashWatchdog {
  SplashWatchdog({
    this.stall = BrandSplashOverlay.stallTimeout,
    this.warmup = BrandSplashOverlay.warmupTimeout,
    this.cap = BrandSplashOverlay.maxSplash,
  });

  /// Longest the position may stand still after it has moved at least once.
  final Duration stall;

  /// Longest the position may sit at 0:00 before playback is given up on. A
  /// decoder warming up looks exactly like autoplay being refused, so this is
  /// the more generous of the two allowances (감사 05/039 SF-1).
  final Duration warmup;

  /// Longest the overlay may stay up at all, once playback has started.
  final Duration cap;

  Duration _furthest = Duration.zero;
  Duration _stillFor = Duration.zero;
  Duration _elapsed = Duration.zero;

  Duration get elapsed => _elapsed;

  /// Feeds one sample taken [tick] after the previous one, and says whether the
  /// app must now be revealed.
  ///
  /// [completed] is not a reveal on its own: the normal ending keeps its hold on
  /// the last frame, and that is the widget's timer, not this one's business.
  /// It only stops a finished clip from being read as a stall.
  bool reveal({
    required Duration tick,
    required Duration position,
    required bool completed,
    required bool hasError,
  }) {
    _elapsed += tick;
    if (hasError) return true;
    if (completed) {
      _stillFor = Duration.zero;
    } else if (position > _furthest) {
      _furthest = position;
      _stillFor = Duration.zero;
    } else {
      _stillFor += tick;
    }
    // Nothing has played yet: this is the warm-up budget, not the stall one.
    final limit = _furthest == Duration.zero ? warmup : stall;
    return _stillFor >= limit || _elapsed >= cap;
  }
}

class _BrandSplashOverlayState extends State<BrandSplashOverlay> {
  VideoPlayerController? _video;
  bool _playing = false;
  bool _fading = false;
  bool _done = false;

  /// Safety net until playback is seen to move.
  Timer? _startTimer;

  /// Holds the last frame after the clip finishes — the normal ending.
  Timer? _holdTimer;

  /// Samples the position while playing.
  Timer? _watchTimer;
  SplashWatchdog? _watchdog;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(BrandSplashOverlay.startTimeout, _fadeOut);
    _start();
  }

  Future<void> _start() async {
    final video = widget.createPlayer?.call() ??
        VideoPlayerController.asset(
          BrandSplashOverlay.asset,
          // Silent clip — don't pause whatever audio the user already has
          // playing.
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
    _video = video;
    try {
      await video.initialize();
      if (!mounted || _fading) return;
      video.addListener(_onTick);
      await video.play();
      // `play()` resolving does not mean anything is playing: a browser that
      // blocks autoplay resolves it and leaves the clip parked at 0:00. So the
      // start timer is not cancelled here — the watchdog cancels it once the
      // position has actually moved.
      if (!mounted || _fading) return;
      _watchdog = SplashWatchdog();
      _watchTimer =
          Timer.periodic(BrandSplashOverlay.watchInterval, _onWatch);
      // The watchdog now owns the timeout, with a warm-up budget of its own.
      // Leaving the absolute start timer armed as well would cut the intro
      // 0.1s in on a device that took 2.9s to start playing (감사 05/039 SF-1).
      _startTimer?.cancel();
      _startTimer = null;
      setState(() => _playing = true);
    } catch (_) {
      _fadeOut();
    }
  }

  void _onWatch(Timer _) {
    final video = _video;
    final watchdog = _watchdog;
    if (video == null || watchdog == null || _fading) return;
    final value = video.value;
    final completed = value.isCompleted ||
        (value.duration > Duration.zero && value.position >= value.duration);
    if (completed && _holdTimer == null) {
      // The listener normally arms this; do it here too so a player that stops
      // notifying still gets the designed ending instead of the 6s ceiling
      // (감사 05/039 NIT-2).
      _holdTimer = Timer(BrandSplashOverlay.holdDuration, _fadeOut);
      return;
    }
    if (watchdog.reveal(
      tick: BrandSplashOverlay.watchInterval,
      position: value.position,
      completed: completed,
      hasError: value.hasError,
    )) {
      _fadeOut();
    }
  }

  void _onTick() {
    final video = _video;
    if (video == null || _fading || _holdTimer != null) return;
    final value = video.value;
    if (value.hasError) {
      _fadeOut();
    } else if (value.isCompleted ||
        (value.duration > Duration.zero && value.position >= value.duration)) {
      _holdTimer = Timer(BrandSplashOverlay.holdDuration, _fadeOut);
    }
  }

  void _fadeOut() {
    if (!mounted || _fading) return;
    _cancelTimers();
    setState(() => _fading = true);
  }

  void _cancelTimers() {
    _startTimer?.cancel();
    _holdTimer?.cancel();
    _watchTimer?.cancel();
    _startTimer = null;
    _holdTimer = null;
    _watchTimer = null;
  }

  @override
  void dispose() {
    // Every timer and the player listener go before the state does, so nothing
    // calls back into a disposed widget.
    _cancelTimers();
    _video?.removeListener(_onTick);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_done)
          // Purely visual — never swallow touches, so taps (and widget tests
          // that don't advance the timers) reach the UI underneath.
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: BrandSplashOverlay.fadeDuration,
              onEnd: () {
                // The fade can finish after the route is gone.
                if (!mounted) return;
                setState(() => _done = true);
                _video?.removeListener(_onTick);
                _video?.dispose();
                _video = null;
              },
              child: Container(
                // The video bakes in the brand blue, so the overlay stays
                // blue in dark mode too.
                color: BrandSplashOverlay.background,
                alignment: Alignment.center,
                child: !_playing || video == null
                    ? null
                    : AspectRatio(
                        aspectRatio: video.value.aspectRatio,
                        child: VideoPlayer(video),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
