function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('동아메이트')
    .addItem('시트 템플릿 만들기/정비', 'setupAdminSheets')
    .addSeparator()
    .addItem('학사일정 동기화', 'syncAcademicEvents')
    .addItem('학식 동기화', 'syncDiningMenus')
    .addToUi();
}

function setupAdminSheets() {
  const ss = SpreadsheetApp.getActive();
  ss.setSpreadsheetTimeZone(CONFIG.timeZone);
  migrateAcademicHeaders_(ss);
  setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
  setupDataSheet_(ss, CONFIG.sheets.dining, DINING_HEADERS);
  setupGuideSheet_(ss);
  configureAcademicSheet_(ss.getSheetByName(CONFIG.sheets.academic));
  configureDiningSheet_(ss.getSheetByName(CONFIG.sheets.dining));
  SpreadsheetApp.getUi().alert('템플릿 준비 완료', '학사일정·학식·안내 시트를 준비했습니다.', SpreadsheetApp.getUi().ButtonSet.OK);
}

// 기존 7열 학사일정 시트를 9열로 올린다.
//
// 그냥 새 머리글을 덮어쓰면 E(분류)·F(동기화 결과)·G(event_id)가 제자리에 남아
// 모든 행이 한 칸씩 밀려 읽힌다 — 분류가 중문 제목이 되고 event_id가 분류가 된다
// (B 03/063 B-01). 그래서 **열을 실제로 삽입**해 기존 값을 오른쪽으로 옮긴다.
// 머리글이 예전 것도 새 것도 아니면 아무것도 건드리지 않고 중단한다.
function migrateAcademicHeaders_(ss) {
  const sheet = ss.getSheetByName(CONFIG.sheets.academic);
  if (!sheet) return;                       // 새로 만들 시트는 바로 9열로 생긴다
  const width = Math.max(sheet.getLastColumn(), ACADEMIC_HEADERS.length);
  const header = sheet.getRange(1, 1, 1, width).getValues()[0]
    .map(h => String(h == null ? '' : h).trim());

  const already = ACADEMIC_HEADERS.every((name, i) => header[i] === name);
  if (already) return;

  const isLegacy = ACADEMIC_HEADERS_LEGACY.every((name, i) => header[i] === name);
  if (isLegacy) {
    // 일정명(영문) 다음(5번째)에 두 열을 넣으면 기존 E:G가 G:I로 이동한다.
    sheet.insertColumnsAfter(4, 2);
    return;
  }

  const blank = header.every(h => h === '');
  if (blank && sheet.getLastRow() <= 1) return;   // 빈 시트: 그대로 머리글을 쓴다

  throw new Error(
    '학사일정 시트의 머리글이 예상과 다릅니다. 기존 데이터를 덮어쓸 수 있어 중단했습니다. ' +
    `현재 1행: ${header.slice(0, 9).join(' | ')} — ` +
    '머리글을 원래대로 되돌리거나, 일정명(영문) 오른쪽에 「일정명(중문)」·「일정명(베트남어)」 ' +
    '두 열을 직접 추가한 뒤 다시 실행해 주세요.');
}

function setupDataSheet_(ss, name, headers) {
  let sheet = ss.getSheetByName(name);
  if (!sheet) sheet = ss.insertSheet(name);
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

function configureAcademicSheet_(sheet) {
  ensureRows_(sheet, 1000);
  const rows = sheet.getMaxRows() - 1;
  const cols = academicColumns_(sheet);
  const dateRule = SpreadsheetApp.newDataValidation().requireDate().setAllowInvalid(false).build();
  sheet.getRange(2, cols.start + 1, rows, 2).setDataValidation(dateRule).setNumberFormat('yyyy-mm-dd');
  setListValidation_(sheet.getRange(2, cols.category + 1, rows, 1), Object.keys(ACADEMIC_CATEGORIES));
  sheet.hideColumns(cols.id + 1);
  sheet.setColumnWidth(cols.titleKo + 1, 220);
  sheet.setColumnWidth(cols.titleEn + 1, 240);
  if (cols.titleZh >= 0) sheet.setColumnWidth(cols.titleZh + 1, 200);
  if (cols.titleVi >= 0) sheet.setColumnWidth(cols.titleVi + 1, 240);
  sheet.setColumnWidth(cols.result + 1, 260);
}

function configureDiningSheet_(sheet) {
  ensureRows_(sheet, 1000);
  const rows = sheet.getMaxRows() - 1;
  const dateRule = SpreadsheetApp.newDataValidation().requireDate().setAllowInvalid(false).build();
  sheet.getRange(2, 1, rows, 1).setDataValidation(dateRule).setNumberFormat('yyyy-mm-dd');
  setListValidation_(sheet.getRange(2, 2, rows, 1), Object.keys(CAFETERIAS));
  setListValidation_(sheet.getRange(2, 3, rows, 1), Object.keys(MEAL_TYPES));
  setListValidation_(sheet.getRange(2, 6, rows, 1), Object.keys(DINING_STATUSES));
  sheet.setColumnWidth(4, 360);
  sheet.setColumnWidth(7, 260);
}

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
  sheet.getRange('A1:A9').setValues([
    ['동아메이트 관리자 입력 안내'],
    ['1. 학사일정 또는 학식 시트에 값을 입력합니다.'],
    ['2. 드롭다운 값과 날짜 형식을 그대로 사용합니다.'],
    ['3. 동아메이트 메뉴에서 해당 동기화를 실행합니다.'],
    ['4. 학사일정은 한 행이라도 오류면 전체 게시가 중단됩니다.'],
    ['5. 학식은 식당×날짜 그룹 안의 한 행이라도 오류면 그 그룹이 게시되지 않습니다.'],
    ['6. 게시취소는 Firestore 문서를 지우지 않고 미게시 상태로 바꿉니다.'],
    ['7. 동기화 결과 열에서 성공/오류를 확인합니다.'],
    ['자세한 설명은 ADMIN_GUIDE.md를 참고하세요.'],
  ]);
  sheet.getRange('A1').setFontWeight('bold').setFontSize(14);
  sheet.setColumnWidth(1, 720);
}
