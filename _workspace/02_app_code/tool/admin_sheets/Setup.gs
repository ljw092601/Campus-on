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
  setupDataSheet_(ss, CONFIG.sheets.academic, ACADEMIC_HEADERS);
  setupDataSheet_(ss, CONFIG.sheets.dining, DINING_HEADERS);
  setupGuideSheet_(ss);
  configureAcademicSheet_(ss.getSheetByName(CONFIG.sheets.academic));
  configureDiningSheet_(ss.getSheetByName(CONFIG.sheets.dining));
  SpreadsheetApp.getUi().alert('템플릿 준비 완료', '학사일정·학식·안내 시트를 준비했습니다.', SpreadsheetApp.getUi().ButtonSet.OK);
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
  const dateRule = SpreadsheetApp.newDataValidation().requireDate().setAllowInvalid(false).build();
  sheet.getRange(2, 1, rows, 2).setDataValidation(dateRule).setNumberFormat('yyyy-mm-dd');
  setListValidation_(sheet.getRange(2, 5, rows, 1), Object.keys(ACADEMIC_CATEGORIES));
  sheet.hideColumns(7);
  sheet.setColumnWidth(3, 220);
  sheet.setColumnWidth(4, 240);
  sheet.setColumnWidth(6, 260);
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
