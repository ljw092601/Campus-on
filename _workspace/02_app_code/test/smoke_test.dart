import 'package:campus_on/app.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal testable entry point for QA (build config + boot smoke test).
/// Full UI/state tests are added alongside week-3 work.
void main() {
  testWidgets('App boots to the Home tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CampusOnApp(),
      ),
    );
    await tester.pump();

    // Home hub renders its branded title (DONG-A-MATE wordmark).
    expect(
      find.textContaining(RegExp('동아메이트|Dong-A Mate|DONG-A-MATE')),
      findsWidgets,
    );

    // Let the home "upcoming events" mock-calendar fetch (120ms latency)
    // finish so no timer is left pending at teardown.
    await tester.pump(const Duration(seconds: 1));
  });
}
