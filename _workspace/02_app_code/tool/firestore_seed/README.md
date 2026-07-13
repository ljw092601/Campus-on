# Firestore seed data

Seed the two public collections used by Campus-On:

| Collection    | Source file              | Doc id  |
|---------------|--------------------------|---------|
| `facilities`  | `facilities.seed.json`   | the JSON key (e.g. `lib-central`) |
| `guide_items` | `guide_items.seed.json`  | the JSON key (e.g. `arc-issue`)   |

Each JSON is `{ "<docId>": { ...fields }, ... }`. Field names match the app
entities' `fromJson` exactly (`name_ko`, `hours_en`, `categoryId`, `relatedFacilityIds`, …).

## Option A — Admin SDK script (recommended, repeatable)

```bash
cd tool/firestore_seed
npm init -y && npm install firebase-admin
# Firebase console → Project settings → Service accounts → Generate new private
# key → save as serviceAccount.json here.  ⚠️ DO NOT COMMIT this file.
node seed.mjs                 # merge/upsert — safe to re-run
node seed.mjs --overwrite     # full replace of each doc
```

The Admin SDK runs server-side and bypasses `firestore.rules`, so client writes
stay blocked while you can still seed.

`.gitignore` suggestion:
```
tool/firestore_seed/serviceAccount.json
tool/firestore_seed/node_modules/
```

## Option B — Firebase console (manual, no tooling)

1. Firestore Database → **Start collection** → id `facilities`.
2. For each entry in `facilities.seed.json`: **Add document**, set the Document
   ID to the JSON key, then add each field with the matching type
   (`lat`/`lng` = number, `relatedFacilityIds` = array, the rest = string).
3. Add an `updatedAt` field of type **timestamp** (set to now).
4. Repeat for `guide_items` from `guide_items.seed.json`.

`updatedAt` is optional for reads (the app tolerates its absence) but recommended
so week-3 "last updated" UI and cache reasoning work.
