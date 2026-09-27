/* Regression tests for the academic-calendar sheet plumbing.
 *
 * Run: python tool/admin_sheets/test/run_in_chrome.py
 * (Apps Script has no test runner and this machine has no Node, so the suite
 * runs in Chrome. It is not part of `flutter test`.)
 *
 * Two of these guard defects found by review (B 03/063):
 *   B-01  the header row was overwritten with the wider schema while the data
 *         columns stayed put, so every row read one field to the left;
 *   B-02  the legacy fallback fired on a partial header and then trusted the
 *         old positions, so a generated event_id could land on 분류.
 * Both are checked against the current code AND against a reconstruction of the
 * code as it was before the fix, so the suite is known to catch them.
 */

var LEGACY_HEADER = ['시작일', '종료일(선택)', '일정명(국문)', '일정명(영문)', '분류',
  '동기화 결과', 'event_id'];
var NEW_HEADER = ['시작일', '종료일(선택)', '일정명(국문)', '일정명(영문)',
  '일정명(중문)', '일정명(베트남어)', '분류', '동기화 결과', 'event_id'];

// Sheets hands date cells back as Date objects, and validDate_ insists on it.
function d(iso) { return new Date(iso + 'T00:00:00Z'); }

var UUID_A = 'aaaaaaaa-1111-2222-3333-444444444444';
var UUID_B = 'bbbbbbbb-1111-2222-3333-444444444444';

function legacySheet() {
  return new FakeSheet('학사일정', [
    LEGACY_HEADER.slice(),
    [d('2026-08-10'), d('2026-08-14'), '2학기 수강신청', 'Fall course registration', '수강', '', UUID_A],
    [d('2026-09-01'), '', '2학기 개강', 'Fall semester begins', '학사', '', UUID_B],
  ]);
}

function newSheet(extra) {
  var rows = [
    NEW_HEADER.slice(),
    [d('2026-08-10'), d('2026-08-14'), '2학기 수강신청', 'Fall course registration',
      '2学期选课', 'Đăng ký môn học kỳ 2', '수강', '', UUID_A],
    [d('2026-09-01'), '', '2학기 개강', 'Fall semester begins', '', '', '학사', '', UUID_B],
  ];
  if (extra) rows.push(extra);
  return new FakeSheet('학사일정', rows);
}

function withSheet(sheet, fn) {
  var ss = new FakeSpreadsheet({ '학사일정': sheet });
  installGlobals(window, ss);
  return fn(ss, sheet);
}

