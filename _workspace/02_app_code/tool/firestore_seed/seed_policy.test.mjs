import test from 'node:test';
import assert from 'node:assert/strict';
import { createMissingAdminDocs } from './seed_policy.mjs';

test('admin seed only creates missing documents; existing fields remain intact', async () => {
  const docs = new Map([['existing', { name: 'admin edit' }]]);
  const db = { collection: () => ({ doc: id => ({ create: async data => {
    if (docs.has(id)) throw Object.assign(new Error('exists'), { code: 6 });
    docs.set(id, data);
  } }) }) };
  const entries = [['existing', { name: 'seed' }], ['new', { name: 'starter' }]];
  assert.equal(await createMissingAdminDocs(db, 'cafeterias', entries, () => 'now'), 1);
  assert.deepEqual(docs.get('existing'), { name: 'admin edit' });
  assert.equal(await createMissingAdminDocs(db, 'cafeterias', entries, () => 'later'), 0);
  assert.equal(docs.get('new').updatedAt, 'now');
});

test('permission and network errors are propagated, not treated as existing data', async () => {
  const error = Object.assign(new Error('denied'), { code: 7 });
  const db = { collection: () => ({ doc: () => ({ create: async () => { throw error; } }) }) };
  await assert.rejects(createMissingAdminDocs(db, 'cafeterias', [['a', {}]], () => 1), error);
});
