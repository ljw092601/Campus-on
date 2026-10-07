import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/config/app_config.dart';

/// Initializes the Kakao Maps SDK with the injected JS key.
/// No-op when the key is absent so the app still boots (map renders fallback).
///
/// `baseUrl` sets the WebView origin that Kakao's JS SDK reports as the referrer.
/// It must match a **Web 플랫폼** site domain registered on Kakao Developers —
/// register `localhost` there so the map tiles are authorized to load.
///
/// The origin is https (not http) on purpose: the SDK bootstrap injects
/// protocol-relative `//t1.kakaocdn.net/...` scripts and `//dapi.kakao.com`
/// service calls, which inherit this scheme. With https the app needs no
/// cleartext exemption at all (audit L-32); Kakao's domain check only looks at
/// the host, so `https://localhost` passes with the same registration.
Future<void> initKakaoMap() async {
  if (!AppConfig.hasKakaoKey) return;
  AuthRepository.initialize(
    appKey: AppConfig.kakaoJsKey,
    baseUrl: 'https://localhost',
  );
}
