import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/app_languages.dart';
import '../../core/i18n/entity_i18n.dart';

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
  'call': Symbols.call,
  'local_police': Symbols.local_police,
  'local_fire_department': Symbols.local_fire_department,
  'emergency': Symbols.emergency,
  'translate': Symbols.translate,
  // Added with the 2026-09 guide expansion (part-time work, changes, D-10…).
  'work': Symbols.work,
  'edit_location_alt': Symbols.edit_location_alt,
  'event_busy': Symbols.event_busy,
  'fact_check': Symbols.fact_check,
  'flight_takeoff': Symbols.flight_takeoff,
  'home_work': Symbols.home_work,
  'gavel': Symbols.gavel,
  'warning': Symbols.warning,
};

/// Resolves a Material Symbols name to its icon, or null when unknown/absent.
IconData? guideIconFromName(String? name) =>
    name == null ? null : _guideIcons[name];

/// Per-language text that is not one of the two built-in fields. The shape and
/// the parsing live in `core/i18n/entity_i18n.dart` because the academic
/// calendar carries the same map; keeping one implementation means a document
/// that is safe for one collection is safe for the other.
typedef GuideI18n = EntityI18n;

const GuideI18n _noI18n = noI18n;

/// Text for [l], falling back requested language → English → Korean, so an
/// untranslated field shows the English (or Korean) sentence rather than a
/// blank line.
String _pickText(String ko, String en, Locale l,
        [GuideI18n i18n = _noI18n, String? key]) =>
    pickI18nText(ko, en, l, i18n, key);

/// Same as [_pickText] for lists, but item by item: a translation that carries
/// only some of the lines must not shorten the list, or a reader of that
/// language would silently lose the rest. The length comes from the written
/// ko/en data, and each missing line falls back on its own (감사 05/034 S-6).
List<String> _pickTextList(List<String> ko, List<String> en, Locale l,
    [GuideI18n i18n = _noI18n, String? key]) {
  final chain = languageFallback(l.languageCode);
  List<String> listFor(String code) {
    switch (code) {
      case 'ko':
        return ko;
      case 'en':
        return en;
      default:
        if (key == null) return const [];
        final v = i18n[code]?[key];
        return v is List ? v.whereType<String>().toList() : const [];
    }
  }

  final lists = [for (final code in chain) listFor(code)];
  // Only the written data decides how many lines there are.
  final written = [
    for (var i = 0; i < chain.length; i++)
      if (chain[i] == 'ko' || chain[i] == 'en') lists[i]
  ];
  final length = written.firstWhere((l) => l.isNotEmpty, orElse: () => const []).length;
  if (length == 0) {
    // ko and en are both empty: nothing to anchor to, so take the translation
    // as it stands.
    return lists.firstWhere((l) => l.isNotEmpty, orElse: () => const []);
  }
  return [
    for (var i = 0; i < length; i++)
      lists
              .map((l) => i < l.length ? l[i] : '')
              .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '')
  ];
}

/// Parses the `i18n` map of a document. See `core/i18n/entity_i18n.dart` —
/// the academic calendar parses the same map with the same rules.
GuideI18n _i18nFromJson(dynamic v) => entityI18nFromJson(v);

