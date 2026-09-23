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
  const BrandSplashOverlay({super.key, required this.child});

  final Widget child;

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

  @override
  State<BrandSplashOverlay> createState() => _BrandSplashOverlayState();
}

class _BrandSplashOverlayState extends State<BrandSplashOverlay> {
  VideoPlayerController? _video;
  bool _playing = false;
  bool _fading = false;
  bool _done = false;
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
      if (!mounted || _fading) return;
      video.addListener(_onTick);
      await video.play();
      _timer?.cancel();
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      _fadeOut();
    }
  }

  void _onTick() {
    final value = _video!.value;
    if (_fading || _timer?.isActive == true) return;
    if (value.hasError) {
      _fadeOut();
    } else if (value.isCompleted ||
        (value.duration > Duration.zero && value.position >= value.duration)) {
      _timer = Timer(BrandSplashOverlay.holdDuration, _fadeOut);
    }
  }

  void _fadeOut() {
    if (!mounted || _fading) return;
    _timer?.cancel();
    setState(() => _fading = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                setState(() => _done = true);
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
