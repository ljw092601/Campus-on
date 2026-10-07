import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

// Loads the Apps Script sources into one vm context with the few Apps Script
// globals the pure helpers touch stubbed out. Dates are formatted as UTC so the
// tests can build them with Date.UTC without depending on the host time zone.
function loadScripts(extraGlobals = {}) {
  const context = vm.createContext({
    // Share the host Date so `instanceof Date` checks in Validation.gs accept the
    // dates the tests build (Apps Script itself runs in a single realm).
    Date,
    Utilities: {
      formatDate: date => date.toISOString().slice(0, 10),
      getUuid: () => '00000000-0000-4000-8000-000000000000',
    },
    SpreadsheetApp: { getUi: () => ({}) },
    ...extraGlobals,
  });
  for (const file of ['Config.gs', 'Validation.gs', 'Setup.gs', 'Sync.gs']) {
    vm.runInContext(readFileSync(new URL(file, import.meta.url), 'utf8'), context, { filename: file });
  }
  // Top-level `const`s are lexical bindings, not context properties; expose the
  // ones the tests read next to the (global) functions.
  const constants = vm.runInContext(
    '({ DEFAULT_CAFETERIAS, EXAMPLE_DINING_ROWS, DINING_HEADERS, LEGACY_DINING_HEADERS })', context);
  return Object.assign(context, constants);
}

// Minimal in-memory sheet: enough of the Range/Sheet API for the migration code.
class FakeSheet {
  constructor(rows) {
    this.cells = rows.map(r => r.slice());
    this.cleared = [];
  }
  width() { return Math.max(...this.cells.map(r => r.length)); }
  getLastRow() {
    for (let i = this.cells.length - 1; i >= 0; i -= 1) {
      if (this.cells[i].some(v => v !== '' && v !== null && typeof v !== 'undefined')) return i + 1;
    }
    return 0;
  }
  getMaxRows() { return this.cells.length; }
  getMaxColumns() { return this.width(); }
  insertColumnsAfter(col, n) {
    this.cells.forEach(row => row.splice(col, 0, ...Array(n).fill('')));
  }
  getRange(row, col, numRows = 1, numCols = 1) {
    const sheet = this;
    const range = {
      getValues() {
        const out = [];
        for (let r = row - 1; r < row - 1 + numRows; r += 1) {
          out.push(Array.from({ length: numCols }, (_, c) => {
            const v = (sheet.cells[r] || [])[col - 1 + c];
            return typeof v === 'undefined' ? '' : v;
          }));
        }
        return out;
      },
      setValues(values) {
        values.forEach((vals, r) => vals.forEach((v, c) => {
          while (sheet.cells.length < row + r) sheet.cells.push([]);
          sheet.cells[row - 1 + r][col - 1 + c] = v;
        }));
        return range;
      },
      setValue(v) { return range.setValues([[v]]); },
      clearContent() {
        sheet.cleared.push({ row, col, numRows, numCols });
        for (let r = 0; r < numRows; r += 1) for (let c = 0; c < numCols; c += 1) sheet.cells[row - 1 + r][col - 1 + c] = '';
        return range;
      },
      setBackground() { return range; },
      setFontWeight() { return range; },
    };
    return range;
  }
}

const D = (y, m, d) => new Date(Date.UTC(y, m - 1, d));

// Values built inside the vm context have that realm's prototypes, so strict
// deepEqual against test-realm literals fails on the prototype check. Compare
// JSON-plain copies instead.
const plain = value => JSON.parse(JSON.stringify(value));
const eq = (actual, expected, message) => assert.deepEqual(plain(actual), plain(expected), message);

function cafeteriaIndex(ctx) {
  return ctx.cafeteriaIndex_(ctx.parseCafeteriaRows_(ctx.DEFAULT_CAFETERIAS.map(r => r.slice())));
}