/// A list of strings from a document, whatever shape the document is in: a
/// number, a map or a missing key gives an empty list, and a non-string item is
/// dropped rather than printed as `{a: 1}`. One hand-edited document used to
/// throw here and, since the repository only catches FirebaseException, take the
/// whole guide list with it (B 03/054 NEW-B-01).
List<String> _strList(dynamic v) => v is List
    ? [for (final e in v) if (e is String) e else if (e is num || e is bool) e.toString()]
    : const [];

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
    this.i18n = _noI18n,
  });

  /// Chinese/Vietnamese label + description (keys `label`, `description`).
  final GuideI18n i18n;

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
    final s = _pickText(labelKo, labelEn, l, i18n, 'label');
    return s.trim().isNotEmpty ? s : url;
  }

  String? description(Locale l) {
    final s = _pickText(
        descriptionKo ?? '', descriptionEn ?? '', l, i18n, 'description');
    return s.trim().isNotEmpty ? s : null;
  }

  factory GuideLink.fromJson(Map<String, dynamic> j) => GuideLink(
        labelKo: (j['label_ko'] ?? '') as String,
        labelEn: (j['label_en'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        descriptionKo: j['description_ko'] as String?,
        descriptionEn: j['description_en'] as String?,
        iconName: j['icon'] as String?,
        i18n: _i18nFromJson(j['i18n']),
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
    this.i18n = _noI18n,
  });

  /// Chinese/Vietnamese note text (keys `title`, `lines`).
  final GuideI18n i18n;

  final String titleKo;
  final String titleEn;
  final List<String> linesKo;
  final List<String> linesEn;

  String title(Locale l) => _pickText(titleKo, titleEn, l, i18n, 'title');
  List<String> lines(Locale l) =>
      _pickTextList(linesKo, linesEn, l, i18n, 'lines');

  factory GuideNote.fromJson(Map<String, dynamic> j) => GuideNote(
        titleKo: (j['title_ko'] ?? '') as String,
        titleEn: (j['title_en'] ?? '') as String,
        linesKo: _strList(j['lines_ko']),
        linesEn: _strList(j['lines_en']),
        i18n: _i18nFromJson(j['i18n']),
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
    this.links = const [],
    this.notes = const [],
    this.noticeKo,
    this.noticeEn,
    this.noticeIconName,
    this.footnoteKo,
    this.footnoteEn,
    this.i18n = _noI18n,
  });

  /// Chinese/Vietnamese section text (keys `title`, `body`, `steps`, `notice`,
  /// `footnote`); its links and notes carry their own maps.
  final GuideI18n i18n;

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

  /// Actions belonging to this section, rendered as link rows in a tinted block
  /// right under the lead paragraph — for sections whose point IS the action
  /// (e.g. "112 — 경찰" carrying a `tel:112` row). Same [GuideLink] as the
  /// item-level links, so `/`-prefixed urls still route in-app.
  final List<GuideLink> links;

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

  String title(Locale l) => _pickText(titleKo, titleEn, l, i18n, 'title');

  List<String> steps(Locale l) =>
      _pickTextList(stepsKo, stepsEn, l, i18n, 'steps');

  String? body(Locale l) {
    final s = _pickText(bodyKo ?? '', bodyEn ?? '', l, i18n, 'body');
    return s.trim().isNotEmpty ? s : null;
  }

  String? notice(Locale l) {
    final s = _pickText(noticeKo ?? '', noticeEn ?? '', l, i18n, 'notice');
    return s.trim().isNotEmpty ? s : null;
  }

  String? footnote(Locale l) {
    final s = _pickText(footnoteKo ?? '', footnoteEn ?? '', l, i18n, 'footnote');
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
        links: (j['links'] as List?)
                ?.map((e) =>
                    GuideLink.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        notes: (j['notes'] as List?)
                ?.whereType<Map>()
                    .map((e) => GuideNote.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        noticeKo: j['notice_ko'] as String?,
        noticeEn: j['notice_en'] as String?,
        noticeIconName: j['notice_icon'] as String?,
        footnoteKo: j['footnote_ko'] as String?,
        footnoteEn: j['footnote_en'] as String?,
        i18n: _i18nFromJson(j['i18n']),
      );
}

/// A short phrase pair shown in the S7 "Useful phrases" section — the Korean
/// sentence to say plus what it means. The Korean line is what the user shows
/// or reads at the counter, so it is never locale-switched; only the meaning
/// line follows the UI language (key `text` in [i18n]).
@immutable
class GuidePhrase {
  const GuidePhrase({required this.ko, required this.en, this.i18n = _noI18n});

  final String ko;
  final String en;

  /// Chinese/Vietnamese meaning (key `text`).
  final GuideI18n i18n;

  /// What the Korean sentence means, in the reader's language.
  String meaning(Locale l) {
    final s = _pickText(ko, en, l, i18n, 'text');
    // Korean readers see the sentence itself as the meaning line, as before.
    return s;
  }

  factory GuidePhrase.fromJson(Map<String, dynamic> j) => GuidePhrase(
        ko: (j['ko'] ?? '') as String,
        en: (j['en'] ?? '') as String,
        i18n: _i18nFromJson(j['i18n']),
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
    this.checklistTitleKo,
    this.checklistTitleEn,
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
    this.searchAliasesKo = const [],
    this.searchAliasesEn = const [],
    this.i18n = _noI18n,
  });

  /// Chinese/Vietnamese text for this guide, attached by the generated mock
  /// overlay or read from a Firestore document's `i18n` map. Keys are the
  /// field names without a language suffix (`title`, `detail_title`, `summary`,
  /// `overview`, `checklist_title`, `checklist`, `checklist_optional_title`,
  /// `checklist_optional`, `checklist_note`, `steps`, `tips`, `duration`,
  /// `search_aliases`); sections, notes, links and phrases carry their own.
  final GuideI18n i18n;

  /// Everyday words people type when looking for this guide (알바, 이사,
  /// lost card…) that its title does not contain. Search-only — never
  /// rendered. Optional in Firestore (`search_aliases_ko/en`), so older
  /// documents without them still load and match on their titles.
  final List<String> searchAliasesKo;
  final List<String> searchAliasesEn;

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

  /// Heading for the checklist card when the shared one ("준비물" / "What to
  /// prepare") misreads the content — e.g. health insurance, whose list is
  /// things to verify before an automatic enrolment, not documents to bring.
  /// Falls back to the l10n heading, so every other item is unaffected.
  final String? checklistTitleKo;
  final String? checklistTitleEn;

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

  String _pick(String ko, String en, Locale l, String key) =>
      _pickText(ko, en, l, i18n, key);

  String title(Locale l) => _pick(titleKo, titleEn, l, 'title');

  /// Detail-screen heading — [detailTitle] when set, otherwise [title].
  String detailTitle(Locale l) {
    final s = _pick(detailTitleKo ?? '', detailTitleEn ?? '', l, 'detail_title');
    return s.trim().isNotEmpty ? s : title(l);
  }

  String? summary(Locale l) {
    final s = _pick(summaryKo ?? '', summaryEn ?? '', l, 'summary');
    return s.trim().isNotEmpty ? s : null;
  }

  String? overview(Locale l) {
    final s = _pick(overviewKo ?? '', overviewEn ?? '', l, 'overview');
    return s.trim().isNotEmpty ? s : null;
  }

  /// Locale-aware list with fallback to the other language when one is empty.
  List<String> checklist(Locale l) =>
      _pickList(checklistKo, checklistEn, l, 'checklist');
  List<String> checklistOptional(Locale l) => _pickList(
      checklistOptionalKo, checklistOptionalEn, l, 'checklist_optional');
  List<String> steps(Locale l) => _pickList(stepsKo, stepsEn, l, 'steps');
  List<String> tips(Locale l) => _pickList(tipsKo, tipsEn, l, 'tips');

  String? checklistTitle(Locale l) {
    final s =
        _pick(checklistTitleKo ?? '', checklistTitleEn ?? '', l, 'checklist_title');
    return s.trim().isNotEmpty ? s : null;
  }

  String? checklistOptionalTitle(Locale l) {
    final s = _pick(checklistOptionalTitleKo ?? '', checklistOptionalTitleEn ?? '',
        l, 'checklist_optional_title');
    return s.trim().isNotEmpty ? s : null;
  }

  String? checklistNote(Locale l) {
    final s =
        _pick(checklistNoteKo ?? '', checklistNoteEn ?? '', l, 'checklist_note');
    return s.trim().isNotEmpty ? s : null;
  }

  List<String> _pickList(
          List<String> ko, List<String> en, Locale l, String key) =>
      _pickTextList(ko, en, l, i18n, key);

  String? duration(Locale l) {
    final s = _pick(durationKo ?? '', durationEn ?? '', l, 'duration');
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
      checklistTitleKo: j['checklist_title_ko'] as String?,
      checklistTitleEn: j['checklist_title_en'] as String?,
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
              ?.whereType<Map>()
                  .map((e) => GuideSection.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      sections: (j['sections'] as List?)
              ?.whereType<Map>()
                  .map((e) => GuideSection.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      tipsKo: _strList(j['tips_ko']),
      tipsEn: _strList(j['tips_en']),
      phrases: (j['phrases'] as List?)
              ?.whereType<Map>()
                  .map((e) => GuidePhrase.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      links: (j['links'] as List?)
              ?.whereType<Map>()
              .map((e) => GuideLink.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      relatedFacilityIds: _strList(j['relatedFacilityIds']),
      durationKo: meta['durationText_ko'] as String?,
      durationEn: meta['durationText_en'] as String?,
      difficulty: switch (meta['difficulty']) {
        final num n => n.toInt(),
        final String t => int.tryParse(t),
        _ => null,
      },
      iconName: j['icon'] as String?,
      status: (j['status'] == 'published')
          ? GuideStatus.published
          : GuideStatus.comingSoon,
      searchAliasesKo: _strList(j['search_aliases_ko']),
      searchAliasesEn: _strList(j['search_aliases_en']),
      i18n: _i18nFromJson(j['i18n']),
    );
  }
}

/// Vietnamese letters folded to their base letter for matching only, so
/// "hoc phi" finds "học phí" and "dang ky" finds "đăng ký". Display text is
/// never folded — this runs on the comparison copy.
const Map<String, String> _vietnameseFolding = {
  'à': 'a',
  'á': 'a',
  'ả': 'a',
  'ã': 'a',
  'ạ': 'a',
  'ă': 'a',
  'ằ': 'a',
  'ắ': 'a',
  'ẳ': 'a',
  'ẵ': 'a',
  'ặ': 'a',
  'â': 'a',
  'ầ': 'a',
  'ấ': 'a',
  'ẩ': 'a',
  'ẫ': 'a',
  'ậ': 'a',
  'è': 'e',
  'é': 'e',
  'ẻ': 'e',
  'ẽ': 'e',
  'ẹ': 'e',
  'ê': 'e',
  'ề': 'e',
  'ế': 'e',
  'ể': 'e',
  'ễ': 'e',
  'ệ': 'e',
  'ì': 'i',
  'í': 'i',
  'ỉ': 'i',
  'ĩ': 'i',
  'ị': 'i',
  'ò': 'o',
  'ó': 'o',
  'ỏ': 'o',
  'õ': 'o',
  'ọ': 'o',
  'ô': 'o',
  'ồ': 'o',
  'ố': 'o',
  'ổ': 'o',
  'ỗ': 'o',
  'ộ': 'o',
  'ơ': 'o',
  'ờ': 'o',
  'ớ': 'o',
  'ở': 'o',
  'ỡ': 'o',
  'ợ': 'o',
  'ù': 'u',
  'ú': 'u',
  'ủ': 'u',
  'ũ': 'u',
  'ụ': 'u',
  'ư': 'u',
  'ừ': 'u',
  'ứ': 'u',
  'ử': 'u',
  'ữ': 'u',
  'ự': 'u',
  'ỳ': 'y',
  'ý': 'y',
  'ỷ': 'y',
  'ỹ': 'y',
  'ỵ': 'y',
  'đ': 'd',
};

/// Combining marks (U+0300–U+036F): the same Vietnamese word can arrive with
/// its tone written as a separate mark (decomposed, NFD) instead of a single
/// character, which is what a paste from a browser or some keyboards produces.
/// Dropping the marks makes both forms compare equal (B 03/054 SF-02).
final RegExp _combiningMarks = RegExp(r'[̀-ͯ]');

String _foldVietnamese(String s) {
  final stripped = s.contains(_combiningMarks) ? s.replaceAll(_combiningMarks, '') : s;
  if (!stripped.split('').any(_vietnameseFolding.containsKey)) return stripped;
  final b = StringBuffer();
  for (final ch in stripped.split('')) {
    b.write(_vietnameseFolding[ch] ?? ch);
  }
  return b.toString();
}

// Case, spaces, hyphens and dashes (U+2010–U+2015), middle dots and Vietnamese
// tone marks are ignored. A slash is NOT removed here — that would make 3/4
// and 34 the same query — it only separates words below (B 03/054 NEW-SF-02).
String _compactQuery(String s) => _foldVietnamese(
    s.toLowerCase().replaceAll(RegExp(r'[\s\-\u2010-\u2015·]+'), ''));

// Searchable text of a guide, grouped by role. Every supported language goes
// into the same lists, so a query in any language finds the guide whatever the
// UI language is. Adding a language (e.g. Chinese, Vietnamese) means adding its
// fields here; the matching and ranking below do not name any language.
/// Overlay strings for [key] across every non-built-in language.
List<String> _i18nTexts(AdminGuideItem g, String key) => [
      for (final lang in g.i18n.keys)
        ...switch (g.i18n[lang]?[key]) {
          final String v => [v],
          final List<dynamic> v => v.map((e) => e.toString()),
          _ => const <String>[],
        },
    ];

List<String> _searchTitles(AdminGuideItem g) =>
    [g.titleKo, g.titleEn, ..._i18nTexts(g, 'title')];

List<String> _searchAliases(AdminGuideItem g) => [
      ...g.searchAliasesKo,
      ...g.searchAliasesEn,
      ..._i18nTexts(g, 'search_aliases'),
    ];

List<String> _searchOtherTexts(AdminGuideItem g) => [
      g.detailTitleKo ?? '',
      g.detailTitleEn ?? '',
      g.summaryKo ?? '',
      g.summaryEn ?? '',
      ..._i18nTexts(g, 'detail_title'),
      ..._i18nTexts(g, 'summary'),
    ];

/// Guide search shared by the mock and Firestore repositories so both answer
/// the same query the same way. Matches, ignoring case, spaces, hyphens and
/// middle dots, against the titles, detail titles, summaries and search
/// aliases of every language. A multi-word query that matches no single field
/// as a whole still matches if every word is found somewhere in those fields.
///
/// Ranking: a title or alias equal to the query, then a title starting with
/// it, then any other title hit, then the rest. The catalogue order is kept
/// inside each group. A lone Latin letter or digit (the first keystroke of
/// "D-4" or "bank") only matches an equal title or alias, since as a substring
/// it would match most of the catalogue.
List<AdminGuideItem> searchGuideItems(
    Iterable<AdminGuideItem> items, String query) {
  final q = _compactQuery(query);
  if (q.isEmpty) return const [];
  final words = query
      // A slash separates alternatives the way a space does, so 「D-4/D-2」
      // matches a guide that carries both codes (B 03/054 N-02).
      .split(RegExp(r'[\s/]+'))
      .map(_compactQuery)
      .where((w) => w.isNotEmpty)
      .toList();
  final exactOnly = RegExp(r'^[a-z0-9]$').hasMatch(q);
  final groups = List.generate(4, (_) => <AdminGuideItem>[]);
  for (final g in items) {
    final titles = _searchTitles(g).map(_compactQuery).toList();
    final aliases = _searchAliases(g).map(_compactQuery).toList();
    final fields = [
      ...titles,
      ...aliases,
      ..._searchOtherTexts(g).map(_compactQuery),
    ].where((f) => f.isNotEmpty).toList();
    if (titles.contains(q) || aliases.contains(q)) {
      groups[0].add(g);
    } else if (exactOnly) {
      continue;
    } else if (titles.any((t) => t.startsWith(q))) {
      groups[1].add(g);
    } else if (titles.any((t) => t.contains(q))) {
      groups[2].add(g);
    } else if (fields.any((f) => f.contains(q)) ||
        (words.length > 1 &&
            words.every((w) => fields.any((f) => f.contains(w))))) {
      groups[3].add(g);
    }
  }
  return [for (final group in groups) ...group];
}
