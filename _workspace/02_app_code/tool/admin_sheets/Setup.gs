function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('동아메이트')
    .addItem('시트 초기화', 'setupAdminSheets')
    .addSeparator()
    .addItem('학사일정 동기화', 'syncAcademicEvents')
    .addItem('학식 동기화', 'syncDiningMenus')
    .addItem('식당 동기화', 'syncCafeterias')
    .addToUi();
}

// Idempotent: creates missing tabs, (re)applies headers, protections, dropdowns,
// widths and wrapping. An existing "학식" tab in the pre-redesign 6+1 column
// layout is migrated in place before the new header is applied.
function setupAdminSheets() {
  const ss = SpreadsheetApp.getActive();
  ss.setSpreadsheetTimeZone(CONFIG.timeZone);

  setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
  configureAcademicSheet_(ss.getSheetByName(CONFIG.sheets.academic));

  const cafeteriaSheet = setupDataSheet_(ss, CONFIG.sheets.cafeterias, CAFETERIA_HEADERS);
  const seededCafeterias = seedDefaultCafeterias_(cafeteriaSheet);
  configureCafeteriaSheet_(cafeteriaSheet);

  const existingDining = ss.getSheetByName(CONFIG.sheets.dining);
  const migration = existingDining ? migrateLegacyDiningSheet_(existingDining) : null;
  const diningSheet = setupDataSheet_(ss, CONFIG.sheets.dining, DINING_HEADERS);
  configureDiningSheet_(diningSheet, cafeteriaSheet);

  setupExampleSheet_(ss);
  setupGuideSheet_(ss);

  const lines = ['학사일정·식당·학식·예시·안내 시트를 준비했습니다.'];
  if (seededCafeterias) lines.push(`'${CONFIG.sheets.cafeterias}' 탭에 기본 식당 ${DEFAULT_CAFETERIAS.length}곳을 채웠습니다. 확인 후 '식당 동기화'를 실행하세요.`);
  if (migration) {
    lines.push(
      `'${CONFIG.sheets.dining}' 탭을 옛 양식에서 새 양식으로 옮겼습니다 (${migration.rows}행).`,
      '- 식사 → 시간대 (조식/중식/석식 → 아침/점심/저녁), 유형은 모두 "정식"으로 채웠습니다.',
      '- 메뉴·가격은 그대로 두었습니다. 정식은 가격 열이 필수이므로 가격이 비어 있던 행은 동기화 전에 채우세요.',
    );
    if (migration.unmappedCafeterias) {
      lines.push(`- 식당 이름을 자동으로 바꾸지 못한 행이 ${migration.unmappedCafeterias}행 있습니다 (예: 부민 학생식당). '${CONFIG.sheets.cafeterias}' 탭의 이름으로 다시 고르세요.`);
    }
    lines.push('- 옛 동기화 결과는 지웠습니다. 내용을 확인한 뒤 "학식 동기화"를 다시 실행하세요.');
  }
  SpreadsheetApp.getUi().alert('시트 초기화 완료', lines.join('\n'), SpreadsheetApp.getUi().ButtonSet.OK);
}

function setupDataSheet_(ss, name, headers) {
  let sheet = ss.getSheetByName(name);
  if (!sheet) sheet = ss.insertSheet(name);
  if (sheet.getMaxColumns() < headers.length) sheet.insertColumnsAfter(sheet.getMaxColumns(), headers.length - sheet.getMaxColumns());
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  sheet.setFrozenRows(1);
  sheet.getRange(1, 1, 1, headers.length)
    .setFontWeight('bold')
    .setBackground('#D9EAF7');
  protectHeader_(sheet, headers.length);
  return sheet;
}

function protectHeader_(sheet, columnCount) {
  const description = '관리자 입력 도구 헤더';
  sheet.getProtections(SpreadsheetApp.ProtectionType.RANGE)
    .filter(p => p.getDescription() === description)
    .forEach(p => p.remove());
  const protection = sheet.getRange(1, 1, 1, columnCount).protect().setDescription(description);
  protection.setWarningOnly(false);
  const me = Session.getEffectiveUser();
  protection.addEditor(me);
  protection.getEditors().forEach(editor => {
    if (editor.getEmail() !== me.getEmail()) protection.removeEditor(editor);
  });
  if (protection.canDomainEdit()) protection.setDomainEdit(false);
}