// 날짜 | 식당 | 시간대 | 유형 | 메뉴 | 가격 | 비고 | 상태 | 동기화 결과
const row = (date, cafeteria, slot, kind, menu, price, note, status) =>
  [date, cafeteria, slot, kind, menu, price, note, status, ''];

// ---------------------------------------------------------------------------
// Menu item parsing
// ---------------------------------------------------------------------------

test('menu items split on newlines or commas and read a trailing price with commas/원', () => {
  const ctx = loadScripts();
  const errors = [];
  const items = ctx.parseMenuItems_('국밥 6000\n돈까스 7,500원, 연어포케 9000원\r\n김밥 3,500', errors);
  eq(errors, []);
  eq(items, [
    { name: '국밥', price: 6000 },
    { name: '돈까스', price: 7500 },
    { name: '연어포케', price: 9000 },
    { name: '김밥', price: 3500 },
  ]);
});

test('menu items without a trailing number carry no price', () => {
  const ctx = loadScripts();
  const errors = [];
  const items = ctx.parseMenuItems_('제육볶음\n미역국, 밥, 배추김치', errors);
  eq(errors, []);
  eq(items, [{ name: '제육볶음' }, { name: '미역국' }, { name: '밥' }, { name: '배추김치' }]);
});

test('menu items reject blank entries, nameless prices and out-of-range prices', () => {
  const ctx = loadScripts();
  let errors = [];
  ctx.parseMenuItems_('국밥,,밥', errors);
  assert.match(errors.join(' '), /빈 항목/);
  errors = [];
  ctx.parseMenuItems_('6000', errors);
  assert.match(errors.join(' '), /이름이 없습니다/);
  errors = [];
  ctx.parseMenuItems_('스테이크 150000', errors);
  assert.match(errors.join(' '), /0~100000/);
});

// ---------------------------------------------------------------------------
// Dining rows → groups/sections
// ---------------------------------------------------------------------------

test('set and thousandWon need the price column and forbid item prices', () => {
  const ctx = loadScripts();
  const index = cafeteriaIndex(ctx);
  const parsed = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '교수회관 식당', '점심', '정식', '제육볶음\n미역국', '', '', '게시'),
    row(D(2026, 10, 14), '학생회관 식당', '아침', '천원의아침밥', '훈제오리솥밥 1000', 1000, '', '게시'),
  ], index);
  assert.equal(parsed.orphanErrors.length, 0);
  const messages = parsed.groups.flatMap(g => g.errors.map(e => `${e.rowNumber}:${e.message}`));
  assert.ok(messages.some(m => m.startsWith('2:') && /가격 열이 필수/.test(m)), messages.join('\n'));
  assert.ok(messages.some(m => m.startsWith('3:') && /항목 끝에는 가격을 붙이지 마세요/.test(m)), messages.join('\n'));
});

test('alacarte and snack must leave the price column blank; item prices are optional', () => {
  const ctx = loadScripts();
  const index = cafeteriaIndex(ctx);
  const parsed = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '학생회관 식당', '종일', '일품', '국밥 6000\n돈까스 7,500원', 6000, '', '게시'),
    row(D(2026, 10, 13), '학생회관 식당', '종일', '양분식', '김밥\n핫도그 2500', '', '', '게시'),
  ], index);
  const [group] = parsed.groups;
  eq(group.errors.map(e => e.rowNumber), [2]);
  assert.match(group.errors[0].message, /가격 열을 비우고/);
  eq(group.rows[1].section, {
    slot: 'allDay', kind: 'snack', items: [{ name: '김밥' }, { name: '핫도그', price: 2500 }],
  });
});

