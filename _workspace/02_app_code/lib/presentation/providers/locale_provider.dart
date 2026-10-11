import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_languages.dart';
import 'repository_providers.dart';

/// Locales the app offers (see `core/i18n/app_languages.dart`).
const supportedLocales = supportedAppLocales;

/// App locale with instant switching (UX doc §5). Persisted locally; first run
/// uses the device locale when the app ships that language, and English
/// otherwise.
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (isSupportedLanguage(saved)) return Locale(saved!);
    final device = PlatformDispatcher.instance.locale.languageCode;
    return isSupportedLanguage(device) ? Locale(device) : const Locale('en');
  }

  /// Switches the in-memory locale immediately and persists it. Returns
  /// whether the preference was written (audit L-27 / 감사 05/034 N-1): on a
  /// failed or throwing write (e.g. web private window, blocked site data) the
  /// UI language still changes for this session, but the caller can warn that
  /// it may not survive a restart. Same policy as the favorites repository's
  /// `_checkWrite` — SharedPreferences updates its memory cache even when the
  /// native write fails, so the cache is reloaded on failure.
  Future<bool> setLocale(Locale locale) async {
    if (!isSupportedLanguage(locale.languageCode)) return true;
    if (locale.languageCode == state.languageCode) return true;
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      if (await prefs.setString(_key, locale.languageCode)) return true;
    } catch (_) {
      // Fall through: the switch itself already happened; losing it on the
      // next start is better than dropping the reader back into a language
      // they can't read.
    }
    try {
      await prefs.reload();
    } catch (_) {}
    return false;
  }

  /// Legacy KO/EN quick toggle. The home app bar now uses the 4-language
  /// pill menu ([setLocale]); kept so any remaining caller still compiles.
  Future<bool> toggle() =>
      setLocale(state.languageCode == 'ko' ? const Locale('en') : const Locale('ko'));
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
