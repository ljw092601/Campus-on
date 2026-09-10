import 'package:flutter/material.dart';

/// Kinds of academic-calendar entries; drives the badge label/tint.
enum AcademicEventCategory {
  semester,
  registration,
  exam,
  holiday,
  graduation;

  static AcademicEventCategory fromId(String id) =>
      AcademicEventCategory.values.firstWhere((e) => e.name == id,
          orElse: () => AcademicEventCategory.semester);
}

/// One academic-calendar entry — a single day ([end] null) or a date range.
/// Dates only; time-of-day is ignored.
@immutable
class AcademicEvent {
  const AcademicEvent({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.category,
    required this.start,
    this.end,
  });

  final String id;
  final String titleKo;
  final String titleEn;
  final AcademicEventCategory category;
  final DateTime start;
  final DateTime? end;

  DateTime get endDate => end ?? start;

  String title(Locale l) => _pick(l, titleKo, titleEn) ?? id;

  static String? _pick(Locale l, String? ko, String? en) {
    final wantKo = l.languageCode == 'ko';
    final primary = wantKo ? ko : en;
    final secondary = wantKo ? en : ko;
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (secondary != null && secondary.trim().isNotEmpty) return secondary;
    return null;
  }

  static String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

  factory AcademicEvent.fromJson(Map<String, dynamic> j) => AcademicEvent(
        id: j['id'] as String,
        titleKo: (j['title_ko'] ?? '') as String,
        titleEn: (j['title_en'] ?? '') as String,
        category: AcademicEventCategory.fromId(
            (j['category'] ?? 'semester') as String),
        start: DateTime.parse(j['start'] as String),
        end: j['end'] == null ? null : DateTime.parse(j['end'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title_ko': titleKo,
        'title_en': titleEn,
        'category': category.name,
        'start': _dateOnly(start),
        'end': end == null ? null : _dateOnly(end!),
      };
}
