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

  /// Switches language now and remembers the choice. Whether it could be
  /// remembered is the return value: on the web in a private window, or with
  /// site data blocked, the write throws and the language then lasts only for
  /// this run (감사 05/034 N-1). Callers that can say so to the reader should.
  Future<bool> setLocale(Locale locale) async {
    if (!isSupportedLanguage(locale.languageCode)) return true;
    if (locale.languageCode == state.languageCode) return true;
    state = locale;
    try {
      return await ref
          .read(sharedPreferencesProvider)
          .setString(_key, locale.languageCode);
    } catch (_) {
      // The switch itself already happened; losing it on the next start is
      // better than dropping the reader back into a language they can't read.
      return false;
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
