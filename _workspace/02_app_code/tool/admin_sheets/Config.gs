const CONFIG = Object.freeze({
  projectId: 'campus-f4748',
  databaseId: '(default)',
  timeZone: 'Asia/Seoul',
  sheets: Object.freeze({
    academic: '학사일정',
    dining: '학식',
    cafeterias: '식당',
    example: '예시',
    guide: '안내',
  }),
  collections: Object.freeze({
    academicEvents: 'academic_events',
    diningMenus: 'dining_menus',
    cafeterias: 'cafeterias',
    syncRuns: 'admin_sync_runs',
  }),
  maxCommitWrites: 500,
  priceMin: 0,
  priceMax: 100000,
  orderMin: 0,
  orderMax: 9999,
});

// Korean sheet labels are mapped through these allowlists. Collection names and
// document ids are never accepted directly from arbitrary sheet cells.
const ACADEMIC_CATEGORIES = Object.freeze({
  '학사': 'semester',
  '수강': 'registration',
  '시험': 'exam',
  '휴일': 'holiday',
  '졸업': 'graduation',
});

// Serving slot of one menu section (app enum MealSlot).
const MEAL_SLOTS = Object.freeze({
  '아침': 'breakfast',
  '점심': 'lunch',
  '저녁': 'dinner',
  '종일': 'allDay',
});

// Kind of one menu section (app enum MenuKind). `set` and `thousandWon` carry a
// single section price; `alacarte` and `snack` price each item.
const MENU_KINDS = Object.freeze({
  '정식': 'set',
  '일품': 'alacarte',
  '양분식': 'snack',
  '천원의아침밥': 'thousandWon',
});

const SECTION_PRICED_KINDS = Object.freeze(['set', 'thousandWon']);

const CAMPUSES = Object.freeze({
  '승학': 'seunghak',
  '구덕': 'gudeok',
  '부민': 'bumin',
});

const DINING_STATUSES = Object.freeze({
  '게시': 'open',
  '휴무': 'closed',
  '게시취소': 'unpublished',
});

// Cafeteria ids come from the "식당" tab, never from free text in the "학식" tab:
// the dining tab references a cafeteria by its Korean name and the id is looked
// up from the validated cafeteria rows. The id itself must match this pattern.
const CAFETERIA_ID_PATTERN = /^[a-z0-9-]+$/;
const FACILITY_ID_PATTERN = /^[a-z0-9-]+$/;

const ACADEMIC_HEADERS = Object.freeze([
  '시작일', '종료일(선택)', '일정명(국문)', '일정명(영문)', '분류',
  '동기화 결과', 'event_id',
]);
const ACADEMIC_RESULT_COLUMN = 6;

// "학식" tab. One row = one section (slot × kind) of one cafeteria on one day.
const DINING_HEADERS = Object.freeze([
  '날짜', '식당', '시간대', '유형', '메뉴', '가격', '비고', '상태', '동기화 결과',
]);
const DINING_COL = Object.freeze({
  date: 0, cafeteria: 1, slot: 2, kind: 3, menu: 4, price: 5, note: 6, status: 7, result: 8,
});
const DINING_RESULT_COLUMN = DINING_COL.result + 1; // 1-based sheet column (9)

// Pre-redesign "학식" layout. Setup migrates a sheet whose header still matches
// this: 식사 → 시간대 (조식/중식/석식 → 아침/점심/저녁), 유형 = 정식, 비고 inserted.
const LEGACY_DINING_HEADERS = Object.freeze([
  '날짜', '식당', '식사', '메뉴 (쉼표로 구분)', '가격', '상태', '동기화 결과',
]);
const LEGACY_MEAL_LABELS = Object.freeze({ '조식': '아침', '중식': '점심', '석식': '저녁' });
const LEGACY_CAFETERIA_LABELS = Object.freeze({
  '승학 학생식당': '학생회관 식당',
  '구덕 학생식당': '구덕 제2캠퍼스 학생회관',
  // '부민 학생식당' no longer exists as one cafeteria; rows keep the old label and
  // fail validation so the admin picks 국제관 식당 / 부민 교직원 식당 explicitly.
});

