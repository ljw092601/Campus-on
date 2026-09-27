import 'package:flutter/material.dart';

import 'facility.dart';

import '../../core/i18n/entity_i18n.dart';

/// Meal slots served by campus cafeterias.
enum MealType {
  breakfast,
  lunch,
  dinner;

  static MealType fromId(String id) => MealType.values
      .firstWhere((e) => e.name == id, orElse: () => MealType.lunch);
}

/// One meal offering on a given day: the menu lines as served (Korean
/// source data) plus an optional price tag.
@immutable
class Meal {
  const Meal({required this.type, required this.items, this.price});

  final MealType type;

  /// Menu lines (e.g. "제육볶음", "미역국"). Korean-only for now — the school
  /// API contract will decide whether translations exist.
  final List<String> items;

  /// Display price in KRW; null when the cafeteria doesn't publish one.
  final int? price;

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        type: MealType.fromId((j['type'] ?? 'lunch') as String),
        items: [for (final s in (j['items'] as List? ?? const [])) s as String],
        price: (j['price'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() =>
      {'type': type.name, 'items': items, 'price': price};
}

/// Whether a cafeteria's menu for a day is published, and how (agreed design:
/// _workspace/06_admin_data_pipeline.md §7 D1). Distinguishes an admin who
/// hasn't entered the menu yet ([unpublished]) from an explicit closure
/// ([closed]) — merging the two would announce "closed" for missing input.
enum DiningAvailability {
  open,
  closed,
  unpublished;

  static DiningAvailability? fromId(String? id) {
    if (id == null) return null;
    for (final v in DiningAvailability.values) {
      if (v.name == id) return v;
    }
    return null;
  }
}

/// One cafeteria's menu for one day.
@immutable
class CafeteriaMenu {
  const CafeteriaMenu({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.campus,
    required this.meals,
    this.hoursKo,
    this.hoursEn,
    this.facilityId,
    DiningAvailability? status,
    this.i18n = noI18n,
  }) : _status = status;

  final String id;
  final String nameKo;
  final String nameEn;
  final Campus campus;

  /// Meals served that day, breakfast → dinner order. Empty = closed.
  final List<Meal> meals;

  final String? hoursKo;
  final String? hoursEn;

  /// Optional link to the facility (map pin) hosting this cafeteria.
  final String? facilityId;

  /// Chinese and Vietnamese text for `name` and `hours`. The menu lines are
  /// not in here — they change daily and are translated by their own text
  /// (see data/i18n/place_text.dart).
  final EntityI18n i18n;

  /// Explicit availability when the data source provides one; null falls back
  /// to the legacy rule (empty meals == closed) so mock data stays valid.
  final DiningAvailability? _status;

  DiningAvailability get status =>
      _status ??
      (meals.isEmpty ? DiningAvailability.closed : DiningAvailability.open);

  bool get isClosed => status == DiningAvailability.closed;
  bool get isUnpublished => status == DiningAvailability.unpublished;

  /// Never falls back to [id]: an internal key must not reach the screen.
  String name(Locale l) => _pick(l, nameKo, nameEn, 'name') ?? '—';
  String? hours(Locale l) => _pick(l, hoursKo, hoursEn, 'hours');

  String? _pick(Locale l, String? ko, String? en, String key) {
    final t = pickI18nText(ko ?? '', en ?? '', l, i18n, key);
    return t.isEmpty ? null : t;
  }

  /// The same cafeteria with empty English fields filled in from [en] — see
  /// [Facility.withEnglish] for why English needs this and the other languages
  /// do not.
  CafeteriaMenu withEnglish(Map<String, Object?> en) {
    String? pick(String? current, String key) {
      if ((current ?? '').trim().isNotEmpty) return current;
      final v = en[key];
      return v is String && v.trim().isNotEmpty ? v : current;
    }

    return CafeteriaMenu(
      id: id,
      nameKo: nameKo,
      nameEn: pick(nameEn, 'name') ?? nameEn,
      campus: campus,
      meals: meals,
      hoursKo: hoursKo,
      hoursEn: pick(hoursEn, 'hours'),
      facilityId: facilityId,
      status: _status,
      i18n: i18n,
    );
  }

  /// The same cafeteria carrying [i18n].
  CafeteriaMenu withI18n(EntityI18n i18n) => CafeteriaMenu(
        id: id,
        nameKo: nameKo,
        nameEn: nameEn,
        campus: campus,
        meals: meals,
        hoursKo: hoursKo,
        hoursEn: hoursEn,
        facilityId: facilityId,
        status: _status,
        i18n: i18n,
      );

  factory CafeteriaMenu.fromJson(Map<String, dynamic> j) => CafeteriaMenu(
        id: j['id'] as String,
        nameKo: (j['name_ko'] ?? '') as String,
        nameEn: (j['name_en'] ?? '') as String,
        campus: Campus.fromId(j['campus'] as String?) ?? Campus.seunghak,
        meals: [
          for (final m in (j['meals'] as List? ?? const []))
            Meal.fromJson((m as Map).cast<String, dynamic>()),
        ],
        hoursKo: j['hours_ko'] as String?,
        hoursEn: j['hours_en'] as String?,
        facilityId: j['facilityId'] as String?,
        status: DiningAvailability.fromId(j['status'] as String?),
        i18n: entityI18nFromJson(j['i18n']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ko': nameKo,
        'name_en': nameEn,
        'campus': campus.name,
        'meals': [for (final m in meals) m.toJson()],
        'hours_ko': hoursKo,
        'hours_en': hoursEn,
        'facilityId': facilityId,
        'status': status.name,
        if (entityI18nToJson(i18n) != null) 'i18n': entityI18nToJson(i18n),
      };
}