// ---------------------------------------------------------------------------
// 학사일정
// ---------------------------------------------------------------------------

function configureAcademicSheet_(sheet) {
  ensureRows_(sheet, 1000);
  const rows = sheet.getMaxRows() - 1;
  const dateRule = SpreadsheetApp.newDataValidation().requireDate().setAllowInvalid(false).build();
  sheet.getRange(2, 1, rows, 2).setDataValidation(dateRule).setNumberFormat('yyyy-mm-dd');
  setListValidation_(sheet.getRange(2, 5, rows, 1), Object.keys(ACADEMIC_CATEGORIES));
  sheet.hideColumns(7);
  sheet.setColumnWidth(3, 220);
  sheet.setColumnWidth(4, 240);
  sheet.setColumnWidth(6, 260);
}

// ---------------------------------------------------------------------------
// 식당
// ---------------------------------------------------------------------------

// Fills the canonical cafeteria rows when the tab has no data rows yet.
// Returns true when rows were written.
function seedDefaultCafeterias_(sheet) {
  if (sheet.getLastRow() >= 2) return false;
  const values = DEFAULT_CAFETERIAS.map(row => row.slice());
  sheet.getRange(2, 1, values.length, values[0].length).setValues(values);
  return true;
}

function configureCafeteriaSheet_(sheet) {
  ensureRows_(sheet, 200);
  const rows = sheet.getMaxRows() - 1;
  const C = CAFETERIA_COL;
  sheet.getRange(2, 1, rows, CAFETERIA_HEADERS.length).clearDataValidations();
  // Plain-text format keeps ids, times and building ids from being coerced
  // ("09:00-09:30" must stay a string, "01" must not become 1).
  sheet.getRange(2, C.id + 1, rows, 1).setNumberFormat('@');
  sheet.getRange(2, C.hours + 1, rows, 1).setNumberFormat('@');
  sheet.getRange(2, C.facilityId + 1, rows, 1).setNumberFormat('@');
  setListValidation_(sheet.getRange(2, C.campus + 1, rows, 1), Object.keys(CAMPUSES));
  sheet.getRange(2, C.order + 1, rows, 1).setDataValidation(
    SpreadsheetApp.newDataValidation()
      .requireNumberBetween(CONFIG.orderMin, CONFIG.orderMax)
      .setAllowInvalid(false)
      .setHelpText(`${CONFIG.orderMin}~${CONFIG.orderMax} 사이의 정수`)
      .build(),
  );
  sheet.setColumnWidth(C.id + 1, 170);
  sheet.setColumnWidth(C.nameKo + 1, 190);
  sheet.setColumnWidth(C.nameEn + 1, 260);
  sheet.setColumnWidth(C.campus + 1, 70);
  sheet.setColumnWidth(C.hours + 1, 260);
  sheet.setColumnWidth(C.hoursKo + 1, 220);
  sheet.setColumnWidth(C.hoursEn + 1, 240);
  sheet.setColumnWidth(C.facilityId + 1, 100);
  sheet.setColumnWidth(C.order + 1, 80);
  sheet.setColumnWidth(C.result + 1, 260);
}

// ---------------------------------------------------------------------------
// 학식
// ---------------------------------------------------------------------------

function configureDiningSheet_(sheet, cafeteriaSheet) {
  ensureRows_(sheet, 1000);
  const rows = sheet.getMaxRows() - 1;
  const C = DINING_COL;
  sheet.getRange(2, 1, rows, DINING_HEADERS.length).clearDataValidations();
  const dateRule = SpreadsheetApp.newDataValidation().requireDate().setAllowInvalid(false).build();
  sheet.getRange(2, C.date + 1, rows, 1).setDataValidation(dateRule).setNumberFormat('yyyy-mm-dd');
  // Cafeteria names come from the "식당" tab so adding a cafeteria there is enough.
  const nameRange = cafeteriaSheet.getRange(2, CAFETERIA_COL.nameKo + 1, cafeteriaSheet.getMaxRows() - 1, 1);
  sheet.getRange(2, C.cafeteria + 1, rows, 1).setDataValidation(
    SpreadsheetApp.newDataValidation()
      .requireValueInRange(nameRange, true)
      .setAllowInvalid(false)
      .setHelpText(`'${CONFIG.sheets.cafeterias}' 탭의 이름(국문) 중 하나`)
      .build(),
  );
  setListValidation_(sheet.getRange(2, C.slot + 1, rows, 1), Object.keys(MEAL_SLOTS));
  setListValidation_(sheet.getRange(2, C.kind + 1, rows, 1), Object.keys(MENU_KINDS));
  setListValidation_(sheet.getRange(2, C.status + 1, rows, 1), Object.keys(DINING_STATUSES));
  // Menu items are one per line (Alt+Enter) or comma separated; wrap so multi-line
  // cells stay readable.
  sheet.getRange(2, C.menu + 1, rows, 1).setWrap(true).setNumberFormat('@');
  sheet.getRange(2, C.note + 1, rows, 1).setWrap(true);
  sheet.setColumnWidth(C.date + 1, 100);
  sheet.setColumnWidth(C.cafeteria + 1, 190);
  sheet.setColumnWidth(C.slot + 1, 70);
  sheet.setColumnWidth(C.kind + 1, 110);
  sheet.setColumnWidth(C.menu + 1, 320);
  sheet.setColumnWidth(C.price + 1, 80);
  sheet.setColumnWidth(C.note + 1, 180);
  sheet.setColumnWidth(C.status + 1, 90);
  sheet.setColumnWidth(C.result + 1, 300);
}

