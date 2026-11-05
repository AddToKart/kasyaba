# KASYABA — Online-First Alignment & Legal Compliance Plan

> **Date:** 2026-11-06 · **Status:** PLAN (approved direction; not yet executed) · **Supersedes:** the offline expectations implied by the retired "local-first" draft. Complements `plan.md` (stabilization/UI), which is complete in the working tree.
>
> **Thesis framing:** KASYABA is a **server-backed, online-first personal finance app** with a device layer for instant interaction, offline capture, and privacy-preserving local math. Everything below is written so each policy sentence can be traced to code and a test (policy↔code verification matrix in §4.3).

---

## 1. North-star architecture contract (single source of truth)

This table IS the product truth. Policy copy, FAQ, Play listing, and onboarding copy must be derived from it — never the reverse.

| Capability | Runs on | Offline playable? | Stored where |
|---|---|---|---|
| Auth (login/register/tokens/rotation) | Server; device holds tokens only | Session restore cached | Postgres (hashed) + secure storage (tokens) |
| Ledger (wallets, transactions, transfers) | **Server (source of truth)** | **Read from cache; capture offline into queue** | Postgres + device snapshot cache + offline queue |
| Balance aggregation & dashboard totals | **Server** | Cached snapshot + queued-transaction overlay (labeled stale) | Postgres + device snapshot |
| Bill generation (2-month lookahead), overdue flips | **Server (worker)** | No — online only | Postgres |
| Health score & grade, snapshots/trend archive | **Server (worker/daily cron)** | No — online only | Postgres |
| 30-day planning horizon + pressure levels | **Server** | No — online only | Postgres |
| Affordability verdict ("Can I afford it?") | **Server (purchase-check)** | No — online only | Postgres (request-scoped) |
| Bill notifications | Device-scheduled from bill data; server reminders are the schedule source | Last-synced state | Postgres + device notification scheduler |
| Daily safe-to-spend, payday countdown, excluded accounts | **Device (deterministic, zero server delay)** | ✅ Fully offline (uses cached inputs) | Computed, not stored |
| PH statutory deductions (SSS/PhilHealth/Pag-IBIG/TAX) | **Device** | ✅ Offline | Computed |
| Affordability simulator interactive math (installments, interest, cash-preserved, work-hours) | **Device (live as you type)** | ✅ Offline (needs a price; salary from profile) | Computed |
| Allocation bar proportions / goal progress % | **Device** | ✅ When the inputs are cached | Computed |
| Offline capture queue | Device → replayed to server | ✅ | Drift `offline_transactions` |
| App preferences (theme, notification prefs, excluded accounts) | **Device only** | ✅ | **Encrypted secure storage** (never SharedPreferences) |

**Wording law (use everywhere):** *online-first* · **never** "local-first", "every calculation runs on your device", "100% on-device math", or "fully functional offline".

---

## 2. Compliance baseline (targets, not aspirations)

1. **RA 10173 (PH DPA 2012) + IRR**: lawful processing + consent at registration (existing terms checkbox — keep), transparency (this plan), data-subject rights (access/export ✅, correction = in-app editing, erasure ✅, portability ✅), security measures (TLS, password hashing, least storage), breach notification commitment (72h NPC reporting clause to ADD), retention statement (ADD: records retained while account active; sessions/jobs pruned; device caches cleared on sign-out).
2. **Google Play Data Safety**: map every collected field (email, display name, hashed password, financial entries, IP-for-rate-limit, hashed refresh tokens) → "encrypted in transit", "users can request deletion", no collection for advertising/sharing. Policy URL serves `/privacy` in production.
3. **Play account deletion** requirement: in-app flow (exists) + web portal `/account-deletion` (exists) — verify links reachable from Play listing.
4. **Honest infra claims (per D6, softened):** all shipped copy says "encrypted in transit (HTTPS/TLS)" without unverified protocol specifics; if the VPS/Postgres at-rest encryption is later verified, upgrade wording deliberately. Argon2id ✅ (code-verified). Device cache is **plaintext on device** — disclosed per D5.
5. **Accuracy bar:** every policy sentence maps to code (§4.3 matrix) and to at least one automated test where feasible.

