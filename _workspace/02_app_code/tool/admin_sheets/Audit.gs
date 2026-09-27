function newRun_(kind) {
  return {
    id: Utilities.getUuid(),
    kind,
    actor: Session.getActiveUser().getEmail() || Session.getEffectiveUser().getEmail() || 'unknown',
    startedAt: new Date(),
  };
}

function finishRun_(run, outcome, counts, errors) {
  const record = {
    kind: run.kind,
    actor: run.actor,
    startedAt: run.startedAt,
    finishedAt: new Date(),
    outcome,
    inputCount: counts.input || 0,
    successCount: counts.success || 0,
    failureCount: counts.failure || 0,
    deleteCount: counts.deleted || 0,
    errors: (errors || []).slice(0, 100),
  };
  try {
    upsertDocument_(CONFIG.collections.syncRuns, run.id, record);
  } catch (auditError) {
    console.error(`감사로그 기록 실패: ${auditError.stack || auditError}`);
    SpreadsheetApp.getActive().toast('주의: 감사로그 기록에 실패했습니다. 개발자에게 알려주세요.', '감사로그 오류', 10);
  }
}

function summarizeErrors_(entries) {
  return entries.map(entry => {
    if (entry.rowNumber) {
      const messages = entry.errors || [entry.message];
      return `${entry.rowNumber}행: ${messages.filter(Boolean).join(' / ')}`;
    }
    return String(entry);
  });
}
