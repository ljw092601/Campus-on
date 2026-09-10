function syncAcademicEvents() {
  runWithLock_('academic_events', syncAcademicEventsLocked_);
}

function syncDiningMenus() {
  runWithLock_('dining_menus', syncDiningMenusLocked_);
}

function runWithLock_(kind, operation) {
  const ui = SpreadsheetApp.getUi();
  const lock = LockService.getDocumentLock();
  if (!lock.tryLock(1000)) {
    ui.alert('동기화 중', '다른 관리자가 이미 동기화하고 있습니다. 잠시 후 다시 시도하세요.', ui.ButtonSet.OK);
    return;
  }
  const run = newRun_(kind);
  try {
    operation(run);
  } catch (error) {
    finishRun_(run, 'failed', { failure: 1 }, [String(error.message || error)]);
    ui.alert('동기화 실패', String(error.message || error), ui.ButtonSet.OK);
    throw error;
  } finally {
    lock.releaseLock();
  }
}

function syncAcademicEventsLocked_(run) {
  const ui = SpreadsheetApp.getUi();
  const parsed = readAcademicRows_();
  clearResultColumn_(parsed.sheet, 6);

  if (parsed.errors.length) {
    const invalidRows = new Set(parsed.errors.map(error => error.rowNumber));
    parsed.errors.forEach(error => setRowResult_(parsed.sheet, error.rowNumber, 6, `❌ ${error.errors.join(' / ')}`, true));
    parsed.rows.filter(row => !invalidRows.has(row.rowNumber)).forEach(row =>
      setRowResult_(parsed.sheet, row.rowNumber, 6, '⏸ 다른 행 오류로 전체 게시 중단', true));
    const summaries = summarizeErrors_(parsed.errors);
    finishRun_(run, 'validation_failed', { input: parsed.rows.length, failure: parsed.errors.length }, summaries);
    ui.alert('게시 중단', `오류 ${parsed.errors.length}행이 있습니다. 학사일정은 한 행이라도 오류면 전체 게시하지 않습니다.`, ui.ButtonSet.OK);
    return;
  }

  const existingIds = listDocumentIds_(CONFIG.collections.academicEvents);
  const desiredIds = new Set(parsed.rows.map(row => row.id));
  const staleIds = existingIds.filter(id => !desiredIds.has(id));
  if (staleIds.length && !confirmAcademicDeletes_(ui, staleIds)) {
    parsed.rows.forEach(row => setRowResult_(parsed.sheet, row.rowNumber, 6, '⏸ 삭제 확인에서 취소됨', false));
    finishRun_(run, 'cancelled', { input: parsed.rows.length, deleted: 0 }, [`삭제 예정 ${staleIds.length}건을 사용자가 취소함`]);
    return;
  }

  const writes = parsed.rows.map(row => updateWrite_(CONFIG.collections.academicEvents, row.id, row.data));
  staleIds.forEach(id => writes.push(deleteWrite_(CONFIG.collections.academicEvents, id)));
  if (writes.length > CONFIG.maxCommitWrites) {
    throw new Error(`게시 ${parsed.rows.length}건 + 삭제 ${staleIds.length}건이 atomic commit 한도 ${CONFIG.maxCommitWrites}건을 넘습니다.`);
  }
  commitWrites_(writes);
  parsed.rows.forEach(row => setRowResult_(parsed.sheet, row.rowNumber, 6, '✅ 동기화됨', false));
  finishRun_(run, 'succeeded', {
    input: parsed.rows.length,
    success: parsed.rows.length,
    deleted: staleIds.length,
  }, []);
  ui.alert('학사일정 동기화 완료', `게시 ${parsed.rows.length}건, 삭제 ${staleIds.length}건을 하나의 atomic commit으로 반영했습니다.`, ui.ButtonSet.OK);
}