---

## 3. Confirmed gaps (evidence from the 2026-11-06 audit)

| ID | Gap | Evidence (current code) | User impact |
|---|---|---|---|
| G1 | Policy says "Every calculation runs on your device" / "100% on-device math" | `privacy_about_screen.dart:191,:242` | Legal inaccuracy; reviewers/user distrust |
| G2 | `/privacy §1` "Locally-Derived Analytics: health scores … snapshots" | `legal/routes.ts:30` | Misrepresents server-side calc |
| G3 | `/privacy §1` Google Sign-In storing Google ID/avatar | `legal/routes.ts:29` | Stale (UI removed) |
| G4 | "Export entire database … JSON or CSV" | `legal/routes.ts:47` | CSV is transactions-only |
| G5 | Only dashboard is cached; wallets/transactions/bills/goals/budgets/alerts are not | `database.dart:5-36` (2 tables), providers fetch-only | Policy-adjacent gap + weak offline UX |
| G6 | Offline **expense** often fails before queueing (fake `cat_food` id → categories lookup) | `api_providers.dart:_resolveCategoryId` `on DioException → StateError` | Breaks the "log expense offline" promise |
| G7 | Queue replay invalidates only 4 providers | `offline_sync_service.dart:28-31` | Stale planning/bills/goals/budgets/alerts after reconnect |
| G8 | Dashboard cache has no timestamp/age surfacing (no expiry) | `cache_service.dart:23-51` | Users can't tell data age |
| G9 | Failed offline fetch shows ALL queued entries unfiltered & as page 1 | `api_providers.dart` paginated catch | Confusing "where did my history go" |
| G10 | No per-screen online/offline capability states; CTAs not gated (mark-paid offline → 409-ish errors) | screens | "Everything doesn't work" feel |
| G11 | Goal deposit not queueable offline (server supports idempotency) | mutator direct POST | Missed offline-capture case |
| G12 | Bill reminders don't re-arm after cold-start offline (bills uncached) | `bill_reminder_sync.dart` | Missed reminders |
| G13 | In-app version hardcoded; duplicate constants | `privacy_about_screen.dart:17,:290` vs `core/app_info.dart` | Drift |
| G14 | Clearing/retention of device data on logout/deletion undefined | auth flows | Data-minimization gap |
| G15 | TLS/AES-at-rest claims unverified | infra | Legal claim risk |

---

## 4. Design decisions — **LOCKED (2026-11-06, all decisions approved by owner)**

- [x] **D1 — Canonical policy source (ACCEPTED):** the backend `legal` module is the single policy; the app renders a **short in-app summary** + "Read full policy" opening the hosted `/privacy` (in-app browser sheet; falls back to last-fetched text off-line). Copies are never edited by hand in three places again. *(Play Console already points at backend `/privacy` — canonical confirmed; the retired "local-first" draft document is not a shipped policy and needs no further alignment.)*

- [x] **D2 — Unified offline snapshot store (ACCEPTED):** one Drift table `cached_snapshots (userId, key, json, fetchedAt)` + `CacheService.getSnapshot/putSnapshot`. Keys: `dashboard`, `accounts`, `balances? (derived)`, `transactions:page1`, `categories`, `bills`, `goals`, `budgets`, `alerts`. Drift migrates v3→v4 (additive; test it).

- [x] **D3 — Offline-capable writes (ACCEPTED):** queue = expense/income/transfer **plus goal deposit** (idempotent via existing `clientMutationId`). Everything else (bill paid/cancel, budget, account, profile, restore) is **online-only** with explicit "Needs internet" gating.

- [x] **D4 — Local data retention (ACCEPTED):** sign-out clears **read caches**; **keeps** the offline queue (data-loss prevention; re-attaches by `userId` at sign-in). Account deletion clears tokens + caches + queue.

- [x] **D5 — Device storage posture (ACCEPTED):** tokens & preferences in `flutter_secure_storage` (encrypted); snapshot cache & queue in **plaintext device DB** — disclosed plainly in policy (SQLCipher explicitly deferred; see §8).

