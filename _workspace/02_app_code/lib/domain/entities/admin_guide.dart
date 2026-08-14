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

/// Item-level icon overrides, keyed by their Material Symbols name.
///
/// Rows normally show their category icon, which makes same-category items
/// (bank / mobile / transit) indistinguishable in the list. Items may therefore
/// name their own icon; the lookup is a fixed map rather than a raw code point
/// so Firestore can carry `icon` as a plain string and the icon font still
/// tree-shakes correctly (const [IconData] only).
const Map<String, IconData> _guideIcons = {
  'account_balance': Symbols.account_balance,
  'sim_card': Symbols.sim_card,
  'smartphone': Symbols.smartphone,
  'directions_transit': Symbols.directions_transit,
  'credit_card': Symbols.credit_card,
  'contactless': Symbols.contactless,
  'payments': Symbols.payments,
  'receipt_long': Symbols.receipt_long,
  'help': Symbols.help,
  'info': Symbols.info,
  'storefront': Symbols.storefront,
  'location_on': Symbols.location_on,
  'swap_horiz': Symbols.swap_horiz,
  'lightbulb': Symbols.lightbulb,
  'event_repeat': Symbols.event_repeat,
  'format_list_numbered': Symbols.format_list_numbered,
  'computer': Symbols.computer,
  'badge': Symbols.badge,
  'school': Symbols.school,
  'menu_book': Symbols.menu_book,
  'compare_arrows': Symbols.compare_arrows,
};

/// Resolves a Material Symbols name to its icon, or null when unknown/absent.
IconData? guideIconFromName(String? name) =>
    name == null ? null : _guideIcons[name];

/// Locale pick with fallback to the other language when the primary is blank.
String _pickText(String ko, String en, Locale l) {
  final primary = l.languageCode == 'ko' ? ko : en;
  if (primary.trim().isNotEmpty) return primary;
  return l.languageCode == 'ko' ? en : ko;
}

/// Same as [_pickText] for lists — falls back when the primary list is empty.
List<String> _pickTextList(List<String> ko, List<String> en, Locale l) {
  final primary = l.languageCode == 'ko' ? ko : en;
  if (primary.isNotEmpty) return primary;
  return l.languageCode == 'ko' ? en : ko;
}