// Pure: true when the header row is the pre-redesign dining layout.
function isLegacyDiningHeader_(headerValues) {
  const header = (headerValues || []).slice(0, LEGACY_DINING_HEADERS.length).map(v => String(v || '').trim());
  return LEGACY_DINING_HEADERS.every((label, i) => header[i] === label);
}

// Migrates an old-layout "학식" sheet in place. Old: 날짜 | 식당 | 식사 | 메뉴 | 가격 |
// 상태 | 결과. New: 날짜 | 식당 | 시간대 | 유형 | 메뉴 | 가격 | 비고 | 상태 | 결과.
// Returns null when no migration was needed, otherwise counts for the alert.
function migrateLegacyDiningSheet_(sheet) {
  const header = sheet.getRange(1, 1, 1, LEGACY_DINING_HEADERS.length).getValues()[0];
  if (!isLegacyDiningHeader_(header)) return null;

  // 1) 유형 after 식사 (old col 3) → becomes col 4.
  sheet.insertColumnsAfter(3, 1);
  // 2) 비고 after 가격 (now col 6) → becomes col 7; 상태 → 8, 결과 → 9.
  sheet.insertColumnsAfter(6, 1);
  sheet.getRange(1, 1, 1, DINING_HEADERS.length).setValues([DINING_HEADERS.slice()]);

  const lastRow = sheet.getLastRow();
  let rows = 0;
  let unmappedCafeterias = 0;
  if (lastRow >= 2) {
    const values = sheet.getRange(2, 2, lastRow - 1, 3).getValues(); // 식당 | 시간대(옛 식사) | 유형(빈칸)
    const migrated = values.map(([cafeteria, meal]) => migrateLegacyDiningRow_(cafeteria, meal));
    migrated.forEach(row => {
      if (row.touched) rows += 1;
      if (row.unmappedCafeteria) unmappedCafeterias += 1;
    });
    sheet.getRange(2, 2, lastRow - 1, 3).setValues(migrated.map(row => row.values));
    sheet.getRange(2, DINING_RESULT_COLUMN, lastRow - 1, 1).clearContent().setBackground(null);
  }
  return { rows, unmappedCafeterias };
}

// Pure: one legacy row's (식당, 식사) → new (식당, 시간대, 유형).
function migrateLegacyDiningRow_(cafeteria, meal) {
  const cafeteriaLabel = String(cafeteria || '').trim();
  const mealLabel = String(meal || '').trim();
  const mappedCafeteria = Object.prototype.hasOwnProperty.call(LEGACY_CAFETERIA_LABELS, cafeteriaLabel)
    ? LEGACY_CAFETERIA_LABELS[cafeteriaLabel] : cafeteriaLabel;
  const mappedMeal = Object.prototype.hasOwnProperty.call(LEGACY_MEAL_LABELS, mealLabel)
    ? LEGACY_MEAL_LABELS[mealLabel] : mealLabel;
  const kind = mealLabel ? '정식' : '';
  return {
    values: [mappedCafeteria, mappedMeal, kind],
    touched: Boolean(cafeteriaLabel || mealLabel),
    unmappedCafeteria: Boolean(cafeteriaLabel) && mappedCafeteria === cafeteriaLabel &&
      !Object.values(LEGACY_CAFETERIA_LABELS).includes(cafeteriaLabel),
  };
}

