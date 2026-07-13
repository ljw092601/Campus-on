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

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, locale.languageCode);
  }

  /// Toggle used by the home app-bar [KO|EN] quick action.
  Future<void> toggle() =>
      setLocale(state.languageCode == 'ko' ? const Locale('en') : const Locale('ko'));
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
