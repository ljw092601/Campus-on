# API Integration Specification — Campus-On (Week 2, Data Layer)

> mobile-app-builder / API Integrator mode
> Scope: implement app-developer's Repository interfaces with **Firebase Cloud Firestore** (+ keep mock), add offline caching.
> Sources of truth: `02_app_architecture.md` (contracts) · `02_app_code/` (code) · `01_ux_design.md` §8 (data model) · `plan.md` (1인·1개월·$500, Firebase Spark free tier).
> **Backend, not REST.** Firestore is a client SDK, so this spec maps repository methods → Firestore reads (no HTTP endpoints/status codes/token flow). Sections below are adapted accordingly.

---

## 0. What changed (files)

| File | Change |
|------|--------|
| `lib/data/firestore/firestore_paths.dart` | **new** — collection names + doc→entity mapping (id injection, Timestamp→ISO) |
| `lib/data/firestore/firestore_facility_repository.dart` | **new** — `FacilityRepository` over Firestore |
| `lib/data/firestore/firestore_guide_repository.dart` | **new** — `GuideRepository` over Firestore |
| `lib/data/firestore/repository_exceptions.dart` | **new** — `DataRepositoryException` (typed throw → app Error state) |
| `lib/core/config/firebase_init.dart` | **new** — `useFirestore` flag + guarded `Firebase.initializeApp` + persistence |
| `lib/firebase_options.dart` | **new** — FlutterFire placeholder (no real keys) |
| `lib/presentation/providers/repository_providers.dart` | **edit** — 2 providers toggle mock↔Firestore on `useFirestore` |
| `lib/main.dart` | **edit** — call `initFirebaseIfEnabled()` |
| `pubspec.yaml` | **edit** — add `firebase_core`, `cloud_firestore` |
| `firestore.rules` | **new** — public read-only security rules |
| `tool/firestore_seed/*` | **new** — seed JSON + Admin SDK uploader + README |

**Interface signatures: unchanged.** Screens/providers/entities untouched. The only wiring edit is the swap point the architecture doc designated (`repository_providers.dart`) plus the `main.dart` init hook the app-developer explicitly flagged as "add if Firebase needed".

---

## 1. Firestore Schema (collections / fields / types / indexes)

Two top-level collections, **document id == entity id** (so `getById(id)` is a direct `doc(id)` lookup, no query).

### `facilities/{id}`
| Field | Type | Req | Notes / entity mapping |
|-------|------|-----|------------------------|
| `name_ko` | string | ✅ | `Facility.nameKo` |
| `name_en` | string | ✅ | `Facility.nameEn` |
| `category` | string | ✅ | enum id ∈ {`building`,`classroom`,`dining`,`library`,`amenity`,`etc`} — unknown → `etc` |
| `lat` | number | ✅ | `Facility.lat` (double) |
| `lng` | number | ✅ | `Facility.lng` (double) |
| `address_ko` / `address_en` | string | – | nullable |
| `building_ko` / `building_en` | string | – | e.g. "A동 2F" |
| `hours_ko` / `hours_en` | string | – | free text |
| `phone` | string | – | |
| `description_ko` / `description_en` | string | – | |
| `imageUrl` | string | – | absent → app shows category banner (Partial state) |
| `updatedAt` | **timestamp** | – | stored as Firestore Timestamp; reader normalizes → ISO string |

> `id` is **not** stored in the body (it is the doc key); the mapper injects it. Storing it too is harmless.

### `guide_items/{id}`
| Field | Type | Req | Notes / entity mapping |
|-------|------|-----|------------------------|
| `categoryId` | string | ✅ | enum ∈ {`immigration`,`housing`,`living`,`health`,`school`,`emergency`} |
| `title_ko` / `title_en` | string | ✅ | |
| `summary_ko` / `summary_en` | string | – | 1-line list summary |
| `relatedFacilityIds` | array\<string\> | – | deep-link `/map?focus=<ids>` |
| `icon` | string | – | Material Symbols name overriding the category icon in list rows (`sim_card`, `account_balance`, …); unknown names fall back to the category icon |
| `checklist_optional_ko` / `_en` | array\<string\> | – | second checklist group ("경우에 따라 필요할 수 있어요") |
| `detail_title_ko` / `_en` | string | – | fuller heading for the detail screen when the list row should stay short; falls back to `title_*` |
| `sections` | array\<object\> | – | item-specific sections rendered after `steps`: `{title_ko,title_en,icon,body_ko,body_en,steps_ko[],steps_en[],notes:[{title_ko,title_en,lines_ko[],lines_en[]}],notice_ko,notice_en}` — `steps_*` draw the same numbered circles as the main steps section |
| `status` | string | – | `published` \| `comingSoon` (default `comingSoon`) |
| `updatedAt` | timestamp | – | |
| _week-3 fields_ | | | `overview_*`, `checklist_*[]`, `steps_*[]`, `links[]`, `meta{}` — reserved by UX §8, added on the SAME docs later; today's mapper ignores unknown fields |

