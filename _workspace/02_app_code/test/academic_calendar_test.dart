import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_on/data/repositories/mock_academic_calendar_repository.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/presentation/calendar/academic_calendar_screen.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';

void main() {
  test('mock events: non-empty, start-sorted, valid ranges, unique ids',
      () async {
    final events = await MockAcademicCalendarRepository().getEvents();

    expect(events, isNotEmpty);
    for (var i = 1; i < events.length; i++) {
      expect(events[i].start.isBefore(events[i - 1].start), isFalse,
          reason: 'events must be sorted by start date');
    }
    for (final e in events) {
      expect(e.endDate.isBefore(e.start), isFalse,
          reason: '${e.id}: end must not precede start');
      expect(e.titleKo, isNotEmpty);
      expect(e.titleEn, isNotEmpty);
    }
    expect({for (final e in events) e.id}.length, events.length,
        reason: 'ids must be unique');
  });

  testWidgets('calendar screen: notice banner, month groups, event rows',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AcademicCalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Sample-data notice and the first month's rows are visible up top
    // (test locale is en; the regex keeps this robust to a ko default).
    expect(
        find.textContaining(RegExp('Sample dates|예시 일정')), findsOneWidget);
    expect(
        find.textContaining(RegExp('Fall course registration|2학기 수강신청')),
        findsOneWidget);

    // Later months exist after scrolling (exam rows carry the exam badge).
    await tester.scrollUntilVisible(
      find.textContaining(RegExp('Midterm exams|중간시험')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining(RegExp('Midterm exams|중간시험')), findsOneWidget);
  });
}