test('same slot with set + alacarte is allowed, duplicate (slot, kind) is an error', () => {
  const ctx = loadScripts();
  const index = cafeteriaIndex(ctx);
  const ok = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '국제관 식당', '점심', '정식', '불고기\n된장국', 6500, '', '게시'),
    row(D(2026, 10, 13), '국제관 식당', '점심', '일품', '카레라이스 6000\n우동 5000', '', '', '게시'),
  ], index);
  assert.equal(ok.groups.length, 1);
  eq(ok.groups[0].errors, []);
  eq(ok.groups[0].sections.map(s => `${s.slot}/${s.kind}`), ['lunch/set', 'lunch/alacarte']);

  const dup = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '국제관 식당', '점심', '정식', '불고기', 6500, '', '게시'),
    row(D(2026, 10, 13), '국제관 식당', '점심', '정식', '닭갈비', 6500, '', '게시'),
  ], index);
  eq(dup.groups[0].errors.map(e => e.rowNumber), [3]);
  assert.match(dup.groups[0].errors[0].message, /점심 정식이 2행과 중복/);
});

test('closed/unpublished rows must be empty, single per group, and not mixed with open rows', () => {
  const ctx = loadScripts();
  const index = cafeteriaIndex(ctx);
  const parsed = ctx.parseDiningRows_([
    row(D(2026, 10, 14), '부민 교직원 식당', '', '', '', '', '', '휴무'),
    row(D(2026, 10, 15), '부민 교직원 식당', '점심', '', '', '', '', '휴무'),
    row(D(2026, 10, 16), '부민 교직원 식당', '', '', '', '', '', '게시취소'),
    row(D(2026, 10, 16), '부민 교직원 식당', '', '', '', '', '', '게시취소'),
    row(D(2026, 10, 17), '부민 교직원 식당', '', '', '', '', '', '휴무'),
    row(D(2026, 10, 17), '부민 교직원 식당', '점심', '정식', '갈치조림', 7000, '', '게시'),
  ], index);
  const byId = Object.fromEntries(parsed.groups.map(g => [g.id, g]));
  eq(byId['bumin-staff_2026-10-14'].errors, []);
  assert.equal(byId['bumin-staff_2026-10-14'].status, 'closed');
  assert.match(byId['bumin-staff_2026-10-15'].errors[0].message, /입력하지 마세요/);
  eq(byId['bumin-staff_2026-10-16'].errors.map(e => e.rowNumber), [5]);
  assert.match(byId['bumin-staff_2026-10-16'].errors[0].message, /한 행만/);
  assert.ok(byId['bumin-staff_2026-10-17'].errors.every(e => /상태는 모두 같아야/.test(e.message)));
});

test('unknown cafeteria names and names shared by two cafeteria rows become orphan errors', () => {
  const ctx = loadScripts();
  const rows = ctx.DEFAULT_CAFETERIAS.map(r => r.slice());
  rows.push(['bumin-staff-2', '부민 교직원 식당', 'Dup', '부민', '', '', '', '', 5]);
  const index = ctx.cafeteriaIndex_(ctx.parseCafeteriaRows_(rows));
  const parsed = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '없는 식당', '점심', '정식', '밥', 5000, '', '게시'),
    row(D(2026, 10, 13), '부민 교직원 식당', '점심', '정식', '밥', 5000, '', '게시'),
  ], index);
  assert.equal(parsed.groups.length, 0);
  eq(parsed.orphanErrors.map(e => e.rowNumber), [2, 3]);
  assert.match(parsed.orphanErrors[0].errors[0], /탭에 없거나/);
  // A name present on two cafeteria rows is ambiguous even though the second row is invalid.
  assert.match(parsed.orphanErrors[1].errors[0], /여러 번 있어/);
});

