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

/// Per-feature flags for the admin-entered content (academic calendar /
/// dining), independent of [useFirestore] so each can go live only once its
/// collections are actually populated (design doc
/// _workspace/06_admin_data_pipeline.md §7 D5):
///
///   flutter run --dart-define=USE_FIRESTORE_CALENDAR=true
///   flutter run --dart-define=USE_FIRESTORE_DINING=true
const bool useFirestoreCalendar =
    bool.fromEnvironment('USE_FIRESTORE_CALENDAR', defaultValue: false);
const bool useFirestoreDining =
    bool.fromEnvironment('USE_FIRESTORE_DINING', defaultValue: false);

/// True when any Firestore-backed feature is on — gates Firebase init.
const bool anyFirestoreEnabled =
    useFirestore || useFirestoreCalendar || useFirestoreDining;

/// Initializes Firebase + Firestore offline persistence — but ONLY when
/// at least one Firestore flag is on. When all are off this is a no-op, so
/// `main()` never touches Firebase and the app boots on mock data.
///
/// Config comes from `flutterfire configure`: the committed
/// `firebase_options.dart` carries the REAL `campus-f4748` options (Firebase
/// app config is public by design — access control is `firestore.rules`'
/// job), while `google-services.json` / `GoogleService-Info.plist` are
/// gitignored, so a fresh checkout must re-fetch them before building.
/// Careful: turning any flag on connects the app to the production Firestore
/// of `campus-f4748`.
Future<void> initFirebaseIfEnabled() async {
  if (!anyFirestoreEnabled) return;

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