> `links[]` entries also accept `description_ko`/`description_en` (rendered as the row subtitle) and an optional `icon` (same name lookup as the item-level `icon`). A `url` starting with `/` is treated as an in-app route rather than an external page — e.g. `/map?nearby=편의점,지하철역` opens S2 and pins those search results.

### Indexes
**None required for week 2.** All reads are whole-collection `get()` or single-doc `get()` — served by the automatic single-field index. No composite index, no `where`/`orderBy`. (If week-3 moves search server-side, add composite indexes then.)

---

## 2. Repository method → Firestore query mapping

| Interface method | Firestore operation | Reads billed |
|------------------|---------------------|--------------|
| `FacilityRepository.getAll()` | `collection('facilities').get()` | N docs (cached after 1st) |
| `FacilityRepository.getById(id)` | `collection('facilities').doc(id).get()` | 1 |
| `FacilityRepository.getByIds(ids)` | **reuse `getAll()` + in-memory filter** | 0 extra (served from cache) |
| `FacilityRepository.search(q)` | **reuse `getAll()` + client contains filter** on `name_ko`/`name_en` | 0 extra |
| `GuideRepository.getAllItems()` | `collection('guide_items').get()` | M docs |
| `GuideRepository.getById(id)` | `collection('guide_items').doc(id).get()` | 1 |
| `GuideRepository.search(q)` | reuse `getAllItems()` + client contains on `title_ko`/`title_en` | 0 extra |
| `FavoritesRepository.*` | **not Firestore** — stays `LocalFavoritesRepository` (SharedPreferences) | 0 |

**Why `getByIds`/`search` reuse `getAll` instead of `whereIn`/server search:**
- Campus dataset is tiny (single university) → one whole-collection read that Firestore then serves from local cache is cheaper across a session than repeated `whereIn` queries, and it keeps search **client-side exactly as the UX doc decided** (§8, "클라 검색, 소량이면 서버 불필요").
- `whereIn` also caps at 30 ids and can't do case-insensitive substring; client filter has neither limit.
- Signatures unchanged → if week-3 data grows, only the private `_loadAll` internals change.

**Failure behavior:** on `FirebaseException` with no usable cache, methods throw `DataRepositoryException` → presentation renders `AsyncValue.error` → `ErrorStateView` + `common_retry` (which calls `ref.invalidate`). Matches the architecture doc's error table.

---

## 3. Caching / Offline strategy (and rationale)

### Decision: **Firestore built-in offline persistence + per-read `Source.cache` fallback.** No Hive/Isar.

| Layer | Mechanism | TTL / invalidation |
|-------|-----------|--------------------|
| In-flight | Firestore in-memory query cache | process lifetime |
| On-disk | **Firestore local persistence** (SQLite/LevelDB, enabled in `firebase_init.dart`) | until next successful server sync overwrites it; unbounded size (`CACHE_SIZE_UNLIMITED`) |
| Explicit fallback | `get(GetOptions(source: Source.cache))` when a live `get()` throws | serves last-synced snapshot instead of an error screen |

How it behaves:
- **Online (normal):** `get()` hits server, returns fresh docs, persistence updated.
- **Offline / slow:** default `get()` already returns the last-synced snapshot from persistence (no code needed). On top of that, if the server call errors, the repo explicitly retries against `Source.cache` before throwing — so a flaky network still shows cached content.
- **First run offline (never synced):** cache empty → repo throws → Error state with retry. Correct: there is genuinely nothing to show.
- **Writes:** none (MVP is read-only), so no write queue / conflict resolution is needed.