test('open group with no valid section is an error; dining document carries sections', () => {
  const ctx = loadScripts();
  const index = cafeteriaIndex(ctx);
  const bad = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '도서관 식당', '종일', '정식', '', 6000, '', '게시'),
  ], index);
  assert.ok(bad.groups[0].errors.some(e => /메뉴은\(는\) 필수/.test(e.message)));
  assert.ok(bad.groups[0].errors.some(e => /한 개 이상의 메뉴 섹션/.test(e.message)));

  const good = ctx.parseDiningRows_([
    row(D(2026, 10, 13), '학생회관 식당', '아침', '천원의아침밥', '훈제오리솥밥', '1,000원', '09:00부터 선착순', '게시'),
    row(D(2026, 10, 13), '학생회관 식당', '종일', '일품', '국밥 6000\n돈까스 7500', '', '', '게시'),
  ], index);
  eq(good.groups[0].errors, []);
  const doc = ctx.diningDocument_(good.groups[0]);
  assert.ok(doc.updatedAt instanceof Date);
  delete doc.updatedAt;
  eq(doc, {
    cafeteriaId: 'seunghak-student',
    date: '2026-10-13',
    status: 'open',
    sections: [
      { slot: 'breakfast', kind: 'thousandWon', items: [{ name: '훈제오리솥밥' }], price: 1000, note: '09:00부터 선착순' },
      { slot: 'allDay', kind: 'alacarte', items: [{ name: '국밥', price: 6000 }, { name: '돈까스', price: 7500 }] },
    ],
  });
  assert.ok(!('meals' in doc));
  const closed = ctx.parseDiningRows_([row(D(2026, 10, 14), '학생회관 식당', '', '', '', '', '', '휴무')], index);
  eq(ctx.diningDocument_(closed.groups[0]).sections, []);
});

// ---------------------------------------------------------------------------
// Cafeteria rows and hours
// ---------------------------------------------------------------------------

test('service hours parse into sorted windows; blank means none', () => {
  const ctx = loadScripts();
  const errors = [];
  eq(ctx.parseHours_('15:00-16:30, 09:00-09:30, 10:00~14:30', errors), [
    { open: '09:00', close: '09:30' }, { open: '10:00', close: '14:30' }, { open: '15:00', close: '16:30' },
  ]);
  eq(errors, []);
  eq(ctx.parseHours_('', errors), []);
  eq(ctx.parseHours_('9:00-10:00', errors), [{ open: '09:00', close: '10:00' }]);
  eq(errors, []);
});

test('service hours reject reversed, overlapping, malformed and out-of-range windows', () => {
  const ctx = loadScripts();
  let errors = [];
  ctx.parseHours_('10:00-09:00', errors);
  assert.match(errors.join(' '), /시작이 종료보다 빨라야/);
  errors = [];
  ctx.parseHours_('09:00-12:00, 11:00-13:00', errors);
  assert.match(errors.join(' '), /겹칩니다/);
  errors = [];
  ctx.parseHours_('09:00-12:00, 12:00-13:00', errors);
  eq(errors, [], 'touching windows do not overlap');
  errors = [];
  ctx.parseHours_('오전 9시', errors);
  assert.match(errors.join(' '), /HH:mm-HH:mm/);
  errors = [];
  ctx.parseHours_('25:00-26:00', errors);
  assert.match(errors.join(' '), /올바르지 않습니다/);
  errors = [];
  ctx.parseHours_('09:00-10:00,,11:00-12:00', errors);
  assert.match(errors.join(' '), /빈 구간/);
});

test('default cafeteria rows validate and map to the Firestore document shape', () => {
  const ctx = loadScripts();
  const parsed = ctx.parseCafeteriaRows_(ctx.DEFAULT_CAFETERIAS.map(r => r.slice()));
  eq(parsed.errors, []);
  assert.equal(parsed.rows.length, 8);
  const student = parsed.rows.find(r => r.id === 'seunghak-student').data;
  assert.ok(student.updatedAt instanceof Date);
  delete student.updatedAt;
  eq(student, {
    name_ko: '학생회관 식당',
    name_en: 'Student Union Cafeteria',
    campus: 'seunghak',
    hours: [{ open: '09:00', close: '09:30' }, { open: '10:00', close: '14:30' }, { open: '15:00', close: '16:30' }],
    hours_ko: '천원의아침밥 09:00부터 선착순',
    hours_en: '₩1,000 breakfast from 09:00, first come',
    facilityId: 's02',
    order: 2,
  });
  const engineering = parsed.rows.find(r => r.id === 'seunghak-engineering').data;
  eq(engineering.hours, []);
  assert.equal(engineering.facilityId, null);
});

