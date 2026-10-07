import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../domain/repositories/dining_repository.dart';

/// Mock dining data for the default dev mode (no Firebase required).
///
/// A school dining API was confirmed unavailable, so production data flows
/// admin sheet → Firestore (`cafeterias` + `dining_menus`; see
/// _workspace/06_admin_data_pipeline.md). Running with
/// `--dart-define=USE_FIRESTORE_DINING=true` swaps in
/// `FirestoreDiningRepository`; this mock stays the default-mode stand-in and
/// is also what `tool/firestore_seed/export_seed_test.dart` exports as the
/// `cafeterias` starter seed, so its static info (ids, names, hours, map pins,
/// order) is the canonical list of the school's 8 cafeterias.
///
/// Menus are fake but realistic: each cafeteria has a pool of 5–7 distinct
/// days which rotates deterministically by date (same date → same menu,
/// adjacent weekdays → different menus, next week shifts the pool by one).
/// Weekends are `closed` except the student hall's Saturday lunch; 공과대학
/// serves only Tue/Thu and is `unpublished` on the other weekdays.
class MockDiningRepository implements DiningRepository {
  MockDiningRepository({this.latency = const Duration(milliseconds: 120)});

  /// Simulated network delay before the menus resolve.
  final Duration latency;

  /// Display order == list order (campus group 승학 → 구덕·부민, then `order`),
  /// the same ordering `FirestoreDiningRepository.compareForDisplay` applies
  /// to Firestore data.
  static const List<MockCafeteriaInfo> cafeterias = [
    MockCafeteriaInfo(
      id: 'seunghak-faculty',
      nameKo: '교수회관 식당',
      nameEn: 'Faculty Hall Cafeteria',
      campus: Campus.seunghak,
      hours: [ServiceHours(open: '11:40', close: '13:30')],
      hoursKo: '점심만 운영',
      hoursEn: 'Lunch only',
      facilityId: 's08',
      order: 1,
    ),
    MockCafeteriaInfo(
      id: 'seunghak-student',
      nameKo: '학생회관 식당',
      nameEn: 'Student Union Cafeteria',
      campus: Campus.seunghak,
      hours: [
        ServiceHours(open: '09:00', close: '09:30'),
        ServiceHours(open: '10:00', close: '14:30'),
        ServiceHours(open: '15:00', close: '16:30'),
      ],
      hoursKo: '천원의아침밥 09:00부터 선착순',
      hoursEn: '₩1,000 breakfast from 09:00, first come first served',
      facilityId: 's02',
      order: 2,
    ),
    MockCafeteriaInfo(
      id: 'seunghak-engineering',
      nameKo: '공과대학 식당',
      nameEn: 'Engineering Cafeteria',
      campus: Campus.seunghak,
      hours: [],
      hoursKo: '운영시간 미표기',
      hoursEn: 'Hours not published',
      facilityId: null,
      order: 3,
    ),
    MockCafeteriaInfo(
      id: 'seunghak-library',
      nameKo: '도서관 식당',
      nameEn: 'Library Cafeteria',
      campus: Campus.seunghak,
      hours: [
        ServiceHours(open: '09:00', close: '10:00'),
        ServiceHours(open: '10:40', close: '15:00'),
        ServiceHours(open: '15:40', close: '16:40'),
      ],
      hoursKo: null,
      hoursEn: null,
      facilityId: 's10',
      order: 4,
    ),
    MockCafeteriaInfo(
      id: 'bumin-international',
      nameKo: '국제관 식당',
      nameEn: 'International Hall Cafeteria',
      campus: Campus.bumin,
      hours: [],
      hoursKo: '점심 정식·일품',
      hoursEn: 'Lunch set menu and a la carte',
      facilityId: 'b05',
      order: 1,
    ),
    MockCafeteriaInfo(
      id: 'bumin-dorm',
      nameKo: '국제관 기숙사 식당',
      nameEn: 'International Hall Dormitory Cafeteria',
      campus: Campus.bumin,
      hours: [ServiceHours(open: '16:50', close: '18:40')],
      hoursKo: '천원의아침밥 09:20부터 선착순, 저녁 운영',
      hoursEn:
          '₩1,000 breakfast from 09:20, first come first served; dinner service',
      facilityId: 'b05',
      order: 2,
    ),
    MockCafeteriaInfo(
      id: 'gudeok-student',
      nameKo: '구덕 제2캠퍼스 학생회관',
      nameEn: 'Gudeok Student Union Cafeteria',
      campus: Campus.gudeok,
      hours: [],
      hoursKo: '덮밥·분식류',
      hoursEn: 'Rice bowls and snacks',
      facilityId: 'g12',
      order: 3,
    ),
    MockCafeteriaInfo(
      id: 'bumin-staff',
      nameKo: '부민 교직원 식당',
      nameEn: 'Bumin Faculty Cafeteria',
      campus: Campus.bumin,
      hours: [ServiceHours(open: '11:00', close: '13:50')],
      hoursKo: null,
      hoursEn: null,
      facilityId: null,
      order: 4,
    ),
  ];

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    await Future<void>.delayed(latency);
    final day = _Day(date);
    return [
      for (final c in cafeterias)
        switch (_dayMenu(c.id, day)) {
          (final status, final sections) => CafeteriaMenu(
              id: c.id,
              nameKo: c.nameKo,
              nameEn: c.nameEn,
              campus: c.campus,
              sections: sections,
              serviceHours: c.hours,
              hoursKo: c.hoursKo,
              hoursEn: c.hoursEn,
              facilityId: c.facilityId,
              order: c.order,
              status: status,
            ),
        },
    ];
  }

  /// The day's status + sections for one cafeteria. Weekends: everything is
  /// `closed` except 학생회관's Saturday lunch (a-la-carte only). 공과대학
  /// serves lunch only on Tue/Thu; the other weekdays it has nothing posted
  /// (`unpublished`, never `open` with no sections).
  static (DiningAvailability, List<MenuSection>) _dayMenu(String id, _Day d) {
    const open = DiningAvailability.open;
    const closed = DiningAvailability.closed;
    if (d.isSunday) return (closed, const []);
    if (d.isSaturday) {
      return id == 'seunghak-student'
          ? (open, [_priced(MealSlot.lunch, MenuKind.alacarte, _studentSatLunch)])
          : (closed, const []);
    }
    final sections = switch (id) {
      'seunghak-faculty' => [
          _set(MealSlot.lunch, 7000, d.pick(_facultyLunch),
              note: d.seed % 3 == 0 ? '셀프바' : null),
        ],
      'seunghak-student' => [
          _priced(MealSlot.breakfast, MenuKind.thousandWon,
              [(d.pick(_studentBreakfast), null)],
              price: 1000, note: '09:00부터 선착순'),
          _set(MealSlot.allDay, 6000, d.pick(_studentSet)),
          _priced(MealSlot.allDay, MenuKind.alacarte, d.pick(_studentAlacarte)),
          _priced(MealSlot.allDay, MenuKind.snack, d.pick(_studentSnack)),
        ],
      'seunghak-engineering' => d.isTuesday || d.isThursday
          ? [
              _priced(MealSlot.lunch, MenuKind.alacarte,
                  _engineeringLunch[d.engineeringSeed % _engineeringLunch.length]),
            ]
          : const <MenuSection>[],
      'seunghak-library' => [
          _set(MealSlot.allDay, 6500, d.pick(_librarySet)),
          _priced(MealSlot.allDay, MenuKind.alacarte, d.pick(_libraryAlacarte)),
        ],
      'bumin-international' => [
          _set(MealSlot.lunch, 6500, d.pick(_internationalSet)),
          _priced(
              MealSlot.lunch, MenuKind.alacarte, d.pick(_internationalAlacarte)),
        ],
      'bumin-dorm' => [
          _priced(MealSlot.breakfast, MenuKind.thousandWon,
              [(d.pick(_dormBreakfast), null)],
              price: 1000, note: '09:20부터 선착순'),
          _set(MealSlot.dinner, 5500, d.pick(_dormDinner)),
        ],
      'gudeok-student' => [
          _priced(MealSlot.lunch, MenuKind.alacarte, d.pick(_gudeokAlacarte)),
          _priced(MealSlot.lunch, MenuKind.snack, d.pick(_gudeokSnack)),
        ],
      'bumin-staff' => [
          _set(MealSlot.lunch, 7000, d.pick(_staffLunch)),
        ],
      _ => const <MenuSection>[],
    };
    return (
      sections.isEmpty ? DiningAvailability.unpublished : open,
      sections,
    );
  }

  static MenuSection _set(MealSlot slot, int price, List<String> items,
          {String? note}) =>
      MenuSection(
        slot: slot,
        kind: MenuKind.set,
        price: price,
        note: note,
        items: [for (final n in items) MenuItem(name: n)],
      );

  static MenuSection _priced(
          MealSlot slot, MenuKind kind, List<(String, int?)> items,
          {int? price, String? note}) =>
      MenuSection(
        slot: slot,
        kind: kind,
        price: price,
        note: note,
        items: [for (final (n, p) in items) MenuItem(name: n, price: p)],
      );

  // ───────────────────────── menu pools (Korean, as served) ─────────────────

  /// 교수회관 점심 정식 7,000: 국 · 메인 · 곁반찬 2 · 김치.
  static const _facultyLunch = [
    ['소고기미역국', '제육볶음', '계란찜', '콩나물무침', '배추김치'],
    ['된장찌개', '고등어구이', '두부조림', '시금치나물', '깍두기'],
    ['육개장', '닭갈비', '감자채볶음', '오이무침', '배추김치'],
    ['순두부찌개', '불고기', '어묵볶음', '도라지무침', '열무김치'],
    ['북엇국', '등심돈까스', '양배추샐러드', '단무지무침', '배추김치'],
    ['김치찌개', '삼치구이', '메추리알장조림', '숙주나물', '깍두기'],
    ['갈비탕', '오징어볶음', '애호박전', '무생채', '배추김치'],
  ];

  /// 학생회관 천원의아침밥 — one dish a day.
  static const _studentBreakfast = [
    '훈제오리솥밥',
    '닭갈비덮밥',
    '참치김치볶음밥',
    '소고기국밥',
    '치즈불닭덮밥',
    '베이컨에그샌드위치',
    '스팸김치볶음밥',
  ];

  /// 학생회관 종일 정식 6,000.
  static const _studentSet = [
    ['뚝배기불고기', '쌀밥', '미소된장국', '오이무침', '배추김치'],
    ['고추장제육볶음', '쌀밥', '콩나물국', '계란말이', '깍두기'],
    ['치킨까스', '쌀밥', '크림스프', '양배추샐러드', '단무지'],
    ['닭볶음탕', '쌀밥', '어묵국', '감자채볶음', '배추김치'],
    ['오징어덮밥', '유부장국', '멸치볶음', '열무김치'],
    ['돼지김치찌개', '쌀밥', '계란찜', '김', '깍두기'],
  ];

  /// 학생회관 종일 일품 — priced per dish.
  static const List<List<(String, int?)>> _studentAlacarte = [
    [('돼지국밥', 6000), ('등심돈까스', 7500), ('연어포케', 9000), ('리코타샐러드', 5500)],
    [('소고기국밥', 6500), ('치즈돈까스', 8000), ('참치포케', 8500), ('닭가슴살샐러드', 5500)],
    [('순대국밥', 6000), ('등심돈까스', 7500), ('새우포케', 9000), ('시저샐러드', 5500)],
    [('육개장', 6500), ('생선까스', 7000), ('연어포케', 9000), ('리코타샐러드', 5500)],
    [('돼지국밥', 6000), ('카레돈까스', 8000), ('불고기포케', 8500), ('그릭샐러드', 6000)],
  ];

  /// 학생회관 종일 양분식.
  static const List<List<(String, int?)>> _studentSnack = [
    [('야채김밥', 3500), ('참치김밥', 4000), ('핫도그', 2500), ('라면', 4000)],
    [('야채김밥', 3500), ('치즈김밥', 4000), ('핫도그', 2500), ('치즈라면', 4500)],
  ];

  /// 학생회관 토요일 점심 일품.
  static const List<(String, int?)> _studentSatLunch = [
    ('돼지국밥', 6000),
    ('등심돈까스', 7500),
  ];

  /// 공과대학 점심 일품 (Tue/Thu only), 1–2 dishes.
  static const List<List<(String, int?)>> _engineeringLunch = [
    [('치킨마요덮밥', 5500), ('제육덮밥', 6000)],
    [('돈까스카레', 6500)],
    [('김치제육덮밥', 6000), ('참치마요덮밥', 5500)],
    [('불고기덮밥', 6500)],
    [('오므라이스', 6000), ('새우볶음밥', 6000)],
  ];

  /// 도서관 종일 정식 6,500.
  static const _librarySet = [
    ['돼지불백', '쌀밥', '된장국', '숙주나물', '배추김치'],
    ['고등어조림', '쌀밥', '미역국', '시금치나물', '깍두기'],
    ['함박스테이크', '쌀밥', '양송이스프', '마카로니샐러드', '단무지'],
    ['닭갈비', '쌀밥', '콩나물국', '감자조림', '배추김치'],
    ['동태찌개', '쌀밥', '계란말이', '무말랭이', '깍두기'],
    ['소불고기', '쌀밥', '북엇국', '브로콜리무침', '배추김치'],
  ];

  /// 도서관 종일 일품 2개.
  static const List<List<(String, int?)>> _libraryAlacarte = [
    [('라볶이', 5000), ('돈까스', 6500)],
    [('치즈라면', 4500), ('김치볶음밥', 5500)],
    [('제육덮밥', 6000), ('우동', 5000)],
    [('카레라이스', 5500), ('치킨마요덮밥', 5500)],
    [('비빔국수', 5000), ('돈까스', 6500)],
  ];

  /// 국제관 점심 정식 6,500.
  static const _internationalSet = [
    ['매콤닭갈비', '쌀밥', '팽이버섯된장국', '오이무침', '배추김치'],
    ['소고기버섯전골', '쌀밥', '계란찜', '연근조림', '깍두기'],
    ['치킨가라아게', '쌀밥', '미소국', '양배추샐러드', '단무지'],
    ['제육볶음', '쌀밥', '근대된장국', '어묵볶음', '배추김치'],
    ['코다리조림', '쌀밥', '뭇국', '호박볶음', '열무김치'],
    ['함박스테이크', '쌀밥', '옥수수스프', '감자샐러드', '깍두기'],
  ];

  /// 국제관 점심 일품 2–3개.
  static const List<List<(String, int?)>> _internationalAlacarte = [
    [('돈까스', 7000), ('쌀국수', 7500), ('마라탕', 8500)],
    [('치즈돈까스', 7500), ('해물볶음우동', 7500)],
    [('돈까스', 7000), ('나시고렝', 7500), ('짜장면', 6000)],
    [('카레우동', 7000), ('비빔밥', 6500)],
    [('돈까스', 7000), ('팟타이', 7500), ('마라샹궈', 9000)],
  ];

  /// 국제관 기숙사 천원의아침밥.
  static const _dormBreakfast = [
    '소고기죽',
    '토스트와 스크램블에그',
    '참치마요주먹밥',
    '김치볶음밥',
    '불고기덮밥',
    '치즈계란밥',
  ];

  /// 국제관 기숙사 저녁 정식 5,500.
  static const _dormDinner = [
    ['돼지김치찌개', '쌀밥', '계란말이', '김', '깍두기'],
    ['닭볶음탕', '쌀밥', '콩나물무침', '배추김치'],
    ['카레라이스', '미소국', '단무지', '요구르트'],
    ['순두부찌개', '쌀밥', '어묵볶음', '배추김치'],
    ['제육볶음', '쌀밥', '미역국', '상추쌈', '깍두기'],
    ['부대찌개', '쌀밥', '감자채볶음', '배추김치'],
  ];

  /// 구덕 학생회관 점심 일품 — 덮밥류 5,500~6,500.
  static const List<List<(String, int?)>> _gudeokAlacarte = [
    [('제육덮밥', 6000), ('치킨마요덮밥', 5500)],
    [('불고기덮밥', 6500), ('참치김치덮밥', 5500)],
    [('오징어덮밥', 6500), ('카레덮밥', 5500)],
    [('돈까스덮밥', 6500), ('마파두부덮밥', 5500)],
    [('낙지덮밥', 6500), ('계란덮밥', 5500)],
  ];

  /// 구덕 학생회관 점심 양분식.
  static const List<List<(String, int?)>> _gudeokSnack = [
    [('떡볶이', 4000), ('야채김밥', 3500), ('라면', 4000)],
    [('라볶이', 4500), ('참치김밥', 4000), ('우동', 4500)],
  ];

  /// 부민 교직원 점심 정식 7,000.
  static const _staffLunch = [
    ['소고기뭇국', '돼지갈비찜', '잡채', '취나물', '배추김치'],
    ['된장찌개', '가자미구이', '두부양념조림', '콩나물무침', '깍두기'],
    ['미역국', '닭다리구이', '마카로니샐러드', '고사리나물', '배추김치'],
    ['육개장', '임연수구이', '애호박볶음', '도토리묵무침', '열무김치'],
    ['순두부찌개', '소불고기', '시금치나물', '메추리알장조림', '깍두기'],
    ['시래기된장국', '제육볶음', '계란찜', '무생채', '배추김치'],
  ];
}