- [x] **D6 — TLS/at-rest claims (ACCEPTED · SOFTENED):** shipping copy now says **"Your data is encrypted in transit (HTTPS/TLS)"** and **drops the unverified "TLS 1.3 & AES-256 at rest" specifics**. Optional non-blocking follow-up: verify TLS protocol enforcement + Postgres disk encryption on the VPS and *upgrade* the wording later. The Phase A-7 checklist remains as documentation-only hygiene.

---

## 5. Phased execution (checkbox plan; sub-agent dispatchable)

### Phase A — Policy & copy alignment (unblocks everything)
- [ ] **A-1** Rewrite `/privacy`, `/terms`, `/account-deletion` to the online-first contract (§1) — backend `legal/routes.ts`. Include: what runs where (right/wrong examples avoided), cached-on-device dashboard+snapshots+queue (plaintext, cleared on sign-out except queue), server-side analytics (health/planning/forecast), queue behavior & retry cap, retention & breach-reporting clause, Google sign-in line removed/qualified, export wording (JSON full / CSV transactions).
- [ ] **A-2** In-app Privacy & About: hero → *"Your ledger lives on our server; day-to-day math runs instantly on your device."*; "What we keep" rows → Records: *"Server-backed with offline cache"*; Calculations: *"Daily math on-device; planning & forecasts on server"*; keep Zero-AI + RA 10173 rows. Version row → `kAppVersionLabel`.
- [ ] **A-3** Global policy fetch: app summary sheet gains "Read full policy" → hosted `/privacy` (browser or in-app sheet); cache last-fetched policy text for offline reading.
- [ ] **A-4** Update all copy strings that say local-first-style claims: register/terms checkbox text, register hero (`auth_widgets.dart:844` "Calculated on your device…"), password screens, settings, plus the in-app About; grep for "local-first|on your device|100% on-device".
- [ ] **A-5** Update tests bound to copy: `auth_screens_test.dart:46,:94`, `profile_suite_test.dart:305,:318`; add `policy_content_test.dart` asserting the new canonical claims exist and banned phrases ("100% on-device", "Every calculation runs", "local-first") are absent app-wide.
- [ ] **A-6** Create `docs/compliance/policy-code-matrix.md`: every policy claim → code file → test id. Add "Last updated" bump + versioned changelog section in policy.
- [ ] **A-7** Infra posture documentation (non-blocking per softened D6): note in the matrix doc that exact TLS protocol + at-rest encryption are deployment-config dependent; record the VPS findings only when available; keep rate-limit IP storage disclosure (already in policy §1).

### Phase B — Offline data layer (unified snapshots, D2)
- [ ] **B-1** Drift v4 migration: add `cached_snapshots` table (+ tests for migration 3→4 including existing data intact).
- [ ] **B-2** `CacheService`: `putSnapshot/getSnapshot/clearSnapshotsFor/user-scoped` (+ fetchedAt handling). Wrap as typed helper `OfflineSnapshot<T>{ value, fetchedAt }`.
- [ ] **B-3** Write-through on success + fallback-on-failure in providers: dashboard (migrate to unified store), accounts (+balances), transactions page-1 (with the SAME filter semantics: cache the defaulted page-1; filtered/unfiltered distinction), categories, bills, goals, budgets, alerts. Return `OfflineSnapshot` so UI can show age.
- [ ] **B-4** Cache hygiene: clear read-snapshots on sign-out (D4); wipe all on account deletion; keep queue. Never serve another user's snapshot (userId-keyed; test).
- [ ] **B-5** Unit tests: cache write/read, per-user isolation, fallback with stale flag, migration, sign-out clearing, account-deletion wipe.