### Why NOT Hive/Isar (over-engineering avoided — required rationale)
- Firestore persistence **already** gives the "last successful snapshot + offline read" that UX §8 asked for — a second cache would duplicate it.
- Hive/Isar add a dependency, a schema/adapter (Isar needs build_runner code-gen — explicitly avoided by the architecture's "no codegen" rule), a manual write-through/invalidation path, and migration risk — all for a dataset of a few dozen docs.
- Cost/benefit for 1인·1개월·$500: **not worth it.** Documented here so week-3 can revisit only if data volume or richer offline UX demands it (it's in the TODO list).

### Offline UX hooks (already in the app, no new code needed)
- **Read:** cached data renders normally. An "offline banner" is a **presentation** concern still on the week-3 TODO; the data layer's job (serve cache) is done. If/when added, it can watch connectivity — the repos don't need to change.
- **Map tiles:** Kakao tiles are not offline-capable (UX §8); S2 already falls back to the facility list. Unchanged.
- **Favorites / language / recent search:** fully local (SharedPreferences), work offline already.

---

## 4. Mock ↔ Firestore toggle (how to switch)

**One flag, one place:** `const bool useFirestore = bool.fromEnvironment('USE_FIRESTORE', defaultValue: false);` in `lib/core/config/firebase_init.dart`. Both `repository_providers.dart` (which impl) and `main.dart` (whether to init Firebase) read it.

```bash
# Default — mock data, NO Firebase setup required (dev / QA / offline demo)
flutter run

# Firestore-backed (requires flutterfire configure + seeded data)
flutter run --dart-define=USE_FIRESTORE=true

# Combine with the existing Kakao key define
flutter run --dart-define=USE_FIRESTORE=true --dart-define=KAKAO_JS_KEY=...
# or a single file:  flutter run --dart-define-from-file=env.json   ({ "USE_FIRESTORE": "true", "KAKAO_JS_KEY": "..." })
```

- Flag **off** (default): `FirebaseFirestore.instance` is never touched and `Firebase.initializeApp` is skipped → the app boots on mock with zero Firebase config. This keeps app-developer, QA smoke tests, and demos unblocked.
- Flag **on**: providers return `Firestore*Repository`; `main()` initializes Firebase + persistence.
- **Tests** can still force either side with `ProviderScope(overrides:)` regardless of the flag (existing pattern), e.g. inject a fake `FacilityRepository`.

---

## 5. Security rules (draft)

`firestore.rules` — **public read, all client writes denied** (MVP is login-free, browse-only; content seeded via Admin SDK which bypasses rules):

```
match /facilities/{facilityId}  { allow read: if true;  allow write: if false; }
match /guide_items/{itemId}     { allow read: if true;  allow write: if false; }
match /{document=**}            { allow read, write: if false; }   // default deny
```

Deploy: `firebase deploy --only firestore:rules`. Secrets: no API/service keys in code; `firebase_options.dart` holds only public app config (placeholder until `flutterfire configure`); the Admin service-account key lives only in `tool/firestore_seed/serviceAccount.json`, which is git-ignored (`02_app_code/.gitignore` — `tool/firestore_seed/serviceAccount.json` + `node_modules/`) so it can never be committed.

---

## 6. Free-tier cost estimate (Firebase Spark)

Spark free quota: **50,000 document reads/day**, 1 GiB stored, 10 GiB/mo egress.

- Dataset: ~dozens of facility docs + a handful of guide docs → storage & egress negligible (well under 1 GiB).
- Reads per app session (cold, online): `getAll` facilities (~N) + `getAllItems` (~M) + a few `getById` = **on the order of tens of reads**. Warm/offline sessions read **0** (served from persistence).
- Even at, say, 40 reads/session that's **~1,250 sessions/day** before touching the 50k free ceiling — far beyond an MVP for one university.
- **Verdict: $0 on Spark, comfortably.** No billing account needed for MVP. Matches plan.md budget (Firebase = $0).

---

## 7. Firebase initialization path

1. `main()` → `await initFirebaseIfEnabled()` (before `runApp`, after `ensureInitialized`).
2. `initFirebaseIfEnabled()` (in `firebase_init.dart`): no-op if `!useFirestore`; else `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` then set `Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)`.
3. `firebase_options.dart` is a **placeholder**; real values come from `flutterfire configure` (also drops `android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`). Placeholders are obvious `REPLACE_*` strings so an accidental `USE_FIRESTORE=true` run fails fast at init rather than pointing at a wrong project.
4. pubspec deps: `firebase_core: ^3.6.0`, `cloud_firestore: ^5.4.4` (resolver picks latest compatible; `flutterfire configure` may repin).

---

## Handoff Notes for App Developer

- **No interface changes.** Your `repository_providers.dart` swap point worked exactly as designed — only the 2 content providers now branch on `useFirestore`; favorites stays `LocalFavoritesRepository`. Screens/providers/entities untouched.
- I added **one** thing to `main.dart` you had pre-approved ("Firebase init 필요 시 main()에 추가"): `await initFirebaseIfEnabled()`, a no-op unless `--dart-define=USE_FIRESTORE=true`.
- `search()`/`getByIds()` stay **client-side** (load-all + filter) per your + UX guidance; signatures identical.
- Entity `fromJson` field names are honored verbatim; the only adapter is Timestamp→ISO for `updatedAt` (done in `firestore_paths.dart`, not in your entities).
- **Nothing needs app-developer sign-off** — but see the one optional item under "Coordination" below.

## Handoff Notes for QA Engineer

- **Two run modes to regress:** default (mock, no Firebase) and `--dart-define=USE_FIRESTORE=true` (needs `flutterfire configure` + seeded data).
- **Seed** a Firestore test project via `tool/firestore_seed/` (Admin script or console). Same 6 facilities + 3 guide items as the mock, so mock and Firestore should render identically — a good A/B oracle.
- **5-state coverage** on Firestore path: Success (seeded), Empty (empty collection), Error (wrong project / rules blocking read), Partial (docs missing `imageUrl`/`hours`), Loading. Error/retry uses the existing `ErrorStateView`.
- **Offline test:** load online once, enable airplane mode, relaunch → cached data should still render (Firestore persistence). First-ever launch offline → Error state (expected).
- **Security-rules test:** in the Rules Playground, a client `write` to `facilities` must be denied; `read` allowed. No auth token is used (login-free).
- No test auth credentials exist by design (MVP has no login). "Test auth" = the Admin service-account key for seeding only; keep it out of git.

## Coordination needed with app-developer (optional, non-blocking)

- Repos throw a typed `DataRepositoryException` (implements `Exception`). The interface only promised "throw"; the presentation layer treats any error uniformly, so this is compatible. **No action needed** unless the app-developer wants to surface a distinct offline vs. server-error message — if so, that's a small presentation-side switch on the exception type, not an interface change.

## Remaining TODO

- Run `flutterfire configure` against the real Firebase project → replaces `firebase_options.dart` placeholders + adds platform config files.
- Seed the real project (`tool/firestore_seed/seed.mjs`) and deploy `firestore.rules`.
- Fill real `imageUrl`s / guide content — schema already supports it (`published` status flips per item). Seed the same fields the app now reads (below).
- **Offline banner** (presentation): optional connectivity watcher; data layer already serves cache, no repo change required. Deferred to Phase-2 (4주차 후보).

### Week 3 완료 — guide detail + offline caching (2026-07-14)

- **`GuideRepository.getByCategory(GuideCategory)` added** (mock + Firestore). Firestore impl filters the cache-friendly `_loadAll()` client-side (campus-small dataset) so it inherits the same `Source.cache` offline fallback; both impls order via shared `orderGuideItems` (published first).
- **`guide_items` docs now consumed in full** by S7: `overview_ko/en`, `checklist_ko/en` (array), `steps_ko/en` (array), `links` (`[{label_ko,label_en,url}]`), `relatedFacilityIds`, and `meta:{durationText_ko,durationText_en,difficulty}`. Seed these fields; `status:comingSoon` items may omit them (the screen renders the standard placeholder). One exemplar (`arc-issue`) is authored end-to-end in the mock as the seeding reference.
- **Offline caching finalized**: Firestore persistence set explicitly in `firebase_init.dart`; every read path (facility `getAll`/`getById`, guide `getAll`/`getById`/`getByCategory`) has a `Source.cache` fallback. Verify with the airplane-mode relaunch test above.
- Map markers now load from bundled PNG assets (`assets/markers/`) via `MarkerIcon.fromAsset` — no network, no impact on the repository layer.
- ~~`.gitignore`: add `tool/firestore_seed/serviceAccount.json` and `node_modules/`.~~ **Done** — both lines added to `02_app_code/.gitignore` (QA 🔴-C1).
- Confirm real campus center coordinate (`AppConfig.campusCenterLat/Lng`) with the seeded facility coordinates (currently Seoul placeholder coords, shared with mock).