// ---------------------------------------------------------------------------
// 예시 (never synced)
// ---------------------------------------------------------------------------

function setupExampleSheet_(ss) {
  let sheet = ss.getSheetByName(CONFIG.sheets.example);
  if (!sheet) sheet = ss.insertSheet(CONFIG.sheets.example);
  sheet.clear();
  sheet.clearConditionalFormatRules();
  const width = DINING_HEADERS.length - 1; // no result column in the example
  sheet.getRange(1, 1).setValue(EXAMPLE_NOTICE).setFontWeight('bold').setBackground('#FFF2CC');
  sheet.getRange(1, 1, 1, width).mergeAcross();
  sheet.getRange(2, 1, 1, width).setValues([DINING_HEADERS.slice(0, width)])
    .setFontWeight('bold').setBackground('#D9EAF7');
  const values = EXAMPLE_DINING_ROWS.map(row => {
    const [y, m, d] = row[0];
    return [new Date(y, m - 1, d)].concat(row.slice(1));
  });
  sheet.getRange(3, 1, values.length, width).setValues(values);
  sheet.getRange(3, 1, values.length, 1).setNumberFormat('yyyy-mm-dd');
  sheet.getRange(3, DINING_COL.menu + 1, values.length, 1).setWrap(true);
  sheet.setFrozenRows(2);
  sheet.setColumnWidth(DINING_COL.date + 1, 100);
  sheet.setColumnWidth(DINING_COL.cafeteria + 1, 190);
  sheet.setColumnWidth(DINING_COL.kind + 1, 110);
  sheet.setColumnWidth(DINING_COL.menu + 1, 320);
  sheet.setColumnWidth(DINING_COL.note + 1, 180);
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

function setListValidation_(range, values) {
  range.setDataValidation(
    SpreadsheetApp.newDataValidation()
      .requireValueInList(values, true)
      .setAllowInvalid(false)
      .build(),
  );
}

function ensureRows_(sheet, minimum) {
  if (sheet.getMaxRows() < minimum) sheet.insertRowsAfter(sheet.getMaxRows(), minimum - sheet.getMaxRows());
}

function setupGuideSheet_(ss) {
  let sheet = ss.getSheetByName(CONFIG.sheets.guide);
  if (!sheet) sheet = ss.insertSheet(CONFIG.sheets.guide);
  sheet.clear();
  const lines = [
    ['동아메이트 관리자 입력 안내'],
    ['1. 식당 탭: 식당 목록(이름·캠퍼스·운영시간)을 관리합니다. 학식 탭의 식당 드롭다운은 이 탭의 이름(국문)을 참조합니다.'],
    ['2. 학식 탭: 한 행 = 한 식당·한 날짜의 한 섹션(시간대 × 유형). 메뉴는 줄바꿈(Alt+Enter) 또는 쉼표로 항목을 구분합니다.'],
    ['3. 정식·천원의아침밥은 가격 열에 한 가격을 적고, 일품·양분식은 가격 열을 비우고 항목 끝에 가격을 적습니다 (예: 국밥 6000).'],
    ['4. 휴무/게시취소는 날짜·식당·상태만 입력하고 나머지는 비웁니다. 식당·날짜당 한 행입니다.'],
    ['5. 동아메이트 메뉴에서 해당 동기화를 실행합니다. 식당을 추가·수정했다면 "식당 동기화"를 먼저 실행하세요.'],
    ['6. 학사일정·식당은 한 행이라도 오류면 전체 게시가 중단되고, 시트에 없는 문서는 삭제됩니다(확인창).'],
    ['7. 학식은 식당×날짜 그룹 안의 한 행이라도 오류면 그 그룹만 게시되지 않습니다. 게시취소는 문서를 지우지 않고 미게시 상태로 바꿉니다.'],
    ['8. 예시 탭은 입력 참고용이며 동기화되지 않습니다. 동기화 결과 열에서 성공/오류를 확인합니다.'],
    ['자세한 설명은 ADMIN_GUIDE.md를 참고하세요.'],
  ];
  sheet.getRange(1, 1, lines.length, 1).setValues(lines);
  sheet.getRange('A1').setFontWeight('bold').setFontSize(14);
  sheet.setColumnWidth(1, 900);
}