// "식당" tab. Whole tab = the `cafeterias` collection (full replace on sync).
const CAFETERIA_HEADERS = Object.freeze([
  '식당ID', '이름(국문)', '이름(영문)', '캠퍼스', '운영시간',
  '운영 비고(국문)', '운영 비고(영문)', '지도 건물ID', '표시 순서', '동기화 결과',
]);
const CAFETERIA_COL = Object.freeze({
  id: 0, nameKo: 1, nameEn: 2, campus: 3, hours: 4, hoursKo: 5, hoursEn: 6,
  facilityId: 7, order: 8, result: 9,
});
const CAFETERIA_RESULT_COLUMN = CAFETERIA_COL.result + 1; // 1-based sheet column (10)

// Canonical cafeteria list written by Setup when the "식당" tab is created or empty.
// Columns follow CAFETERIA_HEADERS without the result column.
const DEFAULT_CAFETERIAS = Object.freeze([
  ['seunghak-faculty', '교수회관 식당', 'Faculty Hall Cafeteria', '승학', '11:40-13:30', '점심만 운영', 'Lunch only', 's08', 1],
  ['seunghak-student', '학생회관 식당', 'Student Union Cafeteria', '승학', '09:00-09:30, 10:00-14:30, 15:00-16:30', '천원의아침밥 09:00부터 선착순', '₩1,000 breakfast from 09:00, first come', 's02', 2],
  ['seunghak-engineering', '공과대학 식당', 'Engineering Cafeteria', '승학', '', '운영시간 미표기', 'Hours not published', '', 3],
  ['seunghak-library', '도서관 식당', 'Library Cafeteria', '승학', '09:00-10:00, 10:40-15:00, 15:40-16:40', '', '', 's10', 4],
  ['bumin-international', '국제관 식당', 'International Hall Cafeteria', '부민', '', '점심 정식·일품', 'Lunch set & à la carte', 'b05', 1],
  ['bumin-dorm', '국제관 기숙사 식당', 'International Hall Dormitory Cafeteria', '부민', '16:50-18:40', '천원의아침밥 09:20부터 선착순, 저녁 운영', '₩1,000 breakfast from 09:20, dinner', 'b05', 2],
  ['gudeok-student', '구덕 제2캠퍼스 학생회관', 'Gudeok Student Union Cafeteria', '구덕', '', '덮밥·분식류', 'Rice bowls & snacks', 'g12', 3],
  ['bumin-staff', '부민 교직원 식당', 'Bumin Faculty Cafeteria', '부민', '11:00-13:50', '', '', '', 4],
]);

