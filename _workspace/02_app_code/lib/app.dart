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
///
/// Owns the video lifecycle and timers only; the pointer blocking, "tap to
/// skip" affordance and fade live in [IntroOverlay] so they can be tested
/// without a platform video player.
class BrandSplashOverlay extends StatefulWidget {
  const BrandSplashOverlay({super.key, required this.child});

  final Widget child;

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

  @override
  State<BrandSplashOverlay> createState() => _BrandSplashOverlayState();
}

class _BrandSplashOverlayState extends State<BrandSplashOverlay> {
  VideoPlayerController? _video;
  bool _playing = false;
  bool _fading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(BrandSplashOverlay.startTimeout, _fadeOut);
    _start();
  }

  Future<void> _start() async {
    final video = VideoPlayerController.asset(
      BrandSplashOverlay.asset,
      // Silent clip — don't pause whatever audio the user already has playing.
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
      _timer?.cancel();
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      _fadeOut();
    }
  }

  void _onTick() {
    final value = _video?.value;
    if (value == null || _fading || _timer?.isActive == true) return;
    if (value.hasError) {
      _fadeOut();
    } else if (value.isCompleted ||
        (value.duration > Duration.zero && value.position >= value.duration)) {
      _timer = Timer(BrandSplashOverlay.holdDuration, _fadeOut);
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
    _timer?.cancel();
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

  @override
  void dispose() {
    _timer?.cancel();
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