List<String> _strList(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? const [];

/// External / related link shown in the S7 "Links & Locations" section.
@immutable
class GuideLink {
  const GuideLink({
    required this.labelKo,
    required this.labelEn,
    required this.url,
    this.descriptionKo,
    this.descriptionEn,
    this.iconName,
  });

  final String labelKo;
  final String labelEn;
  final String url;

  /// Optional one-liner under the label (what the page actually covers).
  final String? descriptionKo;
  final String? descriptionEn;

  /// Optional row icon (see [guideIconFromName]); defaults to the link glyph.
  /// Used e.g. by "find a nearby store" rows that open an external map search.
  final String? iconName;

  String label(Locale l) {
    final s = _pickText(labelKo, labelEn, l);
    return s.trim().isNotEmpty ? s : url;
  }

  String? description(Locale l) {
    final s = _pickText(descriptionKo ?? '', descriptionEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  factory GuideLink.fromJson(Map<String, dynamic> j) => GuideLink(
        labelKo: (j['label_ko'] ?? '') as String,
        labelEn: (j['label_en'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        descriptionKo: j['description_ko'] as String?,
        descriptionEn: j['description_en'] as String?,
        iconName: j['icon'] as String?,
      );
}

/// A titled block inside a [GuideSection] — a short heading plus its bullet
/// lines (e.g. "추천 대상" + who it suits, or "ARC가 아직 없나요?" + what to do).
@immutable
class GuideNote {
  const GuideNote({
    required this.titleKo,
    required this.titleEn,
    this.linesKo = const [],
    this.linesEn = const [],
  });

  final String titleKo;
  final String titleEn;
  final List<String> linesKo;
  final List<String> linesEn;

  String title(Locale l) => _pickText(titleKo, titleEn, l);
  List<String> lines(Locale l) => _pickTextList(linesKo, linesEn, l);

  factory GuideNote.fromJson(Map<String, dynamic> j) => GuideNote(
        titleKo: (j['title_ko'] ?? '') as String,
        titleEn: (j['title_en'] ?? '') as String,
        linesKo: _strList(j['lines_ko']),
        linesEn: _strList(j['lines_en']),
      );
}

/// An item-specific extra section, rendered with the same section card as the
/// fixed template ones (between "steps" and "good to know").
///
/// The fixed S7 template covers what every guide has; some items need their own
/// topics on top — mobile plans, for instance, need prepaid vs. postpaid and an
/// "with/without ARC" helper. Those carry their own title here instead of an
/// l10n key, so new topics are pure content (mock fixture or Firestore doc) and
/// need no screen changes.
@immutable
class GuideSection {
  const GuideSection({
    required this.titleKo,
    required this.titleEn,
    this.iconName,
    this.bodyKo,
    this.bodyEn,
    this.stepsKo = const [],
    this.stepsEn = const [],
    this.notes = const [],
    this.noticeKo,
    this.noticeEn,
    this.noticeIconName,
    this.footnoteKo,
    this.footnoteEn,
  });

  final String titleKo;
  final String titleEn;

  /// Section header icon (see [guideIconFromName]); defaults to the info glyph.
  final String? iconName;

  /// Lead paragraph(s). Use `\n\n` between paragraphs.
  final String? bodyKo;
  final String? bodyEn;

  /// Numbered steps, drawn with the same circles as the main "steps" section —
  /// for items whose flow splits into several named procedures (e.g. a transit
  /// card's "how to buy" vs. "how to recharge").
  final List<String> stepsKo;
  final List<String> stepsEn;

  final List<GuideNote> notes;

  /// Caveat rendered as a small tinted card at the end of the section.
  final String? noticeKo;
  final String? noticeEn;

  /// Glyph for that card (see [guideIconFromName]); defaults to the warning
  /// sign. Sections whose card is informative rather than cautionary — "who is
  /// this for?", "the short version" — name a neutral icon instead.
  final String? noticeIconName;

  /// Muted small print closing the section, same treatment as the checklist's
  /// note: the "there are other sub-types too" kind of caveat that would read
  /// as another bullet if it sat in [notes].
  final String? footnoteKo;
  final String? footnoteEn;

  String title(Locale l) => _pickText(titleKo, titleEn, l);

  List<String> steps(Locale l) => _pickTextList(stepsKo, stepsEn, l);

  String? body(Locale l) {
    final s = _pickText(bodyKo ?? '', bodyEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  String? notice(Locale l) {
    final s = _pickText(noticeKo ?? '', noticeEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  String? footnote(Locale l) {
    final s = _pickText(footnoteKo ?? '', footnoteEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  factory GuideSection.fromJson(Map<String, dynamic> j) => GuideSection(
        titleKo: (j['title_ko'] ?? '') as String,
        titleEn: (j['title_en'] ?? '') as String,
        iconName: j['icon'] as String?,
        bodyKo: j['body_ko'] as String?,
        bodyEn: j['body_en'] as String?,
        stepsKo: _strList(j['steps_ko']),
        stepsEn: _strList(j['steps_en']),
        notes: (j['notes'] as List?)
                ?.map((e) =>
                    GuideNote.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        noticeKo: j['notice_ko'] as String?,
        noticeEn: j['notice_en'] as String?,
        noticeIconName: j['notice_icon'] as String?,
        footnoteKo: j['footnote_ko'] as String?,
        footnoteEn: j['footnote_en'] as String?,
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
    this.detailTitleKo,
    this.detailTitleEn,
    this.summaryKo,
    this.summaryEn,
    this.overviewKo,
    this.overviewEn,
    this.checklistKo = const [],
    this.checklistEn = const [],
    this.checklistOptionalKo = const [],
    this.checklistOptionalEn = const [],
    this.checklistOptionalTitleKo,
    this.checklistOptionalTitleEn,
    this.checklistNoteKo,
    this.checklistNoteEn,
    this.stepsKo = const [],
    this.stepsEn = const [],
    this.topSections = const [],
    this.sections = const [],
    this.tipsKo = const [],
    this.tipsEn = const [],
    this.phrases = const [],
    this.links = const [],
    this.relatedFacilityIds = const [],
    this.durationKo,
    this.durationEn,
    this.difficulty,
    this.iconName,
    this.status = GuideStatus.comingSoon,
  });

  final String id;
  final GuideCategory categoryId;
  final String titleKo;
  final String titleEn;

  /// Heading for the detail screen when it should read fuller than the list
  /// row (e.g. list "교통카드" → detail "교통카드 구매 및 충전"). Falls back to [title].
  final String? detailTitleKo;
  final String? detailTitleEn;

  final String? summaryKo;
  final String? summaryEn;

  // Section 1 — overview.
  final String? overviewKo;
  final String? overviewEn;

  /// Sections rendered directly under the overview, ahead of the checklist —
  /// for items whose first thing to say is a precondition rather than a packing
  /// list (e.g. "when should I apply?" on the stay-extension guide). Everything
  /// else goes in [sections], which renders after the steps.
  final List<GuideSection> topSections;

  // Section 2 — checklist (what to prepare).
  final List<String> checklistKo;
  final List<String> checklistEn;

  /// Second, softer checklist group ("you may also need") shown under the main
  /// one — items that only some applicants are asked for.
  final List<String> checklistOptionalKo;
  final List<String> checklistOptionalEn;

  /// Heading for that second group when the generic l10n one ("경우에 따라 필요할 수
  /// 있어요") is too vague — e.g. the stay-extension guide, where what you are
  /// asked for hangs specifically on your status of stay.
  final String? checklistOptionalTitleKo;
  final String? checklistOptionalTitleEn;

  /// Caveat rendered under the checklist (e.g. "requirements differ per bank").
  final String? checklistNoteKo;
  final String? checklistNoteEn;

  // Section 3 — steps.
  final List<String> stepsKo;
  final List<String> stepsEn;

  // Section 3.5 — item-specific extra sections (rendered after the steps).
  final List<GuideSection> sections;

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

  /// Row icon override for the list (see [guideIconFromName]).
  final String? iconName;

  final GuideStatus status;

  bool get isComingSoon => status == GuideStatus.comingSoon;

  /// Icon for list rows — the item's own if it names one, else its category's.
  IconData get icon => guideIconFromName(iconName) ?? categoryId.icon;

  String _pick(String ko, String en, Locale l) => _pickText(ko, en, l);

  String title(Locale l) => _pick(titleKo, titleEn, l);

  /// Detail-screen heading — [detailTitle] when set, otherwise [title].
  String detailTitle(Locale l) {
    final s = _pick(detailTitleKo ?? '', detailTitleEn ?? '', l);
    return s.trim().isNotEmpty ? s : title(l);
  }

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
  List<String> checklistOptional(Locale l) =>
      _pickList(checklistOptionalKo, checklistOptionalEn, l);
  List<String> steps(Locale l) => _pickList(stepsKo, stepsEn, l);
  List<String> tips(Locale l) => _pickList(tipsKo, tipsEn, l);

  String? checklistOptionalTitle(Locale l) {
    final s = _pick(checklistOptionalTitleKo ?? '', checklistOptionalTitleEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  String? checklistNote(Locale l) {
    final s = _pick(checklistNoteKo ?? '', checklistNoteEn ?? '', l);
    return s.trim().isNotEmpty ? s : null;
  }

  List<String> _pickList(List<String> ko, List<String> en, Locale l) =>
      _pickTextList(ko, en, l);

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
      checklistOptionalKo.isEmpty &&
      checklistOptionalEn.isEmpty &&
      stepsKo.isEmpty &&
      stepsEn.isEmpty &&
      topSections.isEmpty &&
      sections.isEmpty &&
      tipsKo.isEmpty &&
      tipsEn.isEmpty &&
      phrases.isEmpty &&
      links.isEmpty &&
      relatedFacilityIds.isEmpty;

  factory AdminGuideItem.fromJson(Map<String, dynamic> j) {
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminGuideItem(
      id: j['id'] as String,
      categoryId:
          GuideCategory.fromId((j['categoryId'] ?? 'immigration') as String),
      titleKo: (j['title_ko'] ?? '') as String,
      titleEn: (j['title_en'] ?? '') as String,
      detailTitleKo: j['detail_title_ko'] as String?,
      detailTitleEn: j['detail_title_en'] as String?,
      summaryKo: j['summary_ko'] as String?,
      summaryEn: j['summary_en'] as String?,
      overviewKo: j['overview_ko'] as String?,
      overviewEn: j['overview_en'] as String?,
      checklistKo: _strList(j['checklist_ko']),
      checklistEn: _strList(j['checklist_en']),
      checklistOptionalKo: _strList(j['checklist_optional_ko']),
      checklistOptionalEn: _strList(j['checklist_optional_en']),
      checklistOptionalTitleKo: j['checklist_optional_title_ko'] as String?,
      checklistOptionalTitleEn: j['checklist_optional_title_en'] as String?,
      checklistNoteKo: j['checklist_note_ko'] as String?,
      checklistNoteEn: j['checklist_note_en'] as String?,
      stepsKo: _strList(j['steps_ko']),
      stepsEn: _strList(j['steps_en']),
      topSections: (j['top_sections'] as List?)
              ?.map((e) =>
                  GuideSection.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      sections: (j['sections'] as List?)
              ?.map((e) =>
                  GuideSection.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      tipsKo: _strList(j['tips_ko']),
      tipsEn: _strList(j['tips_en']),
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
      iconName: j['icon'] as String?,
      status: (j['status'] == 'published')
          ? GuideStatus.published
          : GuideStatus.comingSoon,
    );
  }
}
