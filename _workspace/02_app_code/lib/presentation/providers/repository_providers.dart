import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/firebase_init.dart' show useFirestore;
import '../../data/firestore/firestore_facility_repository.dart';
import '../../data/firestore/firestore_guide_repository.dart';
import '../../data/repositories/local_favorites_repository.dart';
import '../../data/repositories/mock_facility_repository.dart';
import '../../data/repositories/mock_guide_repository.dart';
import '../../domain/repositories/facility_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/guide_repository.dart';

/// Overridden in `main()` after async init (see main.dart).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// === Repository swap points ===
/// One flag toggles the whole data layer: mock (default) vs. Firestore.
/// Enable Firestore with:  flutter run --dart-define=USE_FIRESTORE=true
/// The flag lives in `core/config/firebase_init.dart` (same one that guards
/// `Firebase.initializeApp`). Interfaces and every screen/provider are unchanged.
///
/// `FirebaseFirestore.instance` is only touched on the Firestore branch, so with
/// the flag off the app never initializes Firebase and boots on mock data.
final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => useFirestore
      ? FirestoreFacilityRepository(FirebaseFirestore.instance)
      : MockFacilityRepository(),
);

final guideRepositoryProvider = Provider<GuideRepository>(
  (ref) => useFirestore
      ? FirestoreGuideRepository(FirebaseFirestore.instance)
      : MockGuideRepository(),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => LocalFavoritesRepository(ref.watch(sharedPreferencesProvider)),
);