// Sample rows for the "예시" tab (never synced). Columns follow DINING_HEADERS
// without the result column; dates are [year, month(1-12), day].
const EXAMPLE_NOTICE = '이 탭은 예시이며 동기화되지 않습니다. 행을 복사해 "학식" 탭에 붙여 넣고 날짜·메뉴를 고쳐 쓰세요.';
const EXAMPLE_DINING_ROWS = Object.freeze([
  // 2026-10-13 (월)
  [[2026, 10, 13], '교수회관 식당', '점심', '정식', '제육볶음\n미역국\n밥\n배추김치', 7000, '셀프바', '게시'],
  [[2026, 10, 13], '학생회관 식당', '아침', '천원의아침밥', '훈제오리솥밥', 1000, '09:00부터 선착순', '게시'],
  [[2026, 10, 13], '학생회관 식당', '종일', '정식', '돈육김치찌개\n계란말이\n밥\n깍두기', 6000, '', '게시'],
  [[2026, 10, 13], '학생회관 식당', '종일', '일품', '국밥 6000\n돈까스 7500\n연어포케 9000', '', '', '게시'],
  [[2026, 10, 13], '학생회관 식당', '종일', '양분식', '김밥 3500\n핫도그 2500', '', '', '게시'],
  [[2026, 10, 13], '공과대학 식당', '점심', '일품', '치킨마요덮밥 5500', '', '', '게시'],
  [[2026, 10, 13], '도서관 식당', '종일', '정식', '순두부찌개\n오징어볶음\n밥\n김치', 6000, '', '게시'],
  [[2026, 10, 13], '도서관 식당', '종일', '일품', '라면 4000\n비빔밥 5500', '', '', '게시'],
  [[2026, 10, 13], '국제관 식당', '점심', '정식', '불고기\n된장국\n밥\n김치', 6500, '', '게시'],
  [[2026, 10, 13], '국제관 식당', '점심', '일품', '카레라이스 6000\n우동 5000', '', '', '게시'],
  [[2026, 10, 13], '국제관 기숙사 식당', '아침', '천원의아침밥', '참치김치볶음밥', 1000, '09:20부터 선착순', '게시'],
  [[2026, 10, 13], '국제관 기숙사 식당', '저녁', '정식', '닭갈비\n콩나물국\n밥\n김치', 5500, '', '게시'],
  [[2026, 10, 13], '구덕 제2캠퍼스 학생회관', '점심', '일품', '불고기덮밥 6000\n오징어덮밥 6000', '', '', '게시'],
  [[2026, 10, 13], '구덕 제2캠퍼스 학생회관', '점심', '양분식', '떡볶이 4000\n김밥 3000', '', '', '게시'],
  [[2026, 10, 13], '부민 교직원 식당', '점심', '정식', '갈치조림\n시금치나물\n밥\n김치', 7000, '', '게시'],
  // 2026-10-14 (화)
  [[2026, 10, 14], '교수회관 식당', '점심', '정식', '소불고기\n북엇국\n밥\n김치', 7000, '셀프바', '게시'],
  [[2026, 10, 14], '학생회관 식당', '아침', '천원의아침밥', '소고기무국 정식', 1000, '09:00부터 선착순', '게시'],
  [[2026, 10, 14], '학생회관 식당', '종일', '정식', '제육볶음\n계란국\n밥\n김치', 6000, '', '게시'],
  [[2026, 10, 14], '학생회관 식당', '종일', '일품', '국밥 6000\n치즈돈까스 8000\n연어포케 9000', '', '', '게시'],
  [[2026, 10, 14], '학생회관 식당', '종일', '양분식', '참치김밥 4000\n핫도그 2500', '', '', '게시'],
  [[2026, 10, 14], '공과대학 식당', '점심', '일품', '제육덮밥 5500', '', '', '게시'],
  [[2026, 10, 14], '도서관 식당', '종일', '정식', '김치찌개\n생선까스\n밥\n김치', 6000, '', '게시'],
  [[2026, 10, 14], '도서관 식당', '종일', '일품', '라면 4000\n김치볶음밥 5000', '', '', '게시'],
  [[2026, 10, 14], '국제관 식당', '점심', '정식', '닭볶음탕\n미역국\n밥\n김치', 6500, '', '게시'],
  [[2026, 10, 14], '국제관 식당', '점심', '일품', '돈까스 6500\n잔치국수 4500', '', '', '게시'],
  [[2026, 10, 14], '국제관 기숙사 식당', '아침', '천원의아침밥', '햄치즈토스트', 1000, '09:20부터 선착순', '게시'],
  [[2026, 10, 14], '국제관 기숙사 식당', '저녁', '정식', '순살치킨\n떡국\n밥\n김치', 5500, '', '게시'],
  [[2026, 10, 14], '구덕 제2캠퍼스 학생회관', '점심', '일품', '치킨마요덮밥 6000\n돈까스덮밥 6500', '', '', '게시'],
  [[2026, 10, 14], '구덕 제2캠퍼스 학생회관', '점심', '양분식', '라볶이 4500\n김밥 3000', '', '', '게시'],
  // 휴무 예시: 시간대·유형·메뉴·가격·비고는 비움, 그룹당 1행
  [[2026, 10, 14], '부민 교직원 식당', '', '', '', '', '', '휴무'],
]);
