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
//
// Every guide is read back through AdminGuideItem.fromJson and compared field
// by field against the entity it came from, so a field added to the entity but
// forgotten here fails the run instead of silently dropping content from the
// seed. To inspect the output before it lands on the checked-in files, send it
// somewhere else first:
//
//   flutter test --dart-define=SEED_OUT=<dir> tool/firestore_seed/export_seed_test.dart

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

    // Round-trip guard: whatever we are about to write must rebuild the exact
    // entity it came from. Runs before the files are touched, so a lossy
    // serializer aborts the export instead of truncating the seed.
    for (final g in MockData.guideItems) {
      expect(
        _dumpGuide(AdminGuideItem.fromJson({...guides[g.id]!, 'id': g.id})),
        equals(_dumpGuide(g)),
        reason: 'export lost or changed data for "${g.id}"',
      );
    }

    const dir = String.fromEnvironment('SEED_OUT',
        defaultValue: 'tool/firestore_seed');
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
    'detail_title_ko': g.detailTitleKo,
    'detail_title_en': g.detailTitleEn,
    'summary_ko': g.summaryKo,
    'summary_en': g.summaryEn,
    'icon': g.iconName,
    'overview_ko': g.overviewKo,
    'overview_en': g.overviewEn,
    'top_sections': g.topSections.map(_sectionToJson).toList(),
    'checklist_title_ko': g.checklistTitleKo,
    'checklist_title_en': g.checklistTitleEn,
    'checklist_ko': g.checklistKo,
    'checklist_en': g.checklistEn,
    'checklist_optional_title_ko': g.checklistOptionalTitleKo,
    'checklist_optional_title_en': g.checklistOptionalTitleEn,
    'checklist_optional_ko': g.checklistOptionalKo,
    'checklist_optional_en': g.checklistOptionalEn,
    'checklist_note_ko': g.checklistNoteKo,
    'checklist_note_en': g.checklistNoteEn,
    'steps_ko': g.stepsKo,
    'steps_en': g.stepsEn,
    'sections': g.sections.map(_sectionToJson).toList(),
    'tips_ko': g.tipsKo,
    'tips_en': g.tipsEn,
    'phrases': [
      for (final p in g.phrases) {'ko': p.ko, 'en': p.en},
    ],
    'links': [
      for (final l in g.links)
        _compact({
          'label_ko': l.labelKo,
          'label_en': l.labelEn,
          'url': l.url,
          'description_ko': l.descriptionKo,
          'description_en': l.descriptionEn,
          'icon': l.iconName,
        }),
    ],
    'relatedFacilityIds': g.relatedFacilityIds,
    if (meta.isNotEmpty) 'meta': meta,
    'status': g.status.name,
  });
}

/// Inverse of [GuideSection.fromJson]; shared by `top_sections` and `sections`.
Map<String, dynamic> _sectionToJson(GuideSection s) => _compact({
      'title_ko': s.titleKo,
      'title_en': s.titleEn,
      'icon': s.iconName,
      'body_ko': s.bodyKo,
      'body_en': s.bodyEn,
      'steps_ko': s.stepsKo,
      'steps_en': s.stepsEn,
      'links': [
        for (final l in s.links)
          _compact({
            'label_ko': l.labelKo,
            'label_en': l.labelEn,
            'url': l.url,
            'description_ko': l.descriptionKo,
            'description_en': l.descriptionEn,
            'icon': l.iconName,
          }),
      ],
      'notes': [
        for (final n in s.notes)
          _compact({
            'title_ko': n.titleKo,
            'title_en': n.titleEn,
            'lines_ko': n.linesKo,
            'lines_en': n.linesEn,
          }),
      ],
      'notice_ko': s.noticeKo,
      'notice_en': s.noticeEn,
      'notice_icon': s.noticeIconName,
      'footnote_ko': s.footnoteKo,
      'footnote_en': s.footnoteEn,
    });

/// Canonical text of every field [AdminGuideItem] exposes, used by the
/// round-trip guard above. Reads the entity's own getters rather than the JSON,
/// so a key the serializer never emitted shows up as a difference here.
String _dumpGuide(AdminGuideItem g) =>
    const JsonEncoder.withIndent('  ').convert({
      'categoryId': g.categoryId.name,
      'titleKo': g.titleKo,
      'titleEn': g.titleEn,
      'detailTitleKo': g.detailTitleKo,
      'detailTitleEn': g.detailTitleEn,
      'summaryKo': g.summaryKo,
      'summaryEn': g.summaryEn,
      'iconName': g.iconName,
      'overviewKo': g.overviewKo,
      'overviewEn': g.overviewEn,
      'checklistTitleKo': g.checklistTitleKo,
      'checklistTitleEn': g.checklistTitleEn,
      'checklistKo': g.checklistKo,
      'checklistEn': g.checklistEn,
      'checklistOptionalTitleKo': g.checklistOptionalTitleKo,
      'checklistOptionalTitleEn': g.checklistOptionalTitleEn,
      'checklistOptionalKo': g.checklistOptionalKo,
      'checklistOptionalEn': g.checklistOptionalEn,
      'checklistNoteKo': g.checklistNoteKo,
      'checklistNoteEn': g.checklistNoteEn,
      'stepsKo': g.stepsKo,
      'stepsEn': g.stepsEn,
      'topSections': g.topSections.map(_dumpSection).toList(),
      'sections': g.sections.map(_dumpSection).toList(),
      'tipsKo': g.tipsKo,
      'tipsEn': g.tipsEn,
      'phrases': [
        for (final p in g.phrases) {'ko': p.ko, 'en': p.en},
      ],
      'links': [
        for (final l in g.links)
          {
            'labelKo': l.labelKo,
            'labelEn': l.labelEn,
            'url': l.url,
            'descriptionKo': l.descriptionKo,
            'descriptionEn': l.descriptionEn,
            'iconName': l.iconName,
          },
      ],
      'relatedFacilityIds': g.relatedFacilityIds,
      'durationKo': g.durationKo,
      'durationEn': g.durationEn,
      'difficulty': g.difficulty,
      'status': g.status.name,
    });

Map<String, dynamic> _dumpSection(GuideSection s) => {
      'titleKo': s.titleKo,
      'titleEn': s.titleEn,
      'iconName': s.iconName,
      'bodyKo': s.bodyKo,
      'bodyEn': s.bodyEn,
      'stepsKo': s.stepsKo,
      'stepsEn': s.stepsEn,
      'links': [
        for (final l in s.links)
          {
            'labelKo': l.labelKo,
            'labelEn': l.labelEn,
            'url': l.url,
            'descriptionKo': l.descriptionKo,
            'descriptionEn': l.descriptionEn,
            'iconName': l.iconName,
          },
      ],
      'notes': [
        for (final n in s.notes)
          {
            'titleKo': n.titleKo,
            'titleEn': n.titleEn,
            'linesKo': n.linesKo,
            'linesEn': n.linesEn,
          },
      ],
      'noticeKo': s.noticeKo,
      'noticeEn': s.noticeEn,
      'noticeIconName': s.noticeIconName,
      'footnoteKo': s.footnoteKo,
      'footnoteEn': s.footnoteEn,
    };

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
