import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function fixture(change = () => {}, answer = 'yes', reacquire = true) {
  const state = {
    rows: [{ id: 'keep', rowNumber: 2, data: { title_ko: 'Event', updatedAt: 'first' } },
      { id: 'new', rowNumber: 3, data: { title_ko: 'New' } }],
    docs: [{ id: 'keep', updateTime: 'v1' }, { id: 'stale', updateTime: 'v2' }],
    commits: [], held: true, reacquired: false,
  };
  const lock = {
    releaseLock() { state.held = false; },
    tryLock() { state.reacquired = true; return state.held = reacquire; },
  };
  const ui = { ButtonSet: { YES_NO: 'confirm', OK: 'ok' }, Button: { YES: 'yes' },
    alert(title, message, buttons) {
      if (buttons === 'confirm') {
        assert.equal(state.held, false);
        change(state);
        return answer;
      }
    },
  };
  const context = vm.createContext({
    SpreadsheetApp: { getUi: () => ui },
  });
  for (const file of ['Config.gs', 'Sync.gs']) {
    vm.runInContext(readFileSync(new URL(file, import.meta.url), 'utf8'), context, { filename: file });
  }
  Object.assign(context, {
    readAcademicRows_: () => ({ sheet: {}, rows: structuredClone(state.rows), errors: [] }),
    listDocumentSummaries_: () => structuredClone(state.docs),
    clearResultColumn_: () => {}, setRowResult_: () => {}, finishRun_: () => {},
    updateWrite_: (collection, id, data) => ({ update: { id, data } }),
    deleteWrite_: (collection, id) => ({ delete: id }),
    commitWrites_: writes => { assert.equal(state.held, true); state.commits.push(writes); },
  });
  return { state, run: () => context.syncAcademicEventsLocked_({}, lock) };
}

test('confirmation reacquires lock and protects updates, creates and deletes with versions', () => {
  const f = fixture(s => { s.rows[0].data.updatedAt = 'generated again'; });
  f.run();
  assert.equal(f.state.reacquired, true);
  assert.deepEqual(JSON.parse(JSON.stringify(f.state.commits[0].map(w => w.currentDocument))),
    [{ updateTime: 'v1' }, { exists: false }, { updateTime: 'v2' }]);
});
for (const [name, change] of [
  ['sheet edit', s => { s.rows[0].data.title_ko = 'edited'; }],
  ['server edit', s => { s.docs[0].updateTime = 'v3'; }],
  ['server insertion', s => { s.docs.push({ id: 'other', updateTime: 'v4' }); }],
]) {
  test(`${name} during confirmation aborts without a commit`, () => {
    const f = fixture(change);
    assert.throws(f.run);
    assert.equal(f.state.commits.length, 0);
  });
}
test('busy lock after confirmation aborts without a commit', () => {
  const f = fixture(() => {}, 'yes', false);
  assert.throws(f.run);
  assert.equal(f.state.commits.length, 0);
});
test('cancel does not write to Firestore', () => {
  const f = fixture(() => {}, 'no');
  f.run();
  assert.equal(f.state.commits.length, 0);
});
test('missing document version fails closed', () => {
  const f = fixture();
  delete f.state.docs[0].updateTime;
  assert.throws(f.run);
  assert.equal(f.state.commits.length, 0);
});
