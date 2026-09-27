import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/mock/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/firestore_seed/guide_seed_codec.dart';

/// The Firestore path reads uploaded documents, never the bundled mock data, so
/// the checked-in seed must be exactly what the exporter would write from the
/// current catalogue. Regenerate with
/// `flutter test tool/firestore_seed/export_seed_test.dart` when this fails.
void main() {
  test('checked-in guide_items.seed.json matches the in-app catalogue', () {
    final onDisk = jsonDecode(
        File('tool/firestore_seed/guide_items.seed.json').readAsStringSync());
    final expected =
        jsonDecode(jsonEncode(guideSeedDocuments(MockData.guideItems)));
    expect((onDisk as Map).keys.toList(), (expected as Map).keys.toList());
    for (final id in expected.keys) {
      expect(onDisk[id], expected[id], reason: 'stale seed document "$id"');
    }
  });
}
