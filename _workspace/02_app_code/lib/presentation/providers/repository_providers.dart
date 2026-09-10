import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/firebase_init.dart'
    show useFirestore, useFirestoreCalendar, useFirestoreDining;
import '../../data/firestore/firestore_academic_calendar_repository.dart';
import '../../data/firestore/firestore_dining_repository.dart';
import '../../data/firestore/firestore_facility_repository.dart';
import '../../data/firestore/firestore_floor_guide_repository.dart';
import '../../data/firestore/firestore_guide_repository.dart';
import '../../data/repositories/local_favorites_repository.dart';
import '../../data/repositories/mock_academic_calendar_repository.dart';
import '../../data/repositories/mock_dining_repository.dart';
import '../../data/repositories/mock_facility_repository.dart';
import '../../data/repositories/mock_floor_guide_repository.dart';
import '../../data/repositories/mock_guide_repository.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import '../../domain/repositories/dining_repository.dart';
import '../../domain/repositories/facility_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/floor_guide_repository.dart';
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

final floorGuideRepositoryProvider = Provider<FloorGuideRepository>(
  (ref) => useFirestore
      ? FirestoreFloorGuideRepository(FirebaseFirestore.instance)
      : MockFloorGuideRepository(),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => LocalFavoritesRepository(ref.watch(sharedPreferencesProvider)),
);

/// Cafeteria menus — admin-entered via the sheet sync (tool/admin_sheets/).
/// Own flag (not [useFirestore]) so it flips on only once the `cafeterias` /
/// `dining_menus` collections are populated; mock stays the dev default.
final diningRepositoryProvider = Provider<DiningRepository>(
  (ref) => useFirestoreDining
      ? FirestoreDiningRepository(FirebaseFirestore.instance)
      : MockDiningRepository(),
);

/// Academic calendar — admin-entered via the sheet sync (tool/admin_sheets/).
/// Same per-feature flag policy as dining.
final academicCalendarRepositoryProvider = Provider<AcademicCalendarRepository>(
  (ref) => useFirestoreCalendar
      ? FirestoreAcademicCalendarRepository(FirebaseFirestore.instance)
      : MockAcademicCalendarRepository(),
);
