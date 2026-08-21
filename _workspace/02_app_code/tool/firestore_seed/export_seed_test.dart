// Regenerates facilities.seed.json + guide_items.seed.json from MockData so the
// Firestore seed can never drift from the in-app fixtures (single source of
// truth = lib/data/mock/mock_data.dart).
//
// Lives under tool/ (not test/) so the default `flutter test` run never
// executes it; run explicitly from the project root when mock data changes:
//
//   flutter test tool/firestore_seed/export_seed_test.dart
//   node tool/firestore_seed/seed.mjs --overwrite
//
// Runs via the flutter_test harness because the entities import Flutter
// (Locale/IconData), which plain `dart run` cannot load.
//
// Emitted docs omit `id` (the JSON key IS the Firestore doc id — see
// firestore_paths.dart) and `updatedAt` (stamped server-side by seed.mjs), and
// drop null/empty fields so absent keys exercise the fromJson defaults.

import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export MockData to Firestore seed JSON', () {
    final facilities = <String, Map<String, dynamic>>{
      for (final f in MockData.facilities)
        f.id: _compact(f.toJson()..remove('id')..remove('updatedAt')),
    };

    final guides = <String, Map<String, dynamic>>{
      for (final g in MockData.guideItems) g.id: _guideToJson(g),
    };

    // Doc id == facilityId (same key convention as facilities).
    final floors = <String, Map<String, dynamic>>{
      for (final b in MockData.buildingFloors)
        b.facilityId: _compact(b.toJson()..remove('facilityId')),
    };

    const dir = 'tool/firestore_seed';
    _writeJson('$dir/facilities.seed.json', facilities);
    _writeJson('$dir/guide_items.seed.json', guides);
    _writeJson('$dir/building_floors.seed.json', floors);

    expect(facilities, hasLength(48));
    expect(floors, hasLength(34));
    expect(
      floors.values.fold<int>(0, (n, d) => n + (d['floors'] as List).length),
      249,
    );
    expect(guides, isNotEmpty);
    // Every floor doc must belong to a facility that advertises it.
    final byId = {for (final f in MockData.facilities) f.id: f};
    for (final id in floors.keys) {
      expect(byId[id]?.hasFloorInfo, isTrue, reason: 'orphan floors doc: $id');
    }
    // …and every hasFloorInfo facility must have a floors doc.
    for (final f in MockData.facilities.where((f) => f.hasFloorInfo)) {
      expect(floors.containsKey(f.id), isTrue,
          reason: 'missing floors doc: ${f.id}');
    }
  });
}

/// Inverse of [AdminGuideItem.fromJson] (the entity is read-only in app code,
/// so serialization lives with the seed tooling that needs it).
Map<String, dynamic> _guideToJson(AdminGuideItem g) {
  final meta = _compact({
    'durationText_ko': g.durationKo,
    'durationText_en': g.durationEn,
    'difficulty': g.difficulty,
  });
  return _compact({
    'categoryId': g.categoryId.name,
    'title_ko': g.titleKo,
    'title_en': g.titleEn,
    'summary_ko': g.summaryKo,
    'summary_en': g.summaryEn,
    'overview_ko': g.overviewKo,
    'overview_en': g.overviewEn,
    'checklist_ko': g.checklistKo,
    'checklist_en': g.checklistEn,
    'steps_ko': g.stepsKo,
    'steps_en': g.stepsEn,
    'links': [
      for (final l in g.links)
        {'label_ko': l.labelKo, 'label_en': l.labelEn, 'url': l.url},
    ],
    'relatedFacilityIds': g.relatedFacilityIds,
    if (meta.isNotEmpty) 'meta': meta,
    'status': g.status.name,
  });
}

/// Drops null values and empty lists/strings so seed docs stay minimal.
Map<String, dynamic> _compact(Map<String, dynamic> m) => {
      for (final e in m.entries)
        if (e.value != null &&
            (e.value is! String || (e.value as String).isNotEmpty) &&
            (e.value is! List || (e.value as List).isNotEmpty))
          e.key: e.value,
    };

void _writeJson(String path, Map<String, dynamic> data) {
  const encoder = JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(data)}\n');
}
