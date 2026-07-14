/// App-wide configuration and secret injection.
///
/// The Kakao Maps JavaScript key is NEVER hard-coded. It is injected at build
/// time with `--dart-define`:
///
///   flutter run --dart-define=KAKAO_JS_KEY=your_js_key_here
///
/// or via a define file:
///
///   flutter run --dart-define-from-file=env.json
///   // env.json: { "KAKAO_JS_KEY": "..." }
///
/// If no key is provided the map screen renders its documented "load failed"
/// fallback (see S2) instead of crashing.
class AppConfig {
  const AppConfig._();

  /// Kakao Maps JavaScript app key (from Kakao Developers console).
  static const String kakaoJsKey =
      String.fromEnvironment('KAKAO_JS_KEY', defaultValue: '');

  static bool get hasKakaoKey => kakaoJsKey.isNotEmpty;

  /// Campus center = 동아대학교 승학캠퍼스 (부산 사하구 낙동대로550번길 37).
  /// Used as the default map camera and the fallback when location permission is
  /// denied. Individual facility coordinates are still placeholders clustered
  /// around this point until the real building survey is provided.
  static const double campusCenterLat = 35.1148;
  static const double campusCenterLng = 128.9683;

  /// Contact email shown on the Settings → Contact page (S9).
  static const String contactEmail = 'donga.campus.on@gmail.com';

  /// Privacy policy URL (store-review requirement). Placeholder until the real
  /// policy is hosted (plan.md suggests GitHub Pages); overridable at build time.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://ljw092601.github.io/Campus-on/privacy',
  );
}
