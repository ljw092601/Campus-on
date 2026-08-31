import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Opening overlay shown over the first frames: the full 동아메이트 wordmark
/// logo on white, fading out after a short hold. The Android 12+ system
/// splash masks its icon to a small circle, so this is the only place the
/// wordmark version of the logo can appear on launch.
class BrandSplashOverlay extends StatefulWidget {
  const BrandSplashOverlay({super.key, required this.child});

  final Widget child;

  static const holdDuration = Duration(milliseconds: 2000);
  static const fadeDuration = Duration(milliseconds: 500);

  @override
  State<BrandSplashOverlay> createState() => _BrandSplashOverlayState();
}

class _BrandSplashOverlayState extends State<BrandSplashOverlay> {
  bool _fading = false;
  bool _done = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer(BrandSplashOverlay.holdDuration, () {
      if (mounted) setState(() => _fading = true);
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_done)
          // Purely visual — never swallow touches, so taps (and widget tests
          // that don't advance the hold timer) reach the UI underneath.
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: BrandSplashOverlay.fadeDuration,
              onEnd: () => setState(() => _done = true),
              child: Container(
                // The logo bakes in a white ground, so the overlay stays
                // white in dark mode too.
                color: Colors.white,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/branding/donga_mate_full.png',
                  width: 340,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
