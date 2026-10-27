import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/theme_mode_provider.dart';

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
      themeMode: ref.watch(themeModeProvider),
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
///
/// Owns the video lifecycle and timers only; the pointer blocking, "tap to
/// skip" affordance and fade live in [IntroOverlay] so they can be tested
/// without a platform video player.
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
  static const fadeDuration = IntroOverlay.fadeDuration;

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
      // Skipped (or unmounted) while the decoder was warming up: the
      // controller is released by [_releaseVideo] and never played.
      if (!mounted || _fading || _video != video) return;
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

  /// "Tap to skip": freeze the clip and start the fade right away. Idempotent;
  /// a second tap, or the hold timer firing afterwards, is a no-op.
  void _skip() {
    if (_fading) return;
    final video = _video;
    if (video != null && video.value.isInitialized) {
      unawaited(video.pause().catchError((_) {}));
    }
    _fadeOut();
  }

  void _fadeOut() {
    if (!mounted || _fading) return;
    _cancelTimers();
    setState(() => _fading = true);
  }

  /// Detaches and disposes the controller exactly once; safe to call from
  /// both the fade's end and [dispose].
  void _releaseVideo() {
    final video = _video;
    _video = null;
    if (video == null) return;
    video.removeListener(_onTick);
    video.dispose();
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
    _releaseVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return IntroOverlay(
      dismissed: _fading,
      onSkip: _skip,
      onHidden: _releaseVideo,
      content: !_playing || video == null
          ? null
          : AspectRatio(
              aspectRatio: video.value.aspectRatio,
              child: VideoPlayer(video),
            ),
      child: widget.child,
    );
  }
}

/// Presentational half of the intro. Draws [content] (the video, or nothing)
/// on a brand-blue sheet above [child], and:
///
/// * while visible, swallows every touch so nothing reaches the app
///   underneath, and reports a tap anywhere as [onSkip];
/// * once [dismissed] flips to true, lets touches through immediately and
///   fades out over [fadeDuration], then removes itself and calls [onHidden].
///
/// Has no dependency on `video_player`, so it is widget-testable as is.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({
    super.key,
    required this.child,
    required this.dismissed,
    this.onSkip,
    this.onHidden,
    this.content,
  });

  /// The app, laid out underneath the overlay.
  final Widget child;

  /// True once the intro is over (video finished, failed, timed out or
  /// skipped). Flipping it starts the fade-out; it never flips back.
  final bool dismissed;

  /// Called when the user taps the overlay while it is still showing.
  final VoidCallback? onSkip;

  /// Called once the fade-out has finished and the overlay is gone.
  final VoidCallback? onHidden;

  /// What to draw centred on the sheet (the video). Null draws plain blue.
  final Widget? content;

  static const background = BrandSplashOverlay.background;
  static const fadeDuration = Duration(milliseconds: 400);

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    // Nothing to fade from if we were born dismissed; AnimatedOpacity would
    // never fire onEnd, so settle the state right away.
    if (widget.dismissed) {
      _hidden = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHidden?.call();
      });
    }
  }

  void _onFadeEnd() {
    if (_hidden || !widget.dismissed) return;
    setState(() => _hidden = true);
    widget.onHidden?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hint = AppLocalizations.of(context).intro_skipHint;
    final dismissed = widget.dismissed;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_hidden)
          // The fade is purely visual: as soon as the intro is dismissed the
          // overlay stops taking touches, so the app underneath is usable at
          // once (and widget tests that tap right after boot still work).
          IgnorePointer(
            ignoring: dismissed,
            child: AnimatedOpacity(
              opacity: dismissed ? 0 : 1,
              duration: IntroOverlay.fadeDuration,
              onEnd: _onFadeEnd,
              // Keep screen readers off the home UI until the intro is gone.
              child: BlockSemantics(
                blocking: !dismissed,
                child: Semantics(
                  button: true,
                  label: hint,
                  onTap: dismissed ? null : widget.onSkip,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: dismissed ? null : widget.onSkip,
                    child: Container(
                      // The video bakes in the brand blue, so the overlay
                      // stays blue in dark mode too.
                      color: IntroOverlay.background,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.content != null) widget.content!,
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  hint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
