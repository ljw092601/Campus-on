import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/firebase_init.dart';
import 'presentation/map/widgets/kakao_init.dart';
import 'presentation/providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase + Firestore offline persistence — no-op unless the app is run with
  // --dart-define=USE_FIRESTORE=true (default off keeps mock-data boot working
  // with zero Firebase setup). See core/config/firebase_init.dart.
  await initFirebaseIfEnabled();

  // Local storage for favorites / language / recent searches.
  final prefs = await SharedPreferences.getInstance();

  // Kakao Maps SDK — no-op when KAKAO_JS_KEY is not injected (map shows its
  // documented fallback instead of crashing). See core/config/app_config.dart.
  await initKakaoMap();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CampusOnApp(),
    ),
  );
}