test('cafeteria rows reject bad ids, duplicate ids/names, bad campus, bad order and bad facility id', () => {
  const ctx = loadScripts();
  const parsed = ctx.parseCafeteriaRows_([
    ['Seunghak_Student', '학생회관 식당', 'Student', '승학', '', '', '', '', 1],
    ['a-1', '같은 이름', 'A', '승학', '', '', '', '', 1],
    ['a-1', '같은 이름', 'B', '해운대', '', '', '', 'S08', 'x'],
  ]);
  const byRow = Object.fromEntries(parsed.errors.map(e => [e.rowNumber, e.errors.join(' | ')]));
  assert.match(byRow[2], /영문 소문자·숫자·하이픈/);
  assert.match(byRow[4], /식당ID가 3행과 중복/);
  assert.match(byRow[4], /이름\(국문\)이 3행과 중복/);
  assert.match(byRow[4], /캠퍼스 값이 허용 목록에 없습니다/);
  assert.match(byRow[4], /지도 건물ID/);
  assert.match(byRow[4], /표시 순서/);
  assert.equal(byRow[3], undefined);
});

// ---------------------------------------------------------------------------
// Full replace: stale document computation and the cafeteria sync path
// ---------------------------------------------------------------------------

test('full replace deletes server documents missing from the sheet', () => {
  const ctx = loadScripts();
  const stale = ctx.staleDocuments_(
    [{ id: 'seunghak-student' }, { id: 'bumin-student' }, { id: 'gudeok-student' }],
    ['seunghak-student', 'gudeok-student', 'bumin-staff'],
  );
  eq(stale.map(d => d.id), ['bumin-student']);
});

test('cafeteria sync shows stale names in the confirmation and commits updates + deletes with versions', () => {
  const state = { commits: [], confirmMessage: '', held: true };
  const lock = { releaseLock() { state.held = false; }, tryLock() { state.held = true; return true; } };
  const ui = {
    ButtonSet: { YES_NO: 'confirm', OK: 'ok' }, Button: { YES: 'yes' },
    alert(title, message, buttons) { if (buttons === 'confirm') state.confirmMessage = message; return 'yes'; },
  };
  const ctx = loadScripts({ SpreadsheetApp: { getUi: () => ui } });
  const sheetRows = [
    { id: 'seunghak-student', rowNumber: 2, data: { name_ko: '학생회관 식당', updatedAt: new Date() } },
    { id: 'bumin-staff', rowNumber: 3, data: { name_ko: '부민 교직원 식당', updatedAt: new Date() } },
  ];
  Object.assign(ctx, {
    readCafeteriaRows_: () => ({ sheet: {}, rows: structuredClone(sheetRows), errors: [] }),
    listDocumentSummaries_: () => [
      { id: 'seunghak-student', updateTime: 'v1', name_ko: '승학캠퍼스 학생식당' },
      { id: 'bumin-student', updateTime: 'v2', name_ko: '부민캠퍼스 학생식당' },
    ],
    clearResultColumn_: () => {}, setRowResult_: () => {}, finishRun_: () => {},
    updateWrite_: (collection, id, data) => ({ update: { collection, id, data } }),
    deleteWrite_: (collection, id) => ({ delete: { collection, id } }),
    commitWrites_: writes => { assert.equal(state.held, true); state.commits.push(writes); },
  });
  ctx.syncCafeteriasLocked_({}, lock);
  assert.match(state.confirmMessage, /부민캠퍼스 학생식당 \[bumin-student\]/);
  assert.match(state.confirmMessage, /식당ID를 바꾼 경우/);
  const [writes] = state.commits;
  eq(writes.map(w => [w.update ? 'update' : 'delete', (w.update || w.delete).id, w.currentDocument]), [
    ['update', 'seunghak-student', { updateTime: 'v1' }],
    ['update', 'bumin-staff', { exists: false }],
    ['delete', 'bumin-student', { updateTime: 'v2' }],
  ]);
  assert.ok(writes.every(w => (w.update || w.delete).collection === 'cafeterias'));
});