function confirmAcademicDeletes_(ui, staleIds) {
  const preview = staleIds.slice(0, 20).map(id => `• ${id}`).join('\n');
  const omitted = staleIds.length > 20 ? `\n… 외 ${staleIds.length - 20}건` : '';
  const response = ui.alert(
    '삭제 예정 문서 확인',
    `시트에 없는 기존 학사일정 ${staleIds.length}건을 삭제합니다.\n\n${preview}${omitted}\n\n계속하시겠습니까?`,
    ui.ButtonSet.YES_NO,
  );
  return response === ui.Button.YES;
}

function syncDiningMenusLocked_(run) {
  const ui = SpreadsheetApp.getUi();
  const parsed = readDiningGroups_();
  clearResultColumn_(parsed.sheet, 7);
  const errorSummaries = [];

  parsed.orphanErrors.forEach(error => {
    setRowResult_(parsed.sheet, error.rowNumber, 7, `❌ ${error.errors.join(' / ')}`, true);
    errorSummaries.push(...summarizeErrors_([error]));
  });

  const validGroups = [];
  parsed.groups.forEach(group => {
    if (group.errors.length) {
      const perRow = new Map();
      group.errors.forEach(error => {
        if (!perRow.has(error.rowNumber)) perRow.set(error.rowNumber, []);
        perRow.get(error.rowNumber).push(error.message);
        errorSummaries.push(`${error.rowNumber}행: ${error.message}`);
      });
      group.rows.forEach(row => {
        const messages = perRow.get(row.rowNumber) || ['같은 식당·날짜 그룹의 다른 행에 오류가 있어 전체 그룹이 중단되었습니다.'];
        setRowResult_(parsed.sheet, row.rowNumber, 7, `❌ ${messages.join(' / ')}`, true);
      });
      return;
    }
    validGroups.push(group);
  });

  if (validGroups.length > CONFIG.maxCommitWrites) {
    throw new Error(`정상 식당×날짜 그룹 ${validGroups.length}건이 commit 한도 ${CONFIG.maxCommitWrites}건을 넘습니다.`);
  }
  const writes = validGroups.map(group => updateWrite_(CONFIG.collections.diningMenus, group.id, {
    cafeteriaId: group.cafeteriaId,
    date: group.date,
    status: group.status,
    meals: group.status === 'open' ? group.meals : [],
    updatedAt: new Date(),
  }));

  try {
    commitWrites_(writes);
    validGroups.forEach(group => group.rows.forEach(row =>
      setRowResult_(parsed.sheet, row.rowNumber, 7, '✅ 동기화됨', false)));
  } catch (error) {
    validGroups.forEach(group => group.rows.forEach(row =>
      setRowResult_(parsed.sheet, row.rowNumber, 7, `❌ Firestore 반영 실패: ${error.message}`, true)));
    throw error;
  }

  const failedGroups = parsed.groups.length - validGroups.length;
  const failedRows = parsed.orphanErrors.length + parsed.groups
    .filter(group => group.errors.length)
    .reduce((sum, group) => sum + group.rows.length, 0);
  finishRun_(run, failedRows ? 'partially_succeeded' : 'succeeded', {
    input: parsed.groups.reduce((sum, group) => sum + group.rows.length, 0) + parsed.orphanErrors.length,
    success: validGroups.length,
    failure: failedRows,
  }, errorSummaries);
  ui.alert(
    '학식 동기화 완료',
    `정상 그룹 ${validGroups.length}건 반영, 오류 그룹 ${failedGroups}건, 그룹을 만들 수 없는 오류 행 ${parsed.orphanErrors.length}건입니다.`,
    ui.ButtonSet.OK,
  );
}

function clearResultColumn_(sheet, column) {
  const lastRow = Math.max(sheet.getLastRow(), 2);
  sheet.getRange(2, column, lastRow - 1, 1).clearContent().setBackground(null);
}

function setRowResult_(sheet, row, column, message, isError) {
  sheet.getRange(row, column)
    .setValue(message)
    .setBackground(isError ? '#F4CCCC' : '#D9EAD3');
}
