import 'package:flutter/material.dart';
import '../../core/i18n/app_languages.dart';
import '../../core/i18n/entity_i18n.dart';

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
    this.i18n = noI18n,
  });

  final String id;
  final String titleKo;
  final String titleEn;
  final AcademicEventCategory category;
  final DateTime start;
  final DateTime? end;

  /// Chinese and Vietnamese titles, under the key `title` — the same `i18n`
  /// map the guide documents carry. Absent on every document written before
  /// this existed, which is exactly the Korean/English behaviour as before.
  final EntityI18n i18n;

  DateTime get endDate => end ?? start;

  /// The same event carrying [i18n]. Used where translations are applied over
  /// data that was written with Korean and English only.
  AcademicEvent withI18n(EntityI18n i18n) => AcademicEvent(
        id: id,
        titleKo: titleKo,
        titleEn: titleEn,
        category: category,
        start: start,
        end: end,
        i18n: i18n,
      );

  /// Korean academic year (학년도) a date belongs to: runs March 1 through
  /// the end of February, so Jan/Feb count toward the previous year.
  static int academicYearOf(DateTime d) => d.month >= 3 ? d.year : d.year - 1;

  /// The 학년도 this event belongs to (by its start date).
  int get academicYear => academicYearOf(start);

  /// The event name for [l]: the requested language, then English, then
  /// Korean. An event nobody has translated still reads, in English, instead of
  /// showing a blank line.
  ///
  /// The slug is kept as the last resort: an event with no name in any language
  /// can only come from a bad admin row, and showing `2026-03-02 ·
  /// spring-semester-start` tells the reader and the admin more than an empty
  /// line would.
  String title(Locale l) {
    final t = pickI18nText(titleKo, titleEn, l, i18n, 'title');
    return t.isEmpty ? id : t;
  }

  /// Which language the title actually comes out in — used by the tests that
  /// check coverage, and by the exporter check.
  String titleLanguage(String code) =>
      resolveLanguage(code, (c) => titleFor(c).trim().isNotEmpty);

  /// The written title for one language code, with no fallback applied.
  String titleFor(String code) {
    switch (code) {
      case 'ko':
        return titleKo;
      case 'en':
        return titleEn;
      default:
        return (i18n[code]?['title'] as String?) ?? '';
    }
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
        i18n: entityI18nFromJson(j['i18n']),
      );

  /// `i18n` is written only when there is something in it, so a Korean/English
  /// event serialises byte for byte as it did before the field existed.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title_ko': titleKo,
        'title_en': titleEn,
        'category': category.name,
        'start': _dateOnly(start),
        'end': end == null ? null : _dateOnly(end!),
        if (entityI18nToJson(i18n) != null) 'i18n': entityI18nToJson(i18n),
      };
}
