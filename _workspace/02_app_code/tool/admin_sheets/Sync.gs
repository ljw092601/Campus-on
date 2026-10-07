function syncAcademicEvents() {
  runWithLock_('academic_events', syncAcademicEventsLocked_);
}

function syncDiningMenus() {
  runWithLock_('dining_menus', syncDiningMenusLocked_);
}

function syncCafeterias() {
  runWithLock_('cafeterias', syncCafeteriasLocked_);
}

function runWithLock_(kind, operation) {
  const ui = SpreadsheetApp.getUi();
  // Dates are grouped/formatted in CONFIG.timeZone; a mismatched spreadsheet
  // time zone would shift every date, so publishing is blocked until it is fixed.
  const spreadsheetTimeZone = SpreadsheetApp.getActive().getSpreadsheetTimeZone();
  if (spreadsheetTimeZone !== CONFIG.timeZone) {
    ui.alert(
      '타임존 불일치',
      `스프레드시트 타임존(${spreadsheetTimeZone})이 '${CONFIG.timeZone}'과 다릅니다.\n` +
      '날짜가 밀려 저장될 수 있어 게시를 중단합니다.\n' +
      "'동아메이트 > 시트 초기화'를 실행해 타임존을 맞춘 뒤 다시 시도하세요.",
      ui.ButtonSet.OK,
    );
    return;
  }
  const lock = LockService.getDocumentLock();
  if (!lock.tryLock(1000)) {
    ui.alert('동기화 중', '다른 관리자가 이미 동기화하고 있습니다. 잠시 후 다시 시도하세요.', ui.ButtonSet.OK);
    return;
  }
  const run = newRun_(kind);
  try {
    operation(run, lock);
  } catch (error) {
    finishRun_(run, 'failed', { failure: 1 }, [String(error.message || error)]);
    ui.alert('동기화 실패', String(error.message || error), ui.ButtonSet.OK);
    throw error;
  } finally {
    if (lock.hasLock()) lock.releaseLock();
  }
}

// ---------------------------------------------------------------------------
// Full replace (학사일정, 식당): the sheet is the single source of truth. All
// rows must be valid; new/updated documents and deletes of documents missing
// from the sheet go out in one atomic commit guarded by document versions.
// ---------------------------------------------------------------------------

function syncAcademicEventsLocked_(run, lock) {
  fullReplaceSync_(run, lock, {
    label: '학사일정',
    collection: CONFIG.collections.academicEvents,
    resultColumn: ACADEMIC_RESULT_COLUMN,
    read: () => readAcademicRows_(),
    describe: doc => `• ${doc.title_ko || '(제목 없음)'} (${doc.start || '날짜 없음'}) [${doc.id.substring(0, 8)}]`,
    deleteNotice: '시트에 없는 기존 학사일정',
  });
}

function syncCafeteriasLocked_(run, lock) {
  fullReplaceSync_(run, lock, {
    label: '식당',
    collection: CONFIG.collections.cafeterias,
    resultColumn: CAFETERIA_RESULT_COLUMN,
    read: () => readCafeteriaRows_(),
    describe: doc => `• ${doc.name_ko || '(이름 없음)'} [${doc.id}]`,
    deleteNotice: "'식당' 탭에 없는 기존 식당 문서. 식당ID를 바꾼 경우 옛 ID 문서는 삭제되고 새 ID 문서가 생깁니다. 삭제되는 식당의 학식 문서(dining_menus)는 남지만 앱에는 보이지 않습니다.\n삭제 예정",
  });
}