var SUITE = [
  {
    name: 'legacy 7-column sheet still reads, with no translations',
    run: function (t) {
      withSheet(legacySheet(), function () {
        var parsed = readAcademicRows_();
        t.equal(parsed.rows.length, 2, 'two rows read');
        t.equal(parsed.errors.length, 0, 'no validation errors');
        t.equal(parsed.rows[0].id, UUID_A, 'event_id preserved');
        t.equal(parsed.rows[0].data.title_ko, '2학기 수강신청', 'Korean title');
        t.equal(parsed.rows[0].data.title_en, 'Fall course registration', 'English title');
        t.equal(parsed.rows[0].data.category, 'registration', 'category mapped');
        t.equal(parsed.rows[0].data.start, '2026-08-10', 'start date');
        t.equal(parsed.rows[0].data.end, '2026-08-14', 'end date');
        t.deepEqual(parsed.rows[0].data.i18n, {}, 'no translations on a legacy sheet');
      });
    },
  },
  {
    name: 'new 9-column sheet reads Korean, English and both translations',
    run: function (t) {
      withSheet(newSheet(), function () {
        var parsed = readAcademicRows_();
        t.equal(parsed.errors.length, 0, 'no validation errors');
        t.deepEqual(parsed.rows[0].data.i18n,
          { zh: { title: '2学期选课' }, vi: { title: 'Đăng ký môn học kỳ 2' } },
          'both translations carried');
        t.deepEqual(parsed.rows[1].data.i18n, {},
          'a row with empty translation cells carries none');
        t.equal(parsed.rows[1].data.title_ko, '2학기 개강', 'Korean still read');
        t.equal(parsed.rows[0].data.category, 'registration',
          'category comes from its own column, not the one next to it');
      });
    },
  },
  {
    name: 'columns are found by name even when they are reordered',
    run: function (t) {
      var header = ['event_id', '분류', '시작일', '종료일(선택)', '일정명(국문)',
        '일정명(영문)', '일정명(중문)', '일정명(베트남어)', '동기화 결과'];
      var sheet = new FakeSheet('학사일정', [
        header,
        [UUID_A, '시험', d('2026-10-20'), d('2026-10-26'), '중간시험', 'Midterm exams',
          '期中考试', 'Thi giữa kỳ', ''],
      ]);
      withSheet(sheet, function () {
        var parsed = readAcademicRows_();
        t.equal(parsed.errors.length, 0, 'no errors');
        t.equal(parsed.rows[0].id, UUID_A, 'id from its column');
        t.equal(parsed.rows[0].data.category, 'exam', 'category from its column');
        t.deepEqual(parsed.rows[0].data.i18n,
          { zh: { title: '期中考试' }, vi: { title: 'Thi giữa kỳ' } }, 'translations');
      });
    },
  },
  // ------------------------------------------------------- event_id creation
  {
    name: 'a generated event_id lands in the event_id column and nowhere else',
    run: function (t) {
      // B 03/063 B-02: with a loose legacy fallback this wrote over 분류.
      var sheet = newSheet([d('2026-12-08'), d('2026-12-14'), '기말시험', 'Final exams',
        '期末考试', 'Thi cuối kỳ', '시험', '', '']);
      withSheet(sheet, function () {
        readAcademicRows_();
        var idCol = NEW_HEADER.indexOf('event_id') + 1;
        t.equal(sheet.writes.length, 1, 'exactly one cell written');
        t.equal(sheet.writes[0].col, idCol, 'written to the event_id column');
        t.equal(sheet.writes[0].row, 4, 'written to the row that was missing one');
        t.equal(sheet.grid[3][NEW_HEADER.indexOf('분류')], '시험',
          'the category cell is untouched');
      });
    },
  },
  {
    name: 'a partial header stops before touching anything',
    run: function (t) {
      // event_id removed from an otherwise 9-column sheet. The old code took
      // this for a legacy sheet and wrote a UUID into 분류 (B 03/063 B-02).
      var header = NEW_HEADER.slice();
      header[header.indexOf('event_id')] = '';
      var sheet = new FakeSheet('학사일정', [
        header,
        [d('2026-08-10'), d('2026-08-14'), '2학기 수강신청', 'Fall course registration',
          '2学期选课', 'Đăng ký môn học kỳ 2', '수강', '', ''],
      ]);
      withSheet(sheet, function () {
        var threw = null;
        try { readAcademicRows_(); } catch (e) { threw = e; }
        t.ok(threw, 'it refuses to guess');
        t.ok(String(threw.message).indexOf('event_id') >= 0,
          'the message names the missing header');
        t.equal(sheet.writes.length, 0, 'nothing was written');
      });
    },
  },
  {
    name: 'an unrecognised header stops before touching anything',
    run: function (t) {
      var sheet = new FakeSheet('학사일정', [
        ['날짜', '제목', '메모'],
        [d('2026-08-10'), '무언가', ''],
      ]);
      withSheet(sheet, function () {
        var threw = null;
        try { readAcademicRows_(); } catch (e) { threw = e; }
        t.ok(threw, 'it refuses to read a sheet it does not recognise');
        t.equal(sheet.writes.length, 0, 'nothing was written');
      });
    },
  },
  // ---------------------------------------------------------- the migration
  {
    name: 'setup migrates a legacy sheet by inserting columns, keeping values',
    run: function (t) {
      // B 03/063 B-01: the old code wrote the wide header over a 7-column
      // sheet, so 분류 / 동기화 결과 / event_id were read one column to the left.
      var sheet = legacySheet();
      withSheet(sheet, function (ss) {
        migrateAcademicHeaders_(ss);
        setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
        t.equal(sheet.insertedColumns.length, 1, 'two columns inserted once');
        t.equal(sheet.insertedColumns[0].after, 4, 'inserted after 일정명(영문)');
        t.equal(sheet.insertedColumns[0].count, 2, 'two of them');
        t.deepEqual(sheet.grid[0].slice(0, 9), NEW_HEADER, 'header is the new one');

        var parsed = readAcademicRows_();
        t.equal(parsed.errors.length, 0, 'the migrated sheet still validates');
        t.equal(parsed.rows.length, 2, 'both rows survive');
        t.equal(parsed.rows[0].id, UUID_A, 'event_id preserved through the move');
        t.equal(parsed.rows[1].id, UUID_B, 'second event_id preserved');
        t.equal(parsed.rows[0].data.category, 'registration', 'category preserved');
        t.equal(parsed.rows[0].data.title_ko, '2학기 수강신청', 'Korean title preserved');
        t.equal(parsed.rows[0].data.end, '2026-08-14', 'end date preserved');
        t.deepEqual(parsed.rows[0].data.i18n, {}, 'the new columns start empty');
      });
    },
  },
  {
    name: 'running setup again does not insert the columns twice',
    run: function (t) {
      var sheet = legacySheet();
      withSheet(sheet, function (ss) {
        migrateAcademicHeaders_(ss);
        setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
        migrateAcademicHeaders_(ss);
        setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
        migrateAcademicHeaders_(ss);
        t.equal(sheet.insertedColumns.length, 1, 'still just the one insert');
        t.equal(sheet.getLastColumn(), 9, 'still nine columns');
        t.deepEqual(sheet.grid[0].slice(0, 9), NEW_HEADER, 'header unchanged');
        var parsed = readAcademicRows_();
        t.equal(parsed.rows[0].id, UUID_A, 'data still intact after three runs');
      });
    },
  },
  {
    name: 'setup refuses a sheet whose header it does not recognise',
    run: function (t) {
      var sheet = new FakeSheet('학사일정', [
        ['날짜', '제목', '분류', '메모'],
        [d('2026-08-10'), '무언가', '수강', ''],
      ]);
      withSheet(sheet, function (ss) {
        var threw = null;
        try { migrateAcademicHeaders_(ss); } catch (e) { threw = e; }
        t.ok(threw, 'it stops');
        t.equal(sheet.insertedColumns.length, 0, 'no columns inserted');
        t.equal(sheet.writes.length, 0, 'nothing written');
      });
    },
  },
  {
    name: 'an empty sheet is set up directly, with no migration',
    run: function (t) {
      var sheet = new FakeSheet('학사일정', [[]]);
      withSheet(sheet, function (ss) {
        migrateAcademicHeaders_(ss);
        setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
        t.equal(sheet.insertedColumns.length, 0, 'nothing to migrate');
        t.deepEqual(sheet.grid[0].slice(0, 9), NEW_HEADER, 'header written');
      });
    },
  },
  // ------------------------------------------------------ clearing a value
  {
    name: 'clearing a translation cell clears it in the document too',
    run: function (t) {
      var sheet = newSheet();
      // the admin deletes the Chinese title
      sheet.grid[1][NEW_HEADER.indexOf('일정명(중문)')] = '';
      withSheet(sheet, function () {
        var parsed = readAcademicRows_();
        t.deepEqual(parsed.rows[0].data.i18n, { vi: { title: 'Đăng ký môn học kỳ 2' } },
          'only Vietnamese remains, and the whole document is rewritten');
      });
    },
  },
];

