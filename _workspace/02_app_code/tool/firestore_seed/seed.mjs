// Firestore seeder — uploads facilities.seed.json + guide_items.seed.json.
//
// Uses the Firebase Admin SDK, which bypasses security rules (server-side),
// so `firestore.rules` can keep client writes fully blocked.
//
// Prereqs (one-time):
//   npm init -y && npm install firebase-admin
//   # Firebase console → Project settings → Service accounts → Generate new
//   # private key → save as serviceAccount.json next to this file (DO NOT COMMIT).
//
// Run:
//   node seed.mjs                    # upsert (merge) — safe to re-run
//   node seed.mjs --overwrite        # replace each doc entirely
//   node seed.mjs --overwrite --prune  # …and delete docs absent from the seed
//
// The JSON is keyed by document id; each value is the document body. `updatedAt`
// is stamped server-side here (stored as a Firestore Timestamp; the app reader
// normalizes Timestamp → ISO string).

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const overwrite = process.argv.includes('--overwrite');
const prune = process.argv.includes('--prune');

const serviceAccount = JSON.parse(
  readFileSync(join(here, 'serviceAccount.json'), 'utf8'),
);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const COLLECTIONS = {
  facilities: 'facilities.seed.json',
  guide_items: 'guide_items.seed.json',
  building_floors: 'building_floors.seed.json',
};

async function seedCollection(collection, file) {
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

  if (prune) {
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

for (const [collection, file] of Object.entries(COLLECTIONS)) {
  await seedCollection(collection, file);
}
console.log('Done.');