function fullReplaceSync_(run, lock, spec) {
  const ui = SpreadsheetApp.getUi();
  const parsed = spec.read();
  clearResultColumn_(parsed.sheet, spec.resultColumn);

  if (parsed.errors.length) {
    const invalidRows = new Set(parsed.errors.map(error => error.rowNumber));
    parsed.errors.forEach(error => setRowResult_(parsed.sheet, error.rowNumber, spec.resultColumn, `❌ ${error.errors.join(' / ')}`, true));
    parsed.rows.filter(row => !invalidRows.has(row.rowNumber)).forEach(row =>
      setRowResult_(parsed.sheet, row.rowNumber, spec.resultColumn, '⏸ 다른 행 오류로 전체 게시 중단', true));
    const summaries = summarizeErrors_(parsed.errors);
    finishRun_(run, 'validation_failed', { input: parsed.rows.length, failure: parsed.errors.length }, summaries);
    ui.alert('게시 중단', `오류 ${parsed.errors.length}행이 있습니다. ${spec.label}은 한 행이라도 오류면 전체 게시하지 않습니다.`, ui.ButtonSet.OK);
    return;
  }

  const existingDocs = listDocumentSummaries_(spec.collection);
  const staleDocs = staleDocuments_(existingDocs, parsed.rows.map(row => row.id));
  let confirmed = true;
  if (staleDocs.length) {
    const sheetRevision = sheetRevision_(parsed);
    const serverRevision = serverRevision_(existingDocs);
    // Apps Script dialogs suspend execution and discard held locks.
    lock.releaseLock();
    confirmed = confirmDeletes_(ui, staleDocs, spec);
    if (!lock.tryLock(1000)) {
      throw new Error('확인 중 다른 동기화가 시작되었습니다. 다시 실행해 주세요.');
    }
    if (confirmed && (
      sheetRevision !== sheetRevision_(spec.read()) ||
      serverRevision !== serverRevision_(listDocumentSummaries_(spec.collection))
    )) {
      throw new Error('확인 중 시트 또는 서버 데이터가 변경되었습니다. 삭제 대상을 다시 확인해 주세요.');
    }
  }
  if (!confirmed) {
    parsed.rows.forEach(row => setRowResult_(parsed.sheet, row.rowNumber, spec.resultColumn, '⏸ 삭제 확인에서 취소됨', false));
    finishRun_(run, 'cancelled', { input: parsed.rows.length, deleted: 0 }, [`삭제 예정 ${staleDocs.length}건을 사용자가 취소함`]);
    return;
  }

  const versions = new Map(existingDocs.map(doc => [doc.id, documentPrecondition_(doc)]));
  const writes = parsed.rows.map(row => ({
    ...updateWrite_(spec.collection, row.id, row.data),
    currentDocument: versions.get(row.id) || { exists: false },
  }));
  staleDocs.forEach(doc => writes.push({
    ...deleteWrite_(spec.collection, doc.id),
    currentDocument: versions.get(doc.id),
  }));
  if (writes.length > CONFIG.maxCommitWrites) {
    throw new Error(`게시 ${parsed.rows.length}건 + 삭제 ${staleDocs.length}건이 atomic commit 한도 ${CONFIG.maxCommitWrites}건을 넘습니다.`);
  }
  commitWrites_(writes);
  parsed.rows.forEach(row => setRowResult_(parsed.sheet, row.rowNumber, spec.resultColumn, '✅ 동기화됨', false));
  finishRun_(run, 'succeeded', {
    input: parsed.rows.length,
    success: parsed.rows.length,
    deleted: staleDocs.length,
  }, []);
  ui.alert(`${spec.label} 동기화 완료`, `게시 ${parsed.rows.length}건, 삭제 ${staleDocs.length}건을 하나의 atomic commit으로 반영했습니다.`, ui.ButtonSet.OK);
}

// Pure: documents on the server whose id is not in the sheet.
function staleDocuments_(existingDocs, desiredIdList) {
  const desiredIds = new Set(desiredIdList);
  return existingDocs.filter(doc => !desiredIds.has(doc.id));
}

function sheetRevision_(parsed) {
  return JSON.stringify({
    errors: parsed.errors,
    rows: parsed.rows.map(row => {
      const data = { ...row.data };
      delete data.updatedAt;
      return { id: row.id, rowNumber: row.rowNumber, data };
    }),
  });
}