// ---------------------------------------------------------------------------
// Legacy layout migration
// ---------------------------------------------------------------------------

test('legacy dining header is detected and a new-layout sheet is left alone', () => {
  const ctx = loadScripts();
  assert.equal(ctx.isLegacyDiningHeader_(ctx.LEGACY_DINING_HEADERS.slice()), true);
  assert.equal(ctx.isLegacyDiningHeader_(ctx.DINING_HEADERS.slice()), false);
  const sheet = new FakeSheet([ctx.DINING_HEADERS.slice(), [D(2026, 10, 13), '학생회관 식당', '점심', '정식', '밥', 6000, '', '게시', '']]);
  assert.equal(ctx.migrateLegacyDiningSheet_(sheet), null);
  assert.equal(sheet.cells[1][2], '점심');
});

test('legacy rows migrate: 식사 → 시간대, 유형 = 정식, menu/price kept, results cleared', () => {
  const ctx = loadScripts();
  const sheet = new FakeSheet([
    ctx.LEGACY_DINING_HEADERS.slice(),
    [D(2026, 9, 1), '승학 학생식당', '조식', '제육볶음, 미역국', 5000, '게시', '✅ 동기화됨'],
    [D(2026, 9, 1), '구덕 학생식당', '중식', '비빔밥', '', '게시', '❌ 오류'],
    [D(2026, 9, 2), '부민 학생식당', '', '', '', '휴무', ''],
    ['', '', '', '', '', '', ''],
  ]);
  const result = ctx.migrateLegacyDiningSheet_(sheet);
  eq(result, { rows: 3, unmappedCafeterias: 1 });
  eq(sheet.cells[0], ctx.DINING_HEADERS.slice());
  eq(sheet.cells[1], [D(2026, 9, 1), '학생회관 식당', '아침', '정식', '제육볶음, 미역국', 5000, '', '게시', '']);
  eq(sheet.cells[2], [D(2026, 9, 1), '구덕 제2캠퍼스 학생회관', '점심', '정식', '비빔밥', '', '', '게시', '']);
  eq(sheet.cells[3], [D(2026, 9, 2), '부민 학생식당', '', '', '', '', '', '휴무', '']);
  // Migrated rows parse under the new rules: set needs a price (row 3) and the
  // unmapped cafeteria is reported (row 4); the first row is valid.
  const parsed = ctx.parseDiningRows_(sheet.cells.slice(1, 4), cafeteriaIndex(ctx));
  eq(parsed.orphanErrors.map(e => e.rowNumber), [4]);
  const byId = Object.fromEntries(parsed.groups.map(g => [g.id, g]));
  eq(byId['seunghak-student_2026-09-01'].errors, []);
  assert.match(byId['gudeok-student_2026-09-01'].errors[0].message, /가격 열이 필수/);
});

test('example rows parse cleanly against the default cafeterias and cover every cafeteria', () => {
  const ctx = loadScripts();
  const values = ctx.EXAMPLE_DINING_ROWS.map(r => {
    const [y, m, d] = r[0];
    return [D(y, m, d)].concat(r.slice(1), ['']);
  });
  const parsed = ctx.parseDiningRows_(values, cafeteriaIndex(ctx));
  eq(parsed.orphanErrors, []);
  eq(parsed.groups.flatMap(g => g.errors), []);
  const cafeterias = new Set(parsed.groups.map(g => g.cafeteriaId));
  assert.equal(cafeterias.size, ctx.DEFAULT_CAFETERIAS.length);
  assert.ok(parsed.groups.some(g => g.status === 'closed'));
  assert.ok(parsed.groups.some(g => g.sections.length >= 4));
});
