import 'package:campus_on/core/theme/app_theme.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/data/repositories/mock_facility_repository.dart';
import 'package:campus_on/data/repositories/mock_guide_repository.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/domain/repositories/read_result.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/dining/dining_menu_screen.dart';
import 'package:campus_on/presentation/calendar/academic_calendar_screen.dart';
import 'package:campus_on/presentation/search/search_screen.dart';
import 'package:campus_on/presentation/providers/academic_calendar_providers.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:campus_on/presentation/shared/widgets/read_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Dining extends MockDiningRepository {
  bool offline = true;
  bool cached = false;
  int calls = 0;
  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    calls++;
    if (offline && !cached) throw const OfflineDataUnavailable();
    return RepositoryList([
      const CafeteriaMenu(
          id: 'a',
          nameKo: 'Cafeteria',
          nameEn: 'Cafeteria',
          campus: Campus.seunghak,
          meals: [],
          status: DiningAvailability.unpublished)
    ], fromCache: offline);
  }
}

class _Guides extends MockGuideRepository {
  bool fail = true;
  int calls = 0;
  @override
  Future<List<AdminGuideItem>> search(String query) async {
    calls++;
    if (fail) throw const OfflineDataUnavailable();
    return super.search(query);
  }
}

class _Facilities extends MockFacilityRepository {
  @override
  Future<List<Facility>> search(String query) async =>
      throw const OfflineDataUnavailable();
}

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> mount(
      WidgetTester tester, Widget screen, List<Override> overrides) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides
        ],
        child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: screen)));
    await settle(tester);
  }

  AppLocalizations labels(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  testWidgets(
      'uncached dining failure is not unpublished; retry actually rereads',
      (tester) async {
    final repo = _Dining();
    await mount(tester, const DiningMenuScreen(),
        [diningRepositoryProvider.overrideWithValue(repo)]);
    final l = labels(tester);
    expect(find.text(l.data_offline_unavailable), findsOneWidget);
    expect(find.text(l.dining_unpublished), findsNothing);
    repo.offline = false;
    await tester.tap(find.text(l.common_retry));
    await settle(tester);
    expect(repo.calls, 2);
    expect(find.text(l.data_offline_unavailable), findsNothing);
    expect(find.text(l.dining_unpublished), findsOneWidget);
  });
  testWidgets(
      'cached dining retains content and banner disappears after refresh',
      (tester) async {
    final repo = _Dining()..cached = true;
    await mount(tester, const DiningMenuScreen(),
        [diningRepositoryProvider.overrideWithValue(repo)]);
    final l = labels(tester);
    expect(find.text(l.data_cached), findsOneWidget);
    expect(find.text('Cafeteria'), findsOneWidget);
    repo.offline = false;
    await tester.tap(find.text(l.common_retry));
    await settle(tester);
    expect(find.text(l.data_cached), findsNothing);
    expect(repo.calls, 2);
  });
  testWidgets('offline calendar error differs from a confirmed empty schedule',
      (tester) async {
    var fail = true;
    await mount(tester, const AcademicCalendarScreen(), [
      academicEventsProvider.overrideWith((ref) async {
        if (fail) throw const OfflineDataUnavailable();
        return [];
      })
    ]);
    final l = labels(tester);
    expect(find.text(l.data_offline_unavailable), findsOneWidget);
    expect(find.text(l.calendar_empty), findsNothing);
    fail = false;
    await tester.tap(find.text(l.common_retry));
    await settle(tester);
    expect(find.text(l.calendar_empty), findsOneWidget);
  });
  testWidgets(
      'partial search keeps successful facilities and retries failed guides',
      (tester) async {
    final guides = _Guides();
    await mount(tester, const SearchScreen(),
        [guideRepositoryProvider.overrideWithValue(guides)]);
    await tester.enterText(find.byType(TextField), 'library');
    await settle(tester);
    final l = labels(tester);
    expect(find.text(l.search_partial_guide), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
    guides.fail = false;
    await tester.tap(find.text(l.common_retry));
    await settle(tester);
    expect(guides.calls, 2);
    expect(find.text(l.search_partial_guide), findsNothing);
  });
  testWidgets('both search sources failing show error, never no results',
      (tester) async {
    await mount(tester, const SearchScreen(), [
      facilityRepositoryProvider.overrideWithValue(_Facilities()),
      guideRepositoryProvider.overrideWithValue(_Guides())
    ]);
    await tester.enterText(find.byType(TextField), 'library');
    await settle(tester);
    final l = labels(tester);
    expect(find.text(l.data_offline_unavailable), findsOneWidget);
    expect(find.text(l.search_empty_noResult('library')), findsNothing);
  });
  testWidgets(
      'filtered cached-empty content cannot claim authoritative absence',
      (tester) async {
    await mount(
        tester,
        Scaffold(
            body: ReadStatusContent(
                data: preserveReadStatus(
                    RepositoryList([1], fromCache: true), <int>[]),
                onRetry: () {},
                child: const Text('No matches'))),
        []);
    expect(find.text('No matches'), findsNothing);
    expect(find.text(labels(tester).data_cached_empty), findsOneWidget);
  });
}
