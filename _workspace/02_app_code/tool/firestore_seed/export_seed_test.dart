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
import 'package:campus_on/data/repositories/mock_academic_calendar_repository.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

import 'guide_seed_codec.dart';
import 'package:campus_on/core/i18n/entity_i18n.dart';

void main() {
  test('export MockData to Firestore seed JSON', () async {
    final facilities = <String, Map<String, dynamic>>{
      for (final f in MockData.facilities)
        f.id: compactSeedMap(f.toJson()..remove('id')..remove('updatedAt')),
    };

    final guides = guideSeedDocuments(MockData.guideItems);

    // Doc id == facilityId (same key convention as facilities).
    final floors = <String, Map<String, dynamic>>{
      for (final b in MockData.buildingFloors)
        b.facilityId: compactSeedMap(b.toJson()..remove('facilityId')),
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

    // Initial content for the admin-entered collections (design doc §7).
    // These seeds are one-time starters only: after the admin sheet goes
    // live it owns the collections, so seed.mjs never prunes them.
    final events = <String, Map<String, dynamic>>{
      for (final e in await MockAcademicCalendarRepository().getEvents())
        e.id: _compact(e.toJson()..remove('id')),
    };
    // Static cafeteria info derived from a weekday mock day (meals stripped;
    // the served slots become `mealTypes`).
    final cafeterias = <String, Map<String, dynamic>>{
      for (final c in await MockDiningRepository()
          .getMenus(DateTime(2026, 9, 7))) // a Monday — all slots present
        c.id: _compact({
          'name_ko': c.nameKo,
          'name_en': c.nameEn,
          'campus': c.campus.name,
          'hours_ko': c.hoursKo,
          'hours_en': c.hoursEn,
          'facilityId': c.facilityId,
          'mealTypes': [for (final m in c.meals) m.type.name],
          // Same `i18n` map the app reads back; absent when untranslated.
          if (entityI18nToJson(c.i18n) != null) 'i18n': entityI18nToJson(c.i18n),
        }),
    };

    const dir = String.fromEnvironment('SEED_OUT',
        defaultValue: 'tool/firestore_seed');
    _writeJson('$dir/facilities.seed.json', facilities);
    _writeJson('$dir/guide_items.seed.json', guides);
    _writeJson('$dir/building_floors.seed.json', floors);
    _writeJson('$dir/academic_events.seed.json', events);
    _writeJson('$dir/cafeterias.seed.json', cafeterias);

    expect(facilities, hasLength(48));
    expect(floors, hasLength(34));
    expect(
      floors.values.fold<int>(0, (n, d) => n + (d['floors'] as List).length),
      249,
    );
    expect(guides, isNotEmpty);
    expect(events, isNotEmpty);
    expect(cafeterias, hasLength(3));
    for (final c in cafeterias.values) {
      expect(c['mealTypes'], isNotEmpty,
          reason: 'cafeteria seed must list its served meal slots');
    }
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
        for (final p in g.phrases) {'ko': p.ko, 'en': p.en, 'i18n': p.i18n},
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
            'i18n': l.i18n,
          },
      ],
      'relatedFacilityIds': g.relatedFacilityIds,
      'durationKo': g.durationKo,
      'durationEn': g.durationEn,
      'difficulty': g.difficulty,
      'status': g.status.name,
      'searchAliasesKo': g.searchAliasesKo,
      'searchAliasesEn': g.searchAliasesEn,
      // The translations belong in the round-trip guard too: without them a
      // codec that dropped an i18n key would lose it from both sides of the
      // comparison and pass (B 03/054 SF-01).
      'i18n': g.i18n,
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
            'i18n': l.i18n,
          },
      ],
      'notes': [
        for (final n in s.notes)
          {
            'titleKo': n.titleKo,
            'titleEn': n.titleEn,
            'linesKo': n.linesKo,
            'linesEn': n.linesEn,
            'i18n': n.i18n,
          },
      ],
      'noticeKo': s.noticeKo,
      'noticeEn': s.noticeEn,
      'noticeIconName': s.noticeIconName,
      'footnoteKo': s.footnoteKo,
      'footnoteEn': s.footnoteEn,
      'i18n': s.i18n,
    };

void _writeJson(String path, Map<String, dynamic> data) {
  const encoder = JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(data)}\n');
}

// Kept from main (297074c): the academic-calendar and cafeteria seed exports
// added there drop null fields through this helper.
Map<String, dynamic> _compact(Map<String, dynamic> m) => {
      for (final e in m.entries)
        if (e.value != null &&
            (e.value is! String || (e.value as String).isNotEmpty) &&
            (e.value is! List || (e.value as List).isNotEmpty))
          e.key: e.value,
    };