### Phase C — Offline capture queue (fixes G6/G11, fulfills "log expense offline")
- [ ] **C-1** Expense path: when `categoriesProvider`/cache holds the selection's UUID → queue exactly as today; otherwise queue with `categoryName` (+ client temp id) and **skip** the online-only `_resolveCategoryId` while offline (detect via `isOnlineProvider` before the lookup). Server replay resolves name→UUID (mutator already name-matches; add a resolver step in `syncPendingTransactions` that calls `_resolveCategoryId` when replaying expenses).
- [ ] **C-2** Income/transfer: unchanged (already queue).
- [ ] **C-3** Goal deposit queueing: new op `goal_contribution` queued with `clientMutationId`; replay posts `/goals/{id}/contributions` (server idempotency guaranteed); failure handling as transactions.
- [ ] **C-4** Replay invalidation: after a successful replay batch, invalidate the FULL finance set (reuse `invalidateFinanceData` from `session_refresh_provider.dart` — make it accept `Ref` and reuse; fixes G7). PendingCount/badges refresh via stream already.
- [ ] **C-5** Queue UX: failed entries remain visible with reason (existing sheet) and a "will retry automatically x/5" copy; unknown/unsupported ops message unchanged.
- [ ] **C-6** Tests: offline expense queues with categoryName & replays to a resolved UUID; goal deposit queues/replays idempotently (replay twice — server sees one instance via fake adapter asserting `clientMutationId` reuse); full invalidation after replay (assert ≥9 providers refetch); retry-cap behavior.

### Phase D — Offline UX & "tool-ready" states (G8–G10)
- [ ] **D-1** Global banner upgrade: "Offline — showing saved data · changes sync when you reconnect" + cached-age chip per provider result ("Updated 3h ago"; ≤72h normal; >72h explicit "very old data").
- [ ] **D-2** `OfflineCapabilities` helper (single map: per-module cached? queueable? online-only?) consumed by screens; CTAs disabled with reason chips when online-only and offline (mark bill paid, create budget, add account, edit salary, affordability *Evaluate*, delete account).
- [ ] **D-3** Transactions offline: cached page-1 + queued (consistent with the active month filter; if filter ≠ cached page, show cached-default page with a "Switch to saved view" action) — no more unfiltered dump (G9).
- [ ] **D-4** Bills reminders: when bills snapshot exists, reminder sync uses cached bills on cold start (G12) — pure reuse of existing resolver.
- [ ] **D-5** Standardized empty vs error vs cached widgets (existing kit) — audit sweeps complete; add policy-consistent copy ("This list needs internet").
- [ ] **D-6** Widget tests: offline banner per module, disabled CTAs show reason, cached-age chip, transactions month-switch fallback.

### Phase E — Compliance & release hardening
- [ ] **E-1** Play Data Safety mapping doc (field → collected? stored where? shared? deleted?) and verify the Console form matches (D1 source of truth). Play Console privacy URL already targets backend `/privacy` — re-verify the page content after the policy rewrite deploys.
- [ ] **E-2** RA 10173 closes: breach-notification clause; retention section; NPC registration/compliance note in thesis appendix; DPIA-lite section in matrix doc.
- [ ] **E-3** Consent UX: registration shows summary + hosted policy link + checkbox (verify current checkbox state post-`4a40309`; keep copy consistent with online-first wording).
- [ ] **E-4** Release build: `--dart-define=API_BASE_URL` production build, release signing + versionName/Code bump, R8/ProGuard rules sanity for drift/sqlite, App Bundle (AAB) assembly, `flutter analyze`/`test` gates.
- [ ] **E-5** Device smoke matrix (scripted checklist): cold-start offline (dashboard cached + age), add expense offline → reconnect → replay + full refresh, add income/transfer offline, goal deposit offline, bills offline read-only + disabled mark-paid, reminders re-arm from cache, logout clears caches (queue retained), account deletion wipes device data.
- [ ] **E-6** Android release-compliance pins: set explicit `compileSdk`/`targetSdk` (≥35) and `minSdk` in `android/app/build.gradle.kts` (replace inherited `flutter.*` defaults so the Play target-API requirement is guaranteed, not accidental); keep `USE_EXACT_ALARM` absent; verify runtime `POST_NOTIFICATIONS` request; add `dataExtractionRules`/`fullBackupContent` XML **excluding flutter_secure_storage prefs and Drift DBs from cloud backup**; wire into both debug + release.
- [ ] **E-7** Reviewer-access pack: create a dedicated demo account on staging/prod (seeded with sample wallets/bills/goals via the JSON restore flow), document credentials, add them to Play Console "App access"; confirm the app opens to a usable demo state within 60s on a fresh install.