/* The pre-fix implementations, so the suite can be shown to catch the two
 * BLOCKERs rather than merely agreeing with today's code. */
function installPreFix() {
  window.academicColumns_ = function (sheet) {
    var width = Math.max(sheet.getLastColumn(), ACADEMIC_HEADERS.length);
    var header = sheet.getRange(1, 1, 1, width).getValues()[0]
      .map(function (h) { return String(h == null ? '' : h).trim(); });
    var find = function (name) { return header.indexOf(name); };
    var cols = {};
    Object.keys(ACADEMIC_FIELDS).forEach(function (key) {
      cols[key] = find(ACADEMIC_FIELDS[key]);
    });
    if (cols.start < 0 || cols.titleKo < 0 || cols.id < 0) {   // the loose test
      ACADEMIC_HEADERS_LEGACY.forEach(function (name, i) {
        Object.keys(ACADEMIC_FIELDS).forEach(function (key) {
          if (ACADEMIC_FIELDS[key] === name) cols[key] = i;
        });
      });
      cols.titleZh = -1;
      cols.titleVi = -1;
    }
    cols.width = Math.max(width, ACADEMIC_HEADERS_LEGACY.length);
    return cols;
  };
  window.migrateAcademicHeaders_ = function () { /* the fix did not exist */ };
}
