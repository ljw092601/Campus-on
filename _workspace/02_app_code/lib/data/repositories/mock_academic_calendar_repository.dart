import '../../domain/entities/academic_event.dart';
import '../../domain/repositories/academic_calendar_repository.dart';

/// PLACEHOLDER academic calendar until the official Dong-A schedule is
/// confirmed (TODO(calendar-data)): a plausible 2026-2 semester timeline.
/// Every date here is a sample — the screen shows a notice banner saying so.
/// Replace with the official 학사일정 when the source is settled.
class MockAcademicCalendarRepository implements AcademicCalendarRepository {
  static const _latency = Duration(milliseconds: 120);

  static final _events = <AcademicEvent>[
    AcademicEvent(
      id: 'fall-registration',
      titleKo: '2학기 수강신청',
      titleEn: 'Fall course registration',
      category: AcademicEventCategory.registration,
      start: DateTime(2026, 8, 10),
      end: DateTime(2026, 8, 14),
    ),
    AcademicEvent(
      id: 'fall-semester-start',
      titleKo: '2학기 개강',
      titleEn: 'Fall semester begins',
      category: AcademicEventCategory.semester,
      start: DateTime(2026, 9, 1),
    ),
    AcademicEvent(
      id: 'fall-add-drop',
      titleKo: '수강신청 정정',
      titleEn: 'Course add/drop period',
      category: AcademicEventCategory.registration,
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 7),
    ),
    AcademicEvent(
      id: 'chuseok',
      titleKo: '추석 연휴',
      titleEn: 'Chuseok holiday',
      category: AcademicEventCategory.holiday,
      start: DateTime(2026, 9, 24),
      end: DateTime(2026, 9, 26),
    ),
    AcademicEvent(
      id: 'foundation-day',
      titleKo: '개천절',
      titleEn: 'National Foundation Day',
      category: AcademicEventCategory.holiday,
      start: DateTime(2026, 10, 3),
    ),
    AcademicEvent(
      id: 'hangul-day',
      titleKo: '한글날',
      titleEn: 'Hangul Day',
      category: AcademicEventCategory.holiday,
      start: DateTime(2026, 10, 9),
    ),
    AcademicEvent(
      id: 'midterm-exams',
      titleKo: '중간시험',
      titleEn: 'Midterm exams',
      category: AcademicEventCategory.exam,
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 10, 26),
    ),
    AcademicEvent(
      id: 'course-withdrawal',
      titleKo: '수강 철회',
      titleEn: 'Course withdrawal period',
      category: AcademicEventCategory.registration,
      start: DateTime(2026, 11, 2),
      end: DateTime(2026, 11, 6),
    ),
    AcademicEvent(
      id: 'final-exams',
      titleKo: '기말시험',
      titleEn: 'Final exams',
      category: AcademicEventCategory.exam,
      start: DateTime(2026, 12, 8),
      end: DateTime(2026, 12, 14),
    ),
    AcademicEvent(
      id: 'winter-break',
      titleKo: '겨울방학 시작',
      titleEn: 'Winter break begins',
      category: AcademicEventCategory.semester,
      start: DateTime(2026, 12, 15),
    ),
    AcademicEvent(
      id: 'winter-session',
      titleKo: '겨울 계절수업',
      titleEn: 'Winter session',
      category: AcademicEventCategory.semester,
      start: DateTime(2026, 12, 21),
      end: DateTime(2027, 1, 13),
    ),
    AcademicEvent(
      id: 'spring-registration',
      titleKo: '1학기 수강신청',
      titleEn: 'Spring course registration',
      category: AcademicEventCategory.registration,
      start: DateTime(2027, 2, 8),
      end: DateTime(2027, 2, 12),
    ),
    AcademicEvent(
      id: 'winter-commencement',
      titleKo: '학위수여식',
      titleEn: 'Commencement',
      category: AcademicEventCategory.graduation,
      start: DateTime(2027, 2, 19),
    ),
    AcademicEvent(
      id: 'spring-semester-start',
      titleKo: '1학기 개강',
      titleEn: 'Spring semester begins',
      category: AcademicEventCategory.semester,
      start: DateTime(2027, 3, 2),
    ),
  ];

  @override
  Future<List<AcademicEvent>> getEvents() async {
    await Future<void>.delayed(_latency);
    return [..._events]..sort((a, b) => a.start.compareTo(b.start));
  }
}
