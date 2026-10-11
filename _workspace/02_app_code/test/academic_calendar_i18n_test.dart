import 'dart:convert';
import 'dart:io';

import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/data/repositories/mock_academic_calendar_repository.dart';
import 'package:campus_on/domain/entities/academic_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Event names used to exist in Korean and English only: a Chinese or
/// Vietnamese reader got a translated screen with the one thing that says what
/// the entry *is* still in English. The entity now carries the same `i18n` map
/// the guides use, and these tests pin both halves of that — the fallback when
/// a translation is missing, and the fact that an old Korean/English document
/// still reads and serialises exactly as before.
void main() {
  const ko = Locale('ko');
  const en = Locale('en');
  const zh = Locale('zh');
  const vi = Locale('vi');

  AcademicEvent event({
    String titleKo = '2학기 수강신청',
    String titleEn = 'Fall course registration',
    Map<String, Map<String, Object?>> i18n = const {},
  }) =>
      AcademicEvent(
        id: 'fall-registration',
        titleKo: titleKo,
        titleEn: titleEn,
        category: AcademicEventCategory.registration,
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 14),
        i18n: i18n,
      );

  group('title in four languages', () {
    final translated = event(i18n: const {
      'zh': {'title': '2学期选课'},
      'vi': {'title': 'Đăng ký môn học kỳ 2'},
    });

    test('each language gets its own name', () {
      expect(translated.title(ko), '2학기 수강신청');
      expect(translated.title(en), 'Fall course registration');
      expect(translated.title(zh), '2学期选课');
      expect(translated.title(vi), 'Đăng ký môn học kỳ 2');
    });

    test('an untranslated event falls back to English, then Korean', () {
      final onlyKoEn = event();
      expect(onlyKoEn.title(zh), 'Fall course registration',
          reason: 'requested → English');
      expect(onlyKoEn.title(vi), 'Fall course registration');

      final onlyKo = event(titleEn: '');
      expect(onlyKo.title(zh), '2학기 수강신청',
          reason: 'no English either → Korean, never a blank line');
      expect(onlyKo.title(en), '2학기 수강신청');
    });

    test('a blank or wrongly-shaped translation falls back, it does not show',
        () {
      expect(event(i18n: const {'zh': {'title': '   '}}).title(zh),
          'Fall course registration');
      // A hand-edited document: the value is a number, or the language holds a
      // string instead of a map. Neither may reach the screen or throw.
      final broken = AcademicEvent.fromJson(const {
        'id': 'x',
        'title_ko': '한국어',
        'title_en': 'English',
        'category': 'exam',
        'start': '2026-10-20',
        'i18n': {'zh': 42, 'vi': {'title': 7}},
      });
      expect(broken.title(zh), 'English');
      expect(broken.title(vi), 'English');
    });

    test('an event with no name at all shows its id, not an empty row', () {
      final nameless = event(titleKo: '', titleEn: '');
      expect(nameless.title(ko), 'fall-registration');
    });

    test('titleFor reports what is written, with no fallback', () {
      expect(translated.titleFor('zh'), '2学期选课');
      expect(event().titleFor('zh'), isEmpty);
      expect(translated.titleLanguage('zh'), 'zh');
      expect(event().titleLanguage('vi'), 'en',
          reason: 'records that vi is still falling back, not translated');
    });
  });

  group('JSON round trip', () {
    test('a Korean/English event serialises exactly as before', () {
      final json = event().toJson();
      expect(json.containsKey('i18n'), isFalse,
          reason: 'no empty i18n key on documents that have no translations');
      expect(json, const {
        'id': 'fall-registration',
        'title_ko': '2학기 수강신청',
        'title_en': 'Fall course registration',
        'category': 'registration',
        'start': '2026-08-10',
        'end': '2026-08-14',
      });
    });

    test('translations survive a round trip', () {
      final before = event(i18n: const {
        'zh': {'title': '2学期选课'},
        'vi': {'title': 'Đăng ký môn học kỳ 2'},
      });
      final after = AcademicEvent.fromJson(before.toJson());
      expect(after.title(zh), before.title(zh));
      expect(after.title(vi), before.title(vi));
      expect(after.toJson(), before.toJson());
    });

    test('a document written before this field existed still reads', () {
      final legacy = AcademicEvent.fromJson(const {
        'id': 'chuseok',
        'title_ko': '추석 연휴',
        'title_en': 'Chuseok holiday',
        'category': 'holiday',
        'start': '2026-09-24',
        'end': '2026-09-26',
      });
      expect(legacy.title(ko), '추석 연휴');
      expect(legacy.title(vi), 'Chuseok holiday');
      expect(legacy.i18n, isEmpty);
    });
  });

  group('the shipped calendar', () {
    test('every event is translated into all four languages', () async {
      final events = await MockAcademicCalendarRepository().getEvents();
      expect(events, hasLength(14));
      for (final e in events) {
        for (final code in appLanguageCodes) {
          expect(e.titleFor(code).trim(), isNotEmpty,
              reason: '${e.id} has no $code title — a reader of that language '
                  'would fall back to English');
          expect(e.titleLanguage(code), code,
              reason: '${e.id} is still falling back for $code');
        }
      }
    });

    test('translation files and the source agree with the shipped data',
        () async {
      // The translators own the JSON; the Dart overlay is generated from it.
      // If someone edits one side only, this fails instead of shipping a
      // half-translated calendar.
      final source = jsonDecode(
          File('tool/i18n/calendar_source.json').readAsStringSync());
      final srcEvents = (source['events'] as Map).cast<String, dynamic>();
      final events = await MockAcademicCalendarRepository().getEvents();

      expect(events.map((e) => e.id).toSet(), srcEvents.keys.toSet(),
          reason: 'calendar_source.json lists exactly the shipped events');
      for (final e in events) {
        final src = (srcEvents[e.id] as Map).cast<String, dynamic>();
        expect(e.titleKo, src['title_ko'], reason: '${e.id} Korean');
        expect(e.titleEn, src['title_en'], reason: '${e.id} English');
        expect(e.category.name, src['category'], reason: '${e.id} category');
        expect(e.start.toIso8601String().substring(0, 10), src['start'],
            reason: '${e.id} start date');
        // The end date is half of what a date range means; comparing only the
        // start let a changed range through (B 03/063 SF-02).
        expect(e.end?.toIso8601String().substring(0, 10), src['end'],
            reason: '${e.id} end date (null when the event is a single day)');
      }

      for (final lang in const ['zh', 'vi']) {
        final titles = (jsonDecode(File('tool/i18n/calendar_$lang.json')
                .readAsStringSync())['titles'] as Map)
            .cast<String, dynamic>();
        for (final e in events) {
          expect(e.titleFor(lang), titles[e.id],
              reason: '${e.id}: $lang in the app differs from '
                  'calendar_$lang.json — regenerate with '
                  'python tool/i18n/i18n_tool.py calendar-gen');
        }
      }
    });

    test('ids, dates and categories are untouched by translation', () async {
      // Translating must never move a date or change a category.
      final events = await MockAcademicCalendarRepository().getEvents();
      final byId = {for (final e in events) e.id: e};
      expect(byId['midterm-exams']!.start, DateTime(2026, 10, 20));
      expect(byId['midterm-exams']!.end, DateTime(2026, 10, 26));
      expect(byId['midterm-exams']!.category, AcademicEventCategory.exam);
      expect(byId['chuseok']!.category, AcademicEventCategory.holiday);
      expect(byId['winter-commencement']!.category,
          AcademicEventCategory.graduation);
    });
  });
}
