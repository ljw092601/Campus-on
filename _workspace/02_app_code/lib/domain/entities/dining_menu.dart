import 'package:flutter/material.dart';

import 'facility.dart';

/// When during the day a menu section is served.
///
/// `allDay` is for cafeterias that keep serving between their breaks
/// (학생회관·도서관 식당) rather than at fixed meal times.
enum MealSlot {
  breakfast,
  lunch,
  dinner,
  allDay;

  /// Null for an unknown id — callers skip the section instead of silently
  /// relabelling it (the old `MealType.fromId` defaulted to lunch).
  static MealSlot? fromId(String? id) {
    for (final v in MealSlot.values) {
      if (v.name == id) return v;
    }
    return null;
  }
}

/// What kind of offering a section is. Drives how the price is shown:
/// [set] and [thousandWon] carry one price for the whole tray, [alacarte]
/// and [snack] price each item.
enum MenuKind {
  /// 정식 — a fixed tray (soup, main, sides, kimchi) with one price.
  set,

  /// 일품 — single dishes, each with its own price (국밥, 돈까스, 포케…).
  alacarte,

  /// 양분식 — light food such as 김밥·핫도그, also sold at the student hall café.
  snack,

  /// 천원의아침밥 — the ₩1,000 breakfast, one dish a day, first come first served.
  thousandWon;

  static MenuKind? fromId(String? id) {
    for (final v in MenuKind.values) {
      if (v.name == id) return v;
    }
    return null;
  }

  /// Whether the price belongs to the section as a whole (one tray price)
  /// rather than to each item.
  bool get hasSectionPrice => this == set || this == thousandWon;
}

/// Lenient integer read for sheet-sourced numbers: accepts 7000, 7000.0 and
/// "7000"; anything else is "no price" rather than a dropped document.
int? _intOrNull(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim().replaceAll(',', ''));
  return null;
}

/// One dish or menu line inside a [MenuSection].
@immutable
class MenuItem {
  const MenuItem({required this.name, this.price});

  /// As served (Korean source data).
  final String name;

  /// Per-item price in KRW — used by [MenuKind.alacarte] / [MenuKind.snack];
  /// null when the section carries the price or none is published.
  final int? price;

  factory MenuItem.fromJson(Object? j) {
    // Legacy `items: ["제육볶음", ...]` kept plain strings.
    if (j is String) return MenuItem(name: j);
    final m = (j as Map).cast<String, dynamic>();
    final name = m['name'];
    return MenuItem(
      name: name is String ? name : (name?.toString() ?? ''),
      price: _intOrNull(m['price']),
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, if (price != null) 'price': price};
}

/// One priced group on a cafeteria's daily menu: "점심 정식 7,000원 + 반찬",
/// "점심 일품: 국밥 6,000 / 돈까스 7,500", "아침 천원의아침밥 …".
///
/// A cafeteria may publish several sections for the same [slot] (set and
/// a-la-carte side by side) — that is the whole reason this replaced the
/// one-price-per-meal `Meal`.
@immutable
class MenuSection {
  const MenuSection({
    required this.slot,
    required this.kind,
    required this.items,
    this.price,
    this.note,
  });

  final MealSlot slot;
  final MenuKind kind;
  final List<MenuItem> items;

  /// Section price in KRW for [MenuKind.hasSectionPrice] kinds; null when
  /// the items are priced individually or no price is published.
  final int? price;

  /// Free text from the admin sheet ("셀프바", "09:00부터 선착순").
  final String? note;

  /// Null when the slot or kind is unknown — the caller drops the section
  /// rather than showing it under a wrong label.
  static MenuSection? fromJson(Map<String, dynamic> j) {
    final slot = MealSlot.fromId(j['slot'] as String?);
    final kind = MenuKind.fromId(j['kind'] as String?);
    if (slot == null || kind == null) return null;
    final note = j['note'];
    return MenuSection(
      slot: slot,
      kind: kind,
      items: [
        for (final i in (j['items'] as List? ?? const [])) MenuItem.fromJson(i)
      ],
      price: _intOrNull(j['price']),
      note: note is String && note.trim().isNotEmpty ? note : null,
    );
  }

