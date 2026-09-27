import '../../core/i18n/app_languages.dart';
import '../../domain/entities/admin_guide.dart';
import 'guide_translations.g.dart';

/// Attaches the Chinese/Vietnamese overlay to the Korean/English guide
/// fixtures. The guide literals themselves never change: a translation is a
/// separate JSON file (`lib/data/i18n/guides_<lang>.json`, generated into
/// `guide_translations.g.dart`), keyed by guide id and mirroring the guide's
/// shape, so translators and the catalogue never edit the same file.
///
/// Missing entries are simply absent — the entity then falls back to English
/// and Korean (see `languageFallback`).
List<AdminGuideItem> applyGuideTranslations(
  List<AdminGuideItem> items, {
  Map<String, Map<String, Object?>> byLanguage = guideTranslationsByLanguage,
}) {
  if (byLanguage.isEmpty) return items;
  return [
    for (final item in items) _withTranslations(item, byLanguage),
  ];
}

/// Per-language tree for one guide, e.g. {'zh': {...}, 'vi': {...}}.
Map<String, Map<String, Object?>> _treesFor(
    String id, Map<String, Object?> byLanguage) {
  final out = <String, Map<String, Object?>>{};
  for (final lang in appLanguageCodes) {
    if (lang == 'ko' || lang == 'en') continue;
    final guides = byLanguage[lang] as Map<String, Object?>?;
    final tree = guides?[id] as Map<String, Object?>?;
    if (tree != null && tree.isNotEmpty) out[lang] = tree;
  }
  return out;
}

const _childKeys = {'top_sections', 'sections', 'links', 'phrases', 'notes'};

/// Scalar and list fields of one tree — the child collections are attached to
/// the child objects instead.
GuideI18n _own(Map<String, Map<String, Object?>> trees) {
  final out = <String, Map<String, Object?>>{};
  for (final e in trees.entries) {
    final fields = <String, Object?>{};
    for (final f in e.value.entries) {
      if (_childKeys.contains(f.key)) continue;
      final v = f.value;
      if (v is String && v.trim().isNotEmpty) {
        fields[f.key] = v;
      } else if (v is List && v.isNotEmpty) {
        fields[f.key] = v.map((x) => x.toString()).toList();
      }
    }
    if (fields.isNotEmpty) out[e.key] = fields;
  }
  return out;
}

/// Trees for child number [i] of collection [key], per language.
Map<String, Map<String, Object?>> _child(
    Map<String, Map<String, Object?>> trees, String key, int i) {
  final out = <String, Map<String, Object?>>{};
  for (final e in trees.entries) {
    final list = e.value[key] as List?;
    if (list == null || i >= list.length) continue;
    final tree = list[i];
    if (tree is Map<String, Object?> && tree.isNotEmpty) out[e.key] = tree;
  }
  return out;
}

AdminGuideItem _withTranslations(
    AdminGuideItem g, Map<String, Object?> byLanguage) {
  final trees = _treesFor(g.id, byLanguage);
  if (trees.isEmpty) return g;
  return AdminGuideItem(
    id: g.id,
    categoryId: g.categoryId,
    titleKo: g.titleKo,
    titleEn: g.titleEn,
    detailTitleKo: g.detailTitleKo,
    detailTitleEn: g.detailTitleEn,
    summaryKo: g.summaryKo,
    summaryEn: g.summaryEn,
    overviewKo: g.overviewKo,
    overviewEn: g.overviewEn,
    checklistTitleKo: g.checklistTitleKo,
    checklistTitleEn: g.checklistTitleEn,
    checklistKo: g.checklistKo,
    checklistEn: g.checklistEn,
    checklistOptionalKo: g.checklistOptionalKo,
    checklistOptionalEn: g.checklistOptionalEn,
    checklistOptionalTitleKo: g.checklistOptionalTitleKo,
    checklistOptionalTitleEn: g.checklistOptionalTitleEn,
    checklistNoteKo: g.checklistNoteKo,
    checklistNoteEn: g.checklistNoteEn,
    stepsKo: g.stepsKo,
    stepsEn: g.stepsEn,
    topSections: [
      for (var i = 0; i < g.topSections.length; i++)
        _section(g.topSections[i], _child(trees, 'top_sections', i)),
    ],
    sections: [
      for (var i = 0; i < g.sections.length; i++)
        _section(g.sections[i], _child(trees, 'sections', i)),
    ],
    tipsKo: g.tipsKo,
    tipsEn: g.tipsEn,
    phrases: [
      for (var i = 0; i < g.phrases.length; i++)
        GuidePhrase(
          ko: g.phrases[i].ko,
          en: g.phrases[i].en,
          i18n: _own(_child(trees, 'phrases', i)),
        ),
    ],
    links: [
      for (var i = 0; i < g.links.length; i++)
        _link(g.links[i], _child(trees, 'links', i)),
    ],
    relatedFacilityIds: g.relatedFacilityIds,
    durationKo: g.durationKo,
    durationEn: g.durationEn,
    difficulty: g.difficulty,
    iconName: g.iconName,
    status: g.status,
    searchAliasesKo: g.searchAliasesKo,
    searchAliasesEn: g.searchAliasesEn,
    i18n: _own(trees),
  );
}

GuideSection _section(
    GuideSection s, Map<String, Map<String, Object?>> trees) {
  if (trees.isEmpty) return s;
  return GuideSection(
    titleKo: s.titleKo,
    titleEn: s.titleEn,
    iconName: s.iconName,
    bodyKo: s.bodyKo,
    bodyEn: s.bodyEn,
    stepsKo: s.stepsKo,
    stepsEn: s.stepsEn,
    links: [
      for (var i = 0; i < s.links.length; i++)
        _link(s.links[i], _child(trees, 'links', i)),
    ],
    notes: [
      for (var i = 0; i < s.notes.length; i++)
        GuideNote(
          titleKo: s.notes[i].titleKo,
          titleEn: s.notes[i].titleEn,
          linesKo: s.notes[i].linesKo,
          linesEn: s.notes[i].linesEn,
          i18n: _own(_child(trees, 'notes', i)),
        ),
    ],
    noticeKo: s.noticeKo,
    noticeEn: s.noticeEn,
    noticeIconName: s.noticeIconName,
    footnoteKo: s.footnoteKo,
    footnoteEn: s.footnoteEn,
    i18n: _own(trees),
  );
}

GuideLink _link(GuideLink l, Map<String, Map<String, Object?>> trees) {
  if (trees.isEmpty) return l;
  return GuideLink(
    labelKo: l.labelKo,
    labelEn: l.labelEn,
    url: l.url,
    descriptionKo: l.descriptionKo,
    descriptionEn: l.descriptionEn,
    iconName: l.iconName,
    i18n: _own(trees),
  );
}
