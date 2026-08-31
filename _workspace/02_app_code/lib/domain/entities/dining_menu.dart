import 'package:flutter/material.dart';

import 'facility.dart';

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
  });

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

  bool get isClosed => meals.isEmpty;

  String name(Locale l) => _pick(l, nameKo, nameEn) ?? id;
  String? hours(Locale l) => _pick(l, hoursKo, hoursEn);

  static String? _pick(Locale l, String? ko, String? en) {
    final wantKo = l.languageCode == 'ko';
    final primary = wantKo ? ko : en;
    final secondary = wantKo ? en : ko;
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (secondary != null && secondary.trim().isNotEmpty) return secondary;
    return null;
  }

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
      };
}
