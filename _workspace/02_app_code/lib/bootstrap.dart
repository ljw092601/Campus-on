import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/firebase_init.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'presentation/map/widgets/kakao_init.dart';
import 'presentation/providers/repository_providers.dart';
import 'presentation/shared/widgets/state_views.dart';

/// Successful stages are retained; retries never change the configured data source.
class AppInitializer {
  bool _firebaseReady = false;
  SharedPreferences? _prefs;
  Future<SharedPreferences> initialize() async {
    if (!_firebaseReady) {
      await initFirebaseIfEnabled();
      _firebaseReady = true;
    }
    _prefs ??= await SharedPreferences.getInstance();
    await initKakaoMap();
    return _prefs!;
  }
}

/// Mounts before platform initialization, so even startup failures have a UI.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap(
      {super.key,
      required this.initialize,
      this.timeout = const Duration(seconds: 20),
      this.appBuilder});

  final Future<SharedPreferences> Function() initialize;
  final Duration timeout;
  final Widget Function(SharedPreferences)? appBuilder;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Future<SharedPreferences>? _inFlight;
  SharedPreferences? _prefs;
  bool _failed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    // A timeout cannot cancel a native operation. Reuse it until it completes
    // rather than starting concurrent Firebase / preferences initialization.
    final operation = _inFlight ??= Future.sync(widget.initialize);
    unawaited(operation.then((_) {
      if (identical(_inFlight, operation)) _inFlight = null;
    }, onError: (Object _, StackTrace __) {
      if (identical(_inFlight, operation)) _inFlight = null;
    }));
    try {
      final prefs = await operation.timeout(widget.timeout);
      if (!mounted || attempt != _attempt) return;
      setState(() => _prefs = prefs);
    } catch (_) {
      if (!mounted || attempt != _attempt) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    if (prefs != null) {
      return widget.appBuilder?.call(prefs) ??
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const CampusOnApp(),
          );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        final l = AppLocalizations.of(context);
        return Scaffold(
            body: SafeArea(
                child: _failed
                    ? ErrorStateView(
                        message: l.startup_error_failed,
                        retryLabel: l.common_retry,
                        onRetry: () {
                          setState(() => _failed = false);
                          _start();
                        })
                    : Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l.startup_loading),
                      ]))));
      }),
    );
  }
}
