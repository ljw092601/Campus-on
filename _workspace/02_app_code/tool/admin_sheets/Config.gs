const CONFIG = Object.freeze({
  projectId: 'campus-f4748',
  databaseId: '(default)',
  timeZone: 'Asia/Seoul',
  sheets: Object.freeze({
    academic: '학사일정',
    dining: '학식',
    guide: '안내',
  }),
  collections: Object.freeze({
    academicEvents: 'academic_events',
    diningMenus: 'dining_menus',
    syncRuns: 'admin_sync_runs',
  }),
  maxCommitWrites: 500,
  priceMin: 0,
  priceMax: 100000,
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

const CAFETERIAS = Object.freeze({
  '승학 학생식당': 'seunghak-student',
  '구덕 학생식당': 'gudeok-student',
  '부민 학생식당': 'bumin-student',
});

const MEAL_TYPES = Object.freeze({
  '조식': 'breakfast',
  '중식': 'lunch',
  '석식': 'dinner',
});

const DINING_STATUSES = Object.freeze({
  '게시': 'open',
  '휴무': 'closed',
  '게시취소': 'unpublished',
});

const ACADEMIC_HEADERS = Object.freeze([
  '시작일', '종료일(선택)', '일정명(국문)', '일정명(영문)', '분류',
  '동기화 결과', 'event_id',
]);

const DINING_HEADERS = Object.freeze([
  '날짜', '식당', '식사', '메뉴 (쉼표로 구분)', '가격', '상태',
  '동기화 결과',
]);
