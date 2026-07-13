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

  /// Fallback campus center used when location permission is denied and as the
  /// default map camera. Replace with the real campus coordinate.
  static const double campusCenterLat = 37.5665;
  static const double campusCenterLng = 126.9780;
}
