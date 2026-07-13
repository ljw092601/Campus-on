import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Single toggle for the whole data layer: mock (default) vs. Firestore.
///
///   flutter run --dart-define=USE_FIRESTORE=true
///
/// Default `false` keeps the app bootable with zero Firebase setup (mock data),
/// so app-developer / QA / offline demos run without a Firebase project.
/// `repository_providers.dart` reads this same flag to pick the implementations.
const bool useFirestore =
    bool.fromEnvironment('USE_FIRESTORE', defaultValue: false);

/// Initializes Firebase + Firestore offline persistence — but ONLY when
/// [useFirestore] is on. When off this is a no-op, so `main()` never touches
/// Firebase and the app boots on mock data.
///
/// Requires real config from `flutterfire configure` (writes `firebase_options.dart`
/// + `google-services.json` / `GoogleService-Info.plist`). The committed
/// `firebase_options.dart` is a placeholder; running with `USE_FIRESTORE=true`
/// against placeholders will fail fast at init (by design — no silent bad state).
Future<void> initFirebaseIfEnabled() async {
  if (!useFirestore) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline persistence is on by default on mobile; set it explicitly so the
  // repositories' cache fallback (Source.cache) always has a store to read.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