### Phase F — Verification gates (repeat per phase merge)
- [ ] **F-1** Backend: `tsc --noEmit`, `npm test` (175 → +new cache/queue-adjacent tests if server changes needed — none expected server-side beyond zero).
- [ ] **F-2** Client: `flutter analyze` clean; full `flutter test` green (current baseline 243 → grow with Phases B–D).
- [ ] **F-3** `flutter build appbundle --release --dart-define=API_BASE_URL=…` assembles.
- [ ] **F-4** `docs/compliance/policy-code-matrix.md`机械化 checked: no banned phrases in user-facing strings (CI-greppable script optional).
- [ ] **F-5** Deployment gate enforced in runbook + psychologically for the team: **backend MUST be live (reachable `/privacy`, `/account-deletion`, `/api/v1`) before the Play listing goes up for review** — the policy/deletion URLs are checked at submission; a non-live VPS is an automatic fail. Order: deploy backend → run `db:repair-bills` (dry-run→apply) → verify public URLs → upload AAB to internal testing → complete Console checklist (Data Safety, ratings, App access, listing assets) → promote to production.

---

## 6. Policy↔Code verification matrix (target state; fill test ids during Phases A–D)

| Policy claim (final wording) | Code evidence | Test |
|---|---|---|
| Ledger, wallets, transactions, bills, budgets, goals stored on our PostgreSQL (hashed credentials; Argon2id) | `prisma/schema.prisma`, `auth/service.ts` argon2 | backend auth tests |
| Dashboard totals/planning(30d)/health score/snapshots/forecast verdict computed server-side | `dashboard|planning|forecasting service.ts` | backend suites |
| Bill generation +2mo & overdue flips + 00:10 Manila snapshot (hourly) | `bills/service.ts`, `worker.ts` | bills service tests |
| Device stores tokens + preferences in encrypted secure storage | `flutter_secure_storage`, `secure_storage_service.dart`, prefs/excluded providers | prefs tests |
| Device caches: dashboard + wallets + recent transactions (plaintext, user-scoped; read-caches cleared on sign-out) | B-2/B-3 files | B-5/B-4 tests |
| Offline queue captures expense/income/transfer/goal deposit; replays idempotently; retry cap 5 | mutator + cache service | C-6 tests |
| Daily math on device: safe-spend (excluded wallets), payday schedules, statutory deductions, simulator math, allocation, goal progress | `deterministic_math.dart`, `ph_salary_calculator.dart`, screens | existing suites |
| Server-corrective analytics (health/planning/forecast) require connection; UI states this | D-1/D-2 | D-6 tests |
| Export JSON (full) / CSV (transactions) | data_backup_sheets | CSV pagination QA |
| Delete account in-app + web portal; device data wiped | delete_account + E-2 wording | E-5 smoke |

## 7. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Stale cache shown as truth | Age chip + stale-first-craft copy; never omit fetchedAt |
| Double-count queued vs server rows | Existing overlay logic confined to dashboard; transactions merged on page 1 only w/ dedupe by clientMutationId/id |
| Replay duplicates on flaky networks | server idempotency keys already accepted (expenses/income/transfers/contributions) — keep clientMutationId generation stable per queue row |
| Migration v4 wipes old data | additive-only migration + test on copy of schema |
| Policy drift returns | D1 single source + A-5 banned-phrase test |
| Plaintext device cache criticism | disclosed plainly (D5); encrypt-at-rest is server-side; SQLCipher optional follow-up |
| Scope creep (SQLCipher/local planners) | explicitly OUT of scope v1 |

## 8. Out of scope (v1)
SQLCipher/encrypted device DB · local 30-day planner · offline bill creation/cancellation · Google Sign-In restoration (backend route dormant) · light theme.

**Execution prerequisites (branch decision LOCKED):** the 32 unstabilized-but-uncommitted files currently on `redesign/figma-ui` (stabilization + sync-hardening pass) are committed FIRST; this plan's phases then execute on the same branch and merge to `main` when green.

**Execution order:** A → B → C → D → E with F gates after each phase. Estimated to be executed with the same 4–6 sub-agent pattern used for the stabilization pass (backend legal agent, data-layer agent, queue agent, UX agent, QA agent).
