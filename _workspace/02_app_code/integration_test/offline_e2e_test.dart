import 'package:campus_on/main.dart' as app;
import 'package:campus_on/core/config/firebase_init.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/domain/repositories/read_result.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/calendar/academic_calendar_screen.dart';
import 'package:campus_on/presentation/dining/dining_menu_screen.dart';
import 'package:campus_on/presentation/facility/facility_list_screen.dart';
import 'package:campus_on/presentation/home/home_screen.dart';
import 'package:campus_on/presentation/providers/academic_calendar_providers.dart';
import 'package:campus_on/presentation/providers/dining_providers.dart';
import 'package:campus_on/presentation/providers/facility_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Firestore cached content, uncached failure and online retry',
      (tester) async {
    expect(useFirestore && useFirestoreCalendar && useFirestoreDining, isTrue,
        reason: 'Run with tool/run_map_e2e.py --test offline --firestore');
    Future<void> until(
        Future<bool> Function() condition, String description) async {
      final deadline = DateTime.now().add(const Duration(seconds: 40));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (await condition()) return;
      }
      fail('Timed out: $description');
    }

    await app.main();
    await until(
        () async => find.byType(HomeScreen).evaluate().isNotEmpty, 'startup');
    await tester.pump(const Duration(seconds: 6));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    final db = FirebaseFirestore.instance;
    final facilities = await container.read(allFacilitiesProvider.future);
    expect(facilities, isNotEmpty);
    final events = await container.read(academicEventsProvider.future);
    final today = diningDateKey(DateTime.now());
    await container.read(diningMenusProvider(today).future);
    debugPrint('E2E_PASS real_Firestore_dining_and_calendar_sources');
    try {
      await db.disableNetwork();
      AppRouter.router.go('/map/list');
      container.invalidate(allFacilitiesProvider);
      await until(
          () async => find.byType(FacilityListScreen).evaluate().isNotEmpty,
          'facility list');
      final l =
          AppLocalizations.of(tester.element(find.byType(FacilityListScreen)));
      await until(
          () async => find.textContaining(l.data_cached).evaluate().isNotEmpty,
          'cached facility notice');
      expect(isCachedRead(container.read(allFacilitiesProvider).requireValue),
          isTrue);
      debugPrint('E2E_PASS cached_facilities_visible');

      AppRouter.router.go('/home/calendar');
      container.invalidate(academicEventsProvider);
      await until(
          () async => find.byType(AcademicCalendarScreen).evaluate().isNotEmpty,
          'calendar');
      await until(
          () async => find
              .text(events.isEmpty ? l.data_offline_unavailable : l.data_cached)
              .evaluate()
              .isNotEmpty,
          'calendar cached/unknown state');
      debugPrint('E2E_PASS calendar_offline_state');

      // No writes: a remote future date intentionally has no cached menu rows.
      await expectLater(
          container
              .read(diningRepositoryProvider)
              .getMenus(DateTime(2099, 12, 29)),
          throwsA(isA<OfflineDataUnavailable>()));
      debugPrint('E2E_PASS uncached_menu_not_unpublished');
      AppRouter.router.go('/home/dining');
      container.invalidate(diningMenusProvider(today));
      await until(
          () async => find.byType(DiningMenuScreen).evaluate().isNotEmpty,
          'dining');
      await until(
          () async =>
              find.textContaining(l.data_cached).evaluate().isNotEmpty ||
              find.text(l.data_offline_unavailable).evaluate().isNotEmpty,
          'dining offline notice');
      await db.enableNetwork();
      await tester.tap(find.text(l.common_retry).first);
      await until(() async {
        final value = container.read(diningMenusProvider(today));
        return value.hasValue && !value.isLoading && !isCachedRead(value.value);
      }, 'dining retry reaches server');
      expect(find.text(l.data_offline_unavailable), findsNothing);
      expect(find.textContaining(l.data_cached), findsNothing);
      expect(find.text(l.dining_placeholder_notice), findsNothing);
      debugPrint('E2E_PASS dining_retry_restores_online_state');
      expect(tester.takeException(), isNull);
      debugPrint('E2E_OFFLINE_COMPLETE');
    } finally {
      await db.enableNetwork();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
