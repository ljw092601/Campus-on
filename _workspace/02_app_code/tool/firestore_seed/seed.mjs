// Firestore seeder — uploads facilities.seed.json + guide_items.seed.json.
//
// Uses the Firebase Admin SDK, which bypasses security rules (server-side),
// so `firestore.rules` can keep client writes fully blocked.
//
// Auth (keyless — design doc _workspace/06_admin_data_pipeline.md §7):
//   gcloud auth application-default login
//   # then, if the project isn't inferred automatically:
//   set GOOGLE_CLOUD_PROJECT=<firebase-project-id>
// A local serviceAccount.json is still honored as a fallback for old setups,
// but the agreed policy is to revoke such keys and use ADC.
//
// Run (from the project root):
//   node tool/firestore_seed/seed.mjs                  # upsert (merge)
//   node tool/firestore_seed/seed.mjs --overwrite      # replace each doc
//   node tool/firestore_seed/seed.mjs --overwrite --prune
//
// `--prune` only ever touches the dev-owned collections (facilities,
// guide_items, building_floors). The admin-entered collections
// (academic_events, cafeterias) get an initial seed here but are OWNED by the
// admin sheet sync afterwards — they are never pruned by this script.
//
// The JSON is keyed by document id; each value is the document body. `updatedAt`
// is stamped server-side here (stored as a Firestore Timestamp; the app reader
// normalizes Timestamp → ISO string).

import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const overwrite = process.argv.includes('--overwrite');
const prune = process.argv.includes('--prune');

const saPath = join(here, 'serviceAccount.json');
if (existsSync(saPath)) {
  console.warn(
    'WARNING: using serviceAccount.json — agreed policy is ADC. ' +
      'Revoke this key in GCP IAM and delete the file, then use ' +
      '`gcloud auth application-default login`.',
  );
  initializeApp({ credential: cert(JSON.parse(readFileSync(saPath, 'utf8'))) });
} else {
  // Project id: env var, or .firebaserc at the app root if present.
  let projectId = process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) {
    const rcPath = join(here, '..', '..', '.firebaserc');
    if (existsSync(rcPath)) {
      projectId = JSON.parse(readFileSync(rcPath, 'utf8')).projects?.default;
    }
  }
  initializeApp({ credential: applicationDefault(), projectId });
}
const db = getFirestore();

// prunable: false = admin-sheet-owned content; this script may add the
// initial docs but must never delete from it (ownership separation, §7 D5).
const COLLECTIONS = {
  facilities: { file: 'facilities.seed.json', prunable: true },
  guide_items: { file: 'guide_items.seed.json', prunable: true },
  building_floors: { file: 'building_floors.seed.json', prunable: true },
  academic_events: { file: 'academic_events.seed.json', prunable: false },
  cafeterias: { file: 'cafeterias.seed.json', prunable: false },
};

async function seedCollection(collection, file, prunable) {
  const docs = JSON.parse(readFileSync(join(here, file), 'utf8'));
  const entries = Object.entries(docs);
  let batch = db.batch();
  let ops = 0;

  for (const [id, body] of entries) {
    const ref = db.collection(collection).doc(id);
    const data = { ...body, updatedAt: FieldValue.serverTimestamp() };
    batch.set(ref, data, { merge: !overwrite });
    if (++ops === 400) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  console.log(
    `Seeded ${entries.length} docs into "${collection}" (${overwrite ? 'overwrite' : 'merge'}).`,
  );

  if (prune && !prunable) {
    console.log(`Skipping prune for admin-owned collection "${collection}".`);
  }
  if (prune && prunable) {
    const seedIds = new Set(Object.keys(docs));
    const existing = await db.collection(collection).listDocuments();
    const stale = existing.filter((ref) => !seedIds.has(ref.id));
    for (const ref of stale) await ref.delete();
    if (stale.length) {
      console.log(
        `Pruned ${stale.length} stale docs from "${collection}": ${stale.map((r) => r.id).join(', ')}`,
      );
    }
  }
}

for (const [collection, { file, prunable }] of Object.entries(COLLECTIONS)) {
  await seedCollection(collection, file, prunable);
}
console.log('Done.');