  /// Pre-`sections` documents (`meals: [{type, items, price}]`): one meal per
  /// slot with a single price → a [MenuKind.set] section.
  static MenuSection? fromLegacyMeal(Map<String, dynamic> j) {
    final slot = MealSlot.fromId((j['type'] ?? 'lunch') as String?);
    if (slot == null) return null;
    return MenuSection(
      slot: slot,
      kind: MenuKind.set,
      items: [
        for (final s in (j['items'] as List? ?? const [])) MenuItem.fromJson(s)
      ],
      price: _intOrNull(j['price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot.name,
        'kind': kind.name,
        'items': [for (final i in items) i.toJson()],
        if (price != null) 'price': price,
        if (note != null) 'note': note,
      };
}

/// One continuous serving window, "HH:mm" 24-hour strings. A cafeteria's
/// day is a list of these; the gaps between them are its breaks
/// (학생회관: 09:00–09:30, 10:00–14:30, 15:00–16:30 → 휴게 09:30–10:00 and
/// 14:30–15:00).
@immutable
class ServiceHours {
  const ServiceHours({required this.open, required this.close});

  final String open;
  final String close;

  static final _pattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static bool isValidTime(String s) => _pattern.hasMatch(s);

  /// Minutes since midnight, or null when malformed.
  static int? minutesOf(String s) {
    if (!isValidTime(s)) return null;
    final h = int.parse(s.substring(0, 2));
    final m = int.parse(s.substring(3, 5));
    return h * 60 + m;
  }

  bool get isValid {
    final o = minutesOf(open);
    final c = minutesOf(close);
    return o != null && c != null && o < c;
  }

  static ServiceHours? fromJson(Object? j) {
    if (j is! Map) return null;
    final open = j['open'];
    final close = j['close'];
    if (open is! String || close is! String) return null;
    final h = ServiceHours(open: open, close: close);
    return h.isValid ? h : null;
  }

  Map<String, dynamic> toJson() => {'open': open, 'close': close};

  @override
  bool operator ==(Object other) =>
      other is ServiceHours && other.open == open && other.close == close;

  @override
  int get hashCode => Object.hash(open, close);
}

/// The day's windows folded into "first open – last close + breaks", which
/// is how the school publishes them ("09:00~16:30, 휴게 09:30~10:00").
@immutable
class ServiceHoursSummary {
  const ServiceHoursSummary(
      {required this.open, required this.close, required this.breaks});

  final String open;
  final String close;
  final List<ServiceHours> breaks;

  static ServiceHoursSummary? of(List<ServiceHours> windows) {
    if (windows.isEmpty) return null;
    final sorted = [...windows]
      ..sort((a, b) => ServiceHours.minutesOf(a.open)!
          .compareTo(ServiceHours.minutesOf(b.open)!));
    // Overlapping windows are a sheet-validation error, but stay sane here:
    // a break only exists where the latest close so far precedes the next
    // open, and the day's close is the latest close of any window.
    final breaks = <ServiceHours>[];
    var latestClose = sorted.first.close;
    for (var i = 1; i < sorted.length; i++) {
      final w = sorted[i];
      if (ServiceHours.minutesOf(latestClose)! <
          ServiceHours.minutesOf(w.open)!) {
        breaks.add(ServiceHours(open: latestClose, close: w.open));
      }
      if (ServiceHours.minutesOf(w.close)! >
          ServiceHours.minutesOf(latestClose)!) {
        latestClose = w.close;
      }
    }
    return ServiceHoursSummary(
        open: sorted.first.open, close: latestClose, breaks: breaks);
  }
}

/// Whether a cafeteria's menu for a day is published, and how (agreed design:
/// _workspace/06_admin_data_pipeline.md §7 D1). Distinguishes an admin who
/// hasn't entered the menu yet ([unpublished]) from an explicit closure
/// ([closed]) — merging the two would announce "closed" for missing input.
enum DiningAvailability {
  open,
  closed,
  unpublished,
  unavailable;

  static DiningAvailability? fromId(String? id) {
    if (id == null) return null;
    for (final v in DiningAvailability.values) {
      if (v.name == id) return v;
    }
    return null;
  }
}

/// How the dining screen groups cafeterias: the school runs 승학 on its own
/// and 구덕·부민 together.
enum CampusGroup {
  seunghak,
  gudeokBumin;

  static CampusGroup of(Campus campus) =>
      campus == Campus.seunghak ? seunghak : gudeokBumin;
}

/// One cafeteria's menu for one day, joined with the cafeteria's static
/// info (name, campus, hours, map pin).
@immutable
class CafeteriaMenu {
  const CafeteriaMenu({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.campus,
    required this.sections,
    this.serviceHours = const [],
    this.hoursKo,
    this.hoursEn,
    this.facilityId,
    this.order = 0,
    DiningAvailability? status,
  }) : _status = status;

  final String id;
  final String nameKo;
  final String nameEn;
  final Campus campus;

  CampusGroup get campusGroup => CampusGroup.of(campus);

  /// Sections published that day. [CafeteriaMenu.fromJson] already sorts
  /// these by slot then kind; prefer [sectionsInOrder] for display so a
  /// hand-built list (mock/tests) is shown in order too. Empty = nothing
  /// served (see [status]).
  final List<MenuSection> sections;

  /// [sections] in serving order (breakfast → lunch → dinner → all day, then
  /// set → a-la-carte → snack → ₩1,000 breakfast), independent of the order
  /// the admin typed them into the sheet. Stable within equal keys.
  List<MenuSection> get sectionsInOrder => sortSections(sections);

  static List<MenuSection> sortSections(List<MenuSection> sections) {
    final indexed = [
      for (var i = 0; i < sections.length; i++) (i, sections[i])
    ];
    indexed.sort((a, b) {
      final s = a.$2.slot.index.compareTo(b.$2.slot.index);
      if (s != 0) return s;
      final k = a.$2.kind.index.compareTo(b.$2.kind.index);
      return k != 0 ? k : a.$1.compareTo(b.$1);
    });
    return List.unmodifiable([for (final e in indexed) e.$2]);
  }

  /// Serving windows for the day (gaps = breaks). Empty when the school
  /// publishes no hours (공과대학 식당) — then [hoursKo]/[hoursEn] may carry a
  /// free-text note instead.
  final List<ServiceHours> serviceHours;

  ServiceHoursSummary? get hoursSummary => ServiceHoursSummary.of(serviceHours);

  /// Free-text hours note (legacy field, still accepted from the sheet).
  final String? hoursKo;
  final String? hoursEn;

  /// Optional link to the facility (map pin) hosting this cafeteria.
  final String? facilityId;

  /// Display order within its campus group (admin sheet "표시 순서").
  final int order;

  /// Explicit availability when the data source provides one; null falls back
  /// to the legacy rule (no sections == closed) so mock data stays valid.
  final DiningAvailability? _status;

  DiningAvailability get status =>
      _status ??
      (sections.isEmpty ? DiningAvailability.closed : DiningAvailability.open);

  bool get isClosed => status == DiningAvailability.closed;
  bool get isUnpublished => status == DiningAvailability.unpublished;

  String name(Locale l) => _pick(l, nameKo, nameEn) ?? id;

  /// Free-text hours note in the UI locale, if any. Structured hours are in
  /// [hoursSummary]; the screen formats those with localized labels.
  String? hoursNote(Locale l) => _pick(l, hoursKo, hoursEn);

  static String? _pick(Locale l, String? ko, String? en) {
    final wantKo = l.languageCode == 'ko';
    final primary = wantKo ? ko : en;
    final secondary = wantKo ? en : ko;
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (secondary != null && secondary.trim().isNotEmpty) return secondary;
    return null;
  }

  /// Accepts both the current shape (`sections`, `hours: [{open, close}]`)
  /// and pre-redesign documents (`meals: [{type, items, price}]`, free-text
  /// `hours_ko`), so last week's menus still render after the switch.
  factory CafeteriaMenu.fromJson(Map<String, dynamic> j) {
    final rawSections = j['sections'] as List?;
    final sections = rawSections != null
        ? [
            for (final s in rawSections)
              MenuSection.fromJson((s as Map).cast<String, dynamic>())
          ]
        : [
            for (final m in (j['meals'] as List? ?? const []))
              MenuSection.fromLegacyMeal((m as Map).cast<String, dynamic>())
          ];
    return CafeteriaMenu(
      id: j['id'] as String,
      nameKo: (j['name_ko'] ?? '') as String,
      nameEn: (j['name_en'] ?? '') as String,
      campus: Campus.fromId(j['campus'] as String?) ?? Campus.seunghak,
      // Sheet rows arrive in whatever order the admin typed them; the app
      // owns the display order.
      sections: sortSections([for (final s in sections) if (s != null) s]),
      serviceHours: [
        for (final h in (j['hours'] as List? ?? const []))
          if (ServiceHours.fromJson(h) case final w?) w
      ],
      hoursKo: j['hours_ko'] as String?,
      hoursEn: j['hours_en'] as String?,
      facilityId: j['facilityId'] as String?,
      order: _intOrNull(j['order']) ?? 0,
      status: DiningAvailability.fromId(j['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ko': nameKo,
        'name_en': nameEn,
        'campus': campus.name,
        'sections': [for (final s in sections) s.toJson()],
        'hours': [for (final h in serviceHours) h.toJson()],
        'hours_ko': hoursKo,
        'hours_en': hoursEn,
        'facilityId': facilityId,
        'order': order,
        'status': status.name,
      };
}
