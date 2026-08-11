import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Admin guide categories — the 6 from UX doc §8 (includes emergency).
enum GuideCategory {
  immigration,
  housing,
  living,
  health,
  school,
  emergency;

  static GuideCategory fromId(String id) => GuideCategory.values
      .firstWhere((e) => e.name == id, orElse: () => GuideCategory.immigration);

  IconData get icon {
    switch (this) {
      case GuideCategory.immigration:
        return Symbols.badge;
      case GuideCategory.housing:
        return Symbols.home;
      case GuideCategory.living:
        return Symbols.account_balance;
      case GuideCategory.health:
        return Symbols.local_hospital;
      case GuideCategory.school:
        return Symbols.school;
      case GuideCategory.emergency:
        return Symbols.sos;
    }
  }
}

enum GuideStatus { published, comingSoon }

/// External / related link shown in the S7 "Links & Locations" section.
@immutable
class GuideLink {
  const GuideLink({
    required this.labelKo,
    required this.labelEn,
    required this.url,
  });

  final String labelKo;
  final String labelEn;
  final String url;

  String label(Locale l) {
    final primary = l.languageCode == 'ko' ? labelKo : labelEn;
    if (primary.trim().isNotEmpty) return primary;
    final other = l.languageCode == 'ko' ? labelEn : labelKo;
    return other.trim().isNotEmpty ? other : url;
  }

  factory GuideLink.fromJson(Map<String, dynamic> j) => GuideLink(
        labelKo: (j['label_ko'] ?? '') as String,
        labelEn: (j['label_en'] ?? '') as String,
        url: (j['url'] ?? '') as String,
      );
}

/// A short phrase pair shown in the S7 "Useful phrases" section — the Korean
/// sentence to say plus its English meaning. Both lines are always rendered
/// (the Korean line is what the user shows/reads at the counter), so this is
/// deliberately not locale-switched like the other fields.
@immutable
class GuidePhrase {
  const GuidePhrase({required this.ko, required this.en});

  final String ko;
  final String en;

  factory GuidePhrase.fromJson(Map<String, dynamic> j) => GuidePhrase(
        ko: (j['ko'] ?? '') as String,
        en: (j['en'] ?? '') as String,
      );
}

/// Admin guide item — full sectioned content (UX doc §8 AdminGuideItem).
///
/// Sections follow the fixed S7 template: overview → checklist → steps →
/// links/locations. Items may carry [GuideStatus.comingSoon] while the content
/// is a placeholder; the loading + rendering path is complete regardless (the
/// screen shows the standard "content coming soon" copy per section).
@immutable
class AdminGuideItem {
  const AdminGuideItem({
    required this.id,
    required this.categoryId,
    required this.titleKo,
    required this.titleEn,
    this.summaryKo,
    this.summaryEn,
    this.overviewKo,
    this.overviewEn,
    this.checklistKo = const [],
    this.checklistEn = const [],
    this.checklistNoteKo,
    this.checklistNoteEn,
    this.stepsKo = const [],
    this.stepsEn = const [],
    this.tipsKo = const [],
    this.tipsEn = const [],
    this.phrases = const [],
    this.links = const [],
    this.relatedFacilityIds = const [],
    this.durationKo,
    this.durationEn,
    this.difficulty,
    this.status = GuideStatus.comingSoon,
  });

  final String id;
  final GuideCategory categoryId;
  final String titleKo;
  final String titleEn;
  final String? summaryKo;
  final String? summaryEn;

  // Section 1 — overview.
  final String? overviewKo;
  final String? overviewEn;

  // Section 2 — checklist (what to prepare).
  final List<String> checklistKo;
  final List<String> checklistEn;

  /// Caveat rendered under the checklist (e.g. "requirements differ per bank").
  final String? checklistNoteKo;
  final String? checklistNoteEn;

  // Section 3 — steps.
  final List<String> stepsKo;
  final List<String> stepsEn;

  // Section 4 — good to know (tips).
  final List<String> tipsKo;
  final List<String> tipsEn;

