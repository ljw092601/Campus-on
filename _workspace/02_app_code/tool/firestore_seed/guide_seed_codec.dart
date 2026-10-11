// Serializes guide entities into the Firestore seed document shape. Shared by
// the exporter (export_seed_test.dart), which writes guide_items.seed.json, and
// by test/guide_seed_sync_test.dart, which fails when the checked-in seed no
// longer matches the in-app catalogue.

import 'package:campus_on/data/firestore/firestore_guide_repository.dart'
    show guideSortOrderField;
import 'package:campus_on/domain/entities/admin_guide.dart';

/// Seed documents keyed by guide id (the Firestore document id), each stamped
/// with its catalogue position so the Firestore path can list guides in the
/// same order as the mock data.
Map<String, Map<String, dynamic>> guideSeedDocuments(
        Iterable<AdminGuideItem> items) =>
    {
      for (final (i, g) in items.indexed)
        g.id: {..._guideToJson(g), guideSortOrderField: i},
    };

/// Inverse of [AdminGuideItem.fromJson] (the entity is read-only in app code,
/// so serialization lives with the seed tooling that needs it).
Map<String, dynamic> _guideToJson(AdminGuideItem g) {
  final meta = compactSeedMap({
    'durationText_ko': g.durationKo,
    'durationText_en': g.durationEn,
    'difficulty': g.difficulty,
  });
  return compactSeedMap({
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
      for (final p in g.phrases)
        {'ko': p.ko, 'en': p.en, if (p.i18n.isNotEmpty) 'i18n': p.i18n},
    ],
    'links': [
      for (final l in g.links)
        compactSeedMap({
          'label_ko': l.labelKo,
          'label_en': l.labelEn,
          'url': l.url,
          'description_ko': l.descriptionKo,
          'description_en': l.descriptionEn,
          'icon': l.iconName,
          if (l.i18n.isNotEmpty) 'i18n': l.i18n,
        }),
    ],
    'relatedFacilityIds': g.relatedFacilityIds,
    if (meta.isNotEmpty) 'meta': meta,
    'status': g.status.name,
    // Optional search-only fields; empty lists are dropped by _compact.
    'search_aliases_ko': g.searchAliasesKo,
    'search_aliases_en': g.searchAliasesEn,
    // Chinese/Vietnamese overlay; absent while nothing is translated yet.
    if (g.i18n.isNotEmpty) 'i18n': g.i18n,
  });
}

/// Inverse of [GuideSection.fromJson]; shared by `top_sections` and `sections`.
Map<String, dynamic> _sectionToJson(GuideSection s) => compactSeedMap({
      'title_ko': s.titleKo,
      'title_en': s.titleEn,
      'icon': s.iconName,
      'body_ko': s.bodyKo,
      'body_en': s.bodyEn,
      'steps_ko': s.stepsKo,
      'steps_en': s.stepsEn,
      'links': [
        for (final l in s.links)
          compactSeedMap({
            'label_ko': l.labelKo,
            'label_en': l.labelEn,
            'url': l.url,
            'description_ko': l.descriptionKo,
            'description_en': l.descriptionEn,
            'icon': l.iconName,
            if (l.i18n.isNotEmpty) 'i18n': l.i18n,
          }),
      ],
      'notes': [
        for (final n in s.notes)
          compactSeedMap({
            'title_ko': n.titleKo,
            'title_en': n.titleEn,
            'lines_ko': n.linesKo,
            'lines_en': n.linesEn,
            if (n.i18n.isNotEmpty) 'i18n': n.i18n,
          }),
      ],
      'notice_ko': s.noticeKo,
      'notice_en': s.noticeEn,
      'notice_icon': s.noticeIconName,
      'footnote_ko': s.footnoteKo,
      'footnote_en': s.footnoteEn,
      if (s.i18n.isNotEmpty) 'i18n': s.i18n,
    });

/// Drops null values and empty lists/strings so seed docs stay minimal.
Map<String, dynamic> compactSeedMap(Map<String, dynamic> m) => {
      for (final e in m.entries)
        if (e.value != null &&
            (e.value is! String || (e.value as String).isNotEmpty) &&
            (e.value is! List || (e.value as List).isNotEmpty))
          e.key: e.value,
    };
