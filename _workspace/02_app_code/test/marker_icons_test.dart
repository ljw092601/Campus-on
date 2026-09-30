import 'package:campus_on/domain/entities/facility.dart';
import 'package:campus_on/presentation/map/widgets/marker_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('failed marker assets are not cached and can be loaded on retry',
      (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (_) async => null);
    try {
      await expectLater(CategoryMarkerIcons.load(), throwsA(anything));
    } finally {
      messenger.setMockMessageHandler('flutter/assets', null);
    }
    final icons = await tester.runAsync(CategoryMarkerIcons.load);
    expect(icons!.keys, containsAll(FacilityCategory.values));
    expect(await CategoryMarkerIcons.load(), same(icons));
  });
}
