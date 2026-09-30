import 'dart:async';
import 'package:campus_on/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  Widget app(Future<SharedPreferences> Function() initialize) => AppBootstrap(
        initialize: initialize,
        timeout: const Duration(seconds: 1),
        appBuilder: (_) => const MaterialApp(home: Text('App ready')),
      );
  testWidgets('initialization failure shows retry and can recover',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(() async {
      if (++calls == 1) throw StateError('platform failed');
      return prefs;
    }));
    await tester.pumpAndSettle();
    expect(find.text('Could not start the app. Please try again.'),
        findsOneWidget);
    expect(find.text('App ready'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('App ready'), findsOneWidget);
  });
  testWidgets(
      'timeout is bounded and retry reuses the pending native operation',
      (tester) async {
    var calls = 0;
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(app(() {
      calls++;
      return pending.future;
    }));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(prefs);
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
  });
  testWidgets(
      'late native failure after timeout is handled and next retry starts again',
      (tester) async {
    var calls = 0;
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(
        app(() => ++calls == 1 ? pending.future : Future.value(prefs)));
    await tester.pump(const Duration(seconds: 2));
    pending.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('App ready'), findsOneWidget);
  });
  testWidgets('disposed bootstrap ignores pending completion', (tester) async {
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(app(() => pending.future));
    await tester.pumpWidget(const SizedBox());
    pending.complete(prefs);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