  // Section 5 — useful phrases (ko + en shown together).
  final List<GuidePhrase> phrases;

  // Section 6 — links + related locations.
  final List<GuideLink> links;

  /// Related campus locations. S7 renders one card per id; tapping a card
  /// deep-links to `/map?focus=<that id>` (single-facility focus). The router
  /// also accepts a comma-joined `focus` list for multi-marker fitBounds
  /// (UX doc §3), used by other entry points.
  final List<String> relatedFacilityIds;

  // Optional meta (durationText / difficulty 1–3).
  final String? durationKo;
  final String? durationEn;
  final int? difficulty;

  final GuideStatus status;

  bool get isComingSoon => status == GuideStatus.comingSoon;

  String _pick(String ko, String en, Locale l) {
    final primary = l.languageCode == 'ko' ? ko : en;
    if (primary.trim().isNotEmpty) return primary;
    return l.languageCode == 'ko' ? en : ko;
  }

  String title(Locale l) => _pick(titleKo, titleEn, l);

  String? summary(Locale l) {
    final s = _pick(summaryKo ?? '', summaryEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  String? overview(Locale l) {
    final s = _pick(overviewKo ?? '', overviewEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  /// Locale-aware list with fallback to the other language when one is empty.
  List<String> checklist(Locale l) => _pickList(checklistKo, checklistEn, l);
  List<String> steps(Locale l) => _pickList(stepsKo, stepsEn, l);
  List<String> tips(Locale l) => _pickList(tipsKo, tipsEn, l);

  String? checklistNote(Locale l) {
    final s = _pick(checklistNoteKo ?? '', checklistNoteEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  List<String> _pickList(List<String> ko, List<String> en, Locale l) {
    final primary = l.languageCode == 'ko' ? ko : en;
    if (primary.isNotEmpty) return primary;
    return l.languageCode == 'ko' ? en : ko;
  }

  String? duration(Locale l) {
    final s = _pick(durationKo ?? '', durationEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  /// True when every content section is empty — used to render the whole-screen
  /// "coming soon" state even if [status] was mislabeled.
  bool get hasNoContent =>
      (overviewKo ?? '').trim().isEmpty &&
      (overviewEn ?? '').trim().isEmpty &&
      checklistKo.isEmpty &&
      checklistEn.isEmpty &&
      stepsKo.isEmpty &&
      stepsEn.isEmpty &&
      tipsKo.isEmpty &&
      tipsEn.isEmpty &&
      phrases.isEmpty &&
      links.isEmpty &&
      relatedFacilityIds.isEmpty;

  factory AdminGuideItem.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminGuideItem(
      id: j['id'] as String,
      categoryId:
          GuideCategory.fromId((j['categoryId'] ?? 'immigration') as String),
      titleKo: (j['title_ko'] ?? '') as String,
      titleEn: (j['title_en'] ?? '') as String,
      summaryKo: j['summary_ko'] as String?,
      summaryEn: j['summary_en'] as String?,
      overviewKo: j['overview_ko'] as String?,
      overviewEn: j['overview_en'] as String?,
      checklistKo: strList(j['checklist_ko']),
      checklistEn: strList(j['checklist_en']),
      checklistNoteKo: j['checklist_note_ko'] as String?,
      checklistNoteEn: j['checklist_note_en'] as String?,
      stepsKo: strList(j['steps_ko']),
      stepsEn: strList(j['steps_en']),
      tipsKo: strList(j['tips_ko']),
      tipsEn: strList(j['tips_en']),
      phrases: (j['phrases'] as List?)
              ?.map((e) =>
                  GuidePhrase.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      links: (j['links'] as List?)
              ?.map((e) => GuideLink.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      relatedFacilityIds:
          (j['relatedFacilityIds'] as List?)?.cast<String>() ?? const [],
      durationKo: meta['durationText_ko'] as String?,
      durationEn: meta['durationText_en'] as String?,
      difficulty: (meta['difficulty'] as num?)?.toInt(),
      status: (j['status'] == 'published')
          ? GuideStatus.published
          : GuideStatus.comingSoon,
    );
  }
}
