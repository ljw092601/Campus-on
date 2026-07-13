import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/config/app_config.dart';

/// Initializes the Kakao Maps SDK with the injected JS key.
/// No-op when the key is absent so the app still boots (map renders fallback).
///
/// `baseUrl` sets the WebView origin that Kakao's JS SDK reports as the referrer.
/// It must match a **Web 플랫폼** site domain registered on Kakao Developers —
/// register `http://localhost` there so the map tiles are authorized to load.
Future<void> initKakaoMap() async {
  if (!AppConfig.hasKakaoKey) return;
  AuthRepository.initialize(
    appKey: AppConfig.kakaoJsKey,
    baseUrl: 'http://localhost',
  );
}