/// Static cafeteria info (what the `cafeterias` Firestore doc carries).
class MockCafeteriaInfo {
  const MockCafeteriaInfo({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.campus,
    required this.hours,
    required this.hoursKo,
    required this.hoursEn,
    required this.facilityId,
    required this.order,
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final Campus campus;
  final List<ServiceHours> hours;
  final String? hoursKo;
  final String? hoursEn;
  final String? facilityId;
  final int order;
}

/// Date → deterministic pool index. [seed] walks Mon..Fri through a pool and
/// advances by one each week, so a 5-day pool shows five different menus in
/// one week and a different alignment the next.
class _Day {
  _Day(DateTime date)
      : weekday = date.weekday,
        _weekIndex = (DateTime.utc(date.year, date.month, date.day)
                    .difference(_epoch)
                    .inDays /
                7)
            .floor();

  /// A Monday; only the alignment of week boundaries matters.
  static final _epoch = DateTime.utc(2026, 1, 5);

  final int weekday;
  final int _weekIndex;

  bool get isSaturday => weekday == DateTime.saturday;
  bool get isSunday => weekday == DateTime.sunday;
  bool get isTuesday => weekday == DateTime.tuesday;
  bool get isThursday => weekday == DateTime.thursday;

  int get seed => (weekday - 1) + _weekIndex;

  /// 공과대학 serves twice a week, so its pool advances per serving day.
  int get engineeringSeed => _weekIndex * 2 + (isThursday ? 1 : 0);

  T pick<T>(List<T> pool) => pool[seed % pool.length];
}