function serverRevision_(docs) {
  return JSON.stringify(docs.map(doc => [doc.id, doc.updateTime]).sort());
}

function documentPrecondition_(doc) {
  if (!doc.updateTime) throw new Error('서버 문서 버전을 확인할 수 없습니다. 다시 실행해 주세요.');
  return { updateTime: doc.updateTime };
}

function confirmDeletes_(ui, staleDocs, spec) {
  const preview = staleDocs.slice(0, 20).map(spec.describe).join('\n');
  const omitted = staleDocs.length > 20 ? `\n… 외 ${staleDocs.length - 20}건` : '';
  const response = ui.alert(
    '삭제 예정 문서 확인',
    `${spec.deleteNotice} ${staleDocs.length}건을 삭제합니다.\n\n${preview}${omitted}\n\n계속하시겠습니까?`,
    ui.ButtonSet.YES_NO,
  );
  return response === ui.Button.YES;
}

// Backwards-compatible aliases (older tests/scripts referenced these names).
function academicSheetRevision_(parsed) { return sheetRevision_(parsed); }
function academicServerRevision_(docs) { return serverRevision_(docs); }
function academicPrecondition_(doc) { return documentPrecondition_(doc); }

// ---------------------------------------------------------------------------
// 학식: upsert only. Each (cafeteria, date) group becomes one document that is
// overwritten atomically with its `sections`; groups with errors are skipped.
// Documents are never deleted — "게시취소" writes a `status: unpublished` tombstone.
// ---------------------------------------------------------------------------

function syncDiningMenusLocked_(run) {
  const ui = SpreadsheetApp.getUi();
  const column = DINING_RESULT_COLUMN;
  const parsed = readDiningGroups_();
  clearResultColumn_(parsed.sheet, column);
  const errorSummaries = [];

  parsed.orphanErrors.forEach(error => {
    setRowResult_(parsed.sheet, error.rowNumber, column, `❌ ${error.errors.join(' / ')}`, true);
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
        setRowResult_(parsed.sheet, row.rowNumber, column, `❌ ${messages.join(' / ')}`, true);
      });
      return;
    }
    validGroups.push(group);
  });

  // One document per group; a commit holds at most maxCommitWrites documents, so
  // larger syncs go out in chunks. Each group is still written atomically.
  const chunks = chunk_(validGroups, CONFIG.maxCommitWrites);
  let committedGroups = 0;
  try {
    chunks.forEach(groupsInChunk => {
      commitWrites_(groupsInChunk.map(group => updateWrite_(CONFIG.collections.diningMenus, group.id, diningDocument_(group))));
      groupsInChunk.forEach(group => group.rows.forEach(row =>
        setRowResult_(parsed.sheet, row.rowNumber, column, '✅ 동기화됨', false)));
      committedGroups += groupsInChunk.length;
    });
  } catch (error) {
    validGroups.slice(committedGroups).forEach(group => group.rows.forEach(row =>
      setRowResult_(parsed.sheet, row.rowNumber, column, `❌ Firestore 반영 실패: ${error.message}`, true)));
    finishRun_(run, 'failed', {
      input: parsed.groups.reduce((sum, group) => sum + group.rows.length, 0) + parsed.orphanErrors.length,
      success: committedGroups,
      failure: validGroups.length - committedGroups,
    }, errorSummaries.concat([`Firestore 반영 실패: ${error.message}`]));
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

// Pure: Firestore document body for one (cafeteria, date) group.
function diningDocument_(group) {
  return {
    cafeteriaId: group.cafeteriaId,
    date: group.date,
    status: group.status,
    sections: group.status === 'open' ? group.sections : [],
    updatedAt: new Date(),
  };
}

function chunk_(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) chunks.push(items.slice(i, i + size));
  return chunks;
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
