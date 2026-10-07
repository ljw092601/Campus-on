import 'package:campus_on/app.dart' show IntroOverlay;
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/l10n/gen/app_localizations.dart';
import 'package:campus_on/main.dart' as app;
import 'package:campus_on/presentation/dining/dining_menu_screen.dart';
import 'package:campus_on/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Walks the dining screen (mock data) and prints E2E_SHOT checkpoints; the
// host runner (tool/run_map_e2e.py --test showcase) screenshots at each one.
// Not an assertion suite — it only fails if the screen cannot be reached.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dining showcase screenshots', (tester) async {
    Future<void> until(Future<bool> Function() condition, String description,
        {int seconds = 30}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (await condition()) return;
      }
      fail('Timed out: $description');
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 600));
      debugPrint('E2E_SHOT $name');
      // Give the host time to capture before the UI moves on.
      await tester.pump(const Duration(seconds: 4));
    }

    await app.main();
    final sheet = find.descendant(
        of: find.byType(IntroOverlay), matching: find.byType(AnimatedOpacity));
    await until(() async => sheet.evaluate().isNotEmpty, 'intro', seconds: 20);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(IntroOverlay));
    await until(() async => sheet.evaluate().isEmpty, 'intro skipped');

    AppRouter.router.go('/home/dining');
    await until(
        () async => find.byType(DiningMenuScreen).evaluate().isNotEmpty,
        'dining screen');
    await tester.pump(const Duration(seconds: 1));
    final l = AppLocalizations.of(tester.element(find.byType(DiningMenuScreen)));

    await shot('01_seunghak_top');

    // Scroll down through the 승학 cards.
    final scrollable = find.byType(Scrollable).last;
    await tester.drag(scrollable, const Offset(0, -700));
    await shot('02_seunghak_scrolled');
    await tester.drag(scrollable, const Offset(0, -700));
    await shot('03_seunghak_bottom');

    // Switch to 구덕·부민.
    final otherTab = find.text(l.dining_campusGroup_gudeokBumin);
    await tester.ensureVisible(otherTab);
    await tester.tap(otherTab);
    await tester.pump(const Duration(milliseconds: 800));
    await shot('04_gudeok_bumin_top');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
    await shot('05_gudeok_bumin_scrolled');

    // Next day, then the weekend (closed state).
    final next = find.byTooltip(l.dining_nextDay);
    if (next.evaluate().isNotEmpty) {
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 800));
      await shot('06_next_day');
    }
    // Same screens in Korean.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(DiningMenuScreen)));
    await container.read(localeProvider.notifier).setLocale(const Locale('ko'));
    await tester.pump(const Duration(milliseconds: 800));
    final lk = AppLocalizations.of(tester.element(find.byType(DiningMenuScreen)));
    await tester.tap(find.byTooltip(lk.dining_prevDay));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text(lk.dining_campusGroup_seunghak));
    await tester.pump(const Duration(milliseconds: 800));
    await shot('07_ko_seunghak_top');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
    await shot('08_ko_seunghak_scrolled');
    await tester.tap(find.text(lk.dining_campusGroup_gudeokBumin));
    await tester.pump(const Duration(milliseconds: 800));
    await shot('09_ko_gudeok_bumin_top');
    debugPrint('E2E_SHOWCASE_COMPLETE');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
