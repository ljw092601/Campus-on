import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

const supportedLocales = [Locale('ko'), Locale('en')];

/// App locale with instant switching (UX doc §5). Persisted locally; first run
/// uses the device locale, falling back to English when it is neither ko/en.
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved == 'ko' || saved == 'en') return Locale(saved!);
    final device = PlatformDispatcher.instance.locale.languageCode;
    return device == 'ko' ? const Locale('ko') : const Locale('en');
  }

  /// Switches the in-memory locale immediately and persists it. Returns
  /// whether the preference was written (audit L-27): on a failed or throwing
  /// write the UI language still changes for this session, but the caller can
  /// warn that it may not survive a restart. Same policy as the favorites
  /// repository's `_checkWrite` — SharedPreferences updates its memory cache
  /// even when the native write fails, so the cache is reloaded on failure.
  Future<bool> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return true;
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      if (await prefs.setString(_key, locale.languageCode)) return true;
    } catch (_) {
      // Fall through: reported as a failed write below.
    }
    try {
      await prefs.reload();
    } catch (_) {}
    return false;
  }

  /// Toggle used by the home app-bar [KO|EN] quick action.
  Future<bool> toggle() =>
      setLocale(state.languageCode == 'ko' ? const Locale('en') : const Locale('ko'));
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
