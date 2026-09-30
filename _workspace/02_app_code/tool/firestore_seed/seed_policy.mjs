// Atomic create prevents both reseeding and a concurrent admin edit from
// being replaced. Never fall back to set(), including with --overwrite.
export async function createMissingAdminDocs(db, collection, entries, timestamp) {
  let created = 0;
  for (const [id, body] of entries) {
    try {
      await db.collection(collection).doc(id).create({ ...body, updatedAt: timestamp() });
      created++;
    } catch (error) {
      if (error.code !== 6 && error.code !== 'already-exists') throw error;
    }
  }
  return created;
}
