import 'dart:ui';

/// The languages DONG-A-MATE ships, in menu order: Korean, English, Simplified
/// Chinese, Vietnamese.
///
/// Every locale decision reads from here — the supported list, the menu label,
/// and the fallback chain — so adding a language is a change in one place
/// instead of a new `languageCode == 'ko'` branch somewhere.
const List<String> appLanguageCodes = ['ko', 'en', 'zh', 'vi'];

const List<Locale> supportedAppLocales = [
  Locale('ko'),
  Locale('en'),
  Locale('zh'),
  Locale('vi'),
];

/// Menu label, written in the language itself (never translated).
const Map<String, String> appLanguageNames = {
  'ko': '한국어',
  'en': 'English',
  'zh': '简体中文',
  'vi': 'Tiếng Việt',
};

bool isSupportedLanguage(String? code) =>
    code != null && appLanguageCodes.contains(code);

/// Falls back requested language → English → Korean, so a field nobody has
/// translated yet still shows text instead of a blank line or a key.
List<String> languageFallback(String code) {
  switch (code) {
    case 'ko':
      return const ['ko', 'en'];
    case 'en':
      return const ['en', 'ko'];
    default:
      return isSupportedLanguage(code) ? [code, 'en', 'ko'] : const ['en', 'ko'];
  }
}

/// The language actually shown for [code] given which languages hold text.
/// Used to record what is still falling back instead of translated.
String resolveLanguage(String code, bool Function(String) hasText) {
  for (final c in languageFallback(code)) {
    if (hasText(c)) return c;
  }
  return 'ko';
}

/// Compact label for the home app-bar language button.
const Map<String, String> appLanguageShortNames = {
  'ko': 'KO',
  'en': 'EN',
  'zh': '中文',
  'vi': 'VI',
};

/// Korean/English text for [locale] using the shared fallback chain. Data that
/// only exists in those two languages (facilities, cafeteria menus, floor
/// guides) shows English to Chinese and Vietnamese readers, and Korean when
/// there is no English — never a blank line.
String? pickKoEn(Locale locale, String? ko, String? en) {
  for (final code in languageFallback(locale.languageCode)) {
    final s = code == 'ko' ? ko : (code == 'en' ? en : null);
    if (s != null && s.trim().isNotEmpty) return s;
  }
  // Every chain ends with English and Korean, so nothing is left to try.
  return null;
}
