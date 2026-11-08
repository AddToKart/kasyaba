# KASYABA — Policy ↔ Code Verification Matrix

> **Scope:** Phase A backend legal copy (`/privacy`, `/terms`, `/account-deletion`) and the compliance evidence package required by `plan-offline-compliance.md` (§1 architecture contract, §2 compliance baseline, §4 D1–D6).
>
> **Canonical policy source (D1):** `kasyaba-backend/src/modules/legal/routes.ts`.
>
> **Last updated:** 2026-11-06 · **Policy version:** 2.0 · **Status:** Phase A–E claims re-verified against code. Backend request-log IP redaction and the daily session-prune job are implemented. Remaining gaps are listed in §8.
>
> **Status legend**
> - **pre-existing** — implementation and/or test exists in the repository today.
> - **to be added** — required by the plan but not yet implemented or not yet asserted by a test.
> - **process** — operational/legal control; verified by runbook, not code.
> - **deployment** — configuration-dependent; verify on the deployed environment.

---

## 1. Claim → code → test matrix

Paths are relative to the repository root. “Current test” means the test name as it exists in the repository on 2026-11-06.

| # | Public policy claim | Code evidence | Current test evidence | Status |
|---|---|---|---|---|
| 1 | KASYABA is **online-first**; the server is the source of truth, with on-device math for instant feedback. | `kasyaba-backend/src/modules/legal/routes.ts` (`/privacy` Architecture Summary and §3; `/terms` §1, §4) | `kasyaba-backend/src/modules/legal/routes.test.ts` → `states every required online-first and security claim on /privacy` (asserts `online-first`, server-run/device-run claims) and `contains no retired or unverified claims on any legal page` (banned `local-first`, `100% on-device`, etc.). | pre-existing copy; **implemented** test |
| 2 | Accounts/wallets, posted and planned transactions, bills + templates + generated instances, budgets, goals + contributions, snapshots, and alerts are stored on the server in PostgreSQL. | `prisma/schema.prisma` (`User`, `AuthSession`, `FinancialAccount`, `IncomeEntry`, `ExpenseEntry`, `AccountTransfer`, `Budget`, `SavingsGoal`, `SavingsContribution`, `BillTemplate`, `BillInstance`, `FinancialSnapshot`, `FinancialAlert`); services under `src/modules/{accounts,transactions,income,expenses,bills,budgets,goals,forecasting}`. | `src/modules/bills/service.test.ts` → `generateBillInstances`; `src/modules/auth/service.test.ts` → `restoreUserData` and `exportUserData`; `src/modules/auth/auth.e2e.test.ts` → export/restore tests. | pre-existing |
| 3 | Passwords are salted and hashed with **Argon2id**; cleartext passwords are never stored. | `src/modules/auth/service.ts` → `argon2.hash` in `registerUser` (:74), `resetPassword` (:949), `changePassword` (:993); `argon2.verify` in `loginUser` (:98, :328). | `src/modules/auth/auth.e2e.test.ts` → `POST /api/v1/auth/register > successfully registers a user with valid credentials` and login tests. No assertion that the stored value is an Argon2id hash. | pre-existing behavior; **to be added** hash-format assertion |
| 4 | Refresh tokens are stored only as **SHA-256 hashes**; cleartext refresh tokens are never persisted on the server. | `src/modules/auth/service.ts` → `hashToken` (:26–28), `createSession` (:811–832), `refreshSession` (:194–230), `logoutUser` (:232–242); `prisma/schema.prisma` → `AuthSession.refreshTokenHash`. | `src/modules/auth/auth.e2e.test.ts` → `Token Refresh & Session Revocation > successfully refreshes token with valid refresh token`; `> successfully logs out and revokes refresh token`. Behavioral only; no DB-hash assertion. | pre-existing behavior; **to be added** hash assertion |
| 5 | IP addresses are used **only for rate limiting**. | `src/app.ts` → `express-rate-limit` for `/health` (:80–89) and `/api/v1` (:90–99); `src/modules/auth/routes.ts` → login/register/refresh limiters (:24–69); `src/app.ts` → `trust proxy` handling (:23–31). Request logs use `requestLogSerializer` (:127–139), which omits `remoteAddress`; the IP is never persisted or hashed. | `src/app.test.ts` → `pino request serializer (privacy) > never emits the client IP address`; `src/modules/legal/routes.test.ts` → `states every required online-first and security claim on /privacy` asserts the “only for rate limiting” wording. | **implemented** (log redaction) |
| 6 | The **30-day planning horizon and pressure levels** are server-run. | `src/modules/planning/service.ts` → `defaultDateRange` adds 30 days (:144–148); `pressureFor` returns `clear` / `watch` / `risk` (:66–70); `calculatePlanningOverview` (:72–142); route `GET /api/v1/planning/overview` in `src/modules/planning/routes.ts`. | `src/modules/planning/service.test.ts` → `calculatePlanningOverview > calculates a transparent daily allowance from scheduled commitments`; `> never reports a positive allowance when the buffer is negative`; `buildPlanningEvents (R1 regression tests)` clamp tests. | pre-existing |
| 7 | The **financial health score and grade** are server-run. | `src/modules/forecasting/service.ts` → `computeHealthScore` (:876–936); grades `Excellent` / `Good` / `Fair` / `Needs Attention`; persisted in `FinancialSnapshot.healthScore` and `healthGrade`. | `src/modules/forecasting/health-score.test.ts` → `Financial Health Score > savings rate 20%+ gives max savings score`, `> returns Excellent grade for strong finances`, `> returns Needs Attention for poor finances`, and related cases. | pre-existing |
| 8 | **Month-to-date and predicted month-end** figures are server-run. | `src/modules/forecasting/service.ts` → `computeSnapshot` (:25–325), `projectedMonthEndIncome`, `projectedMonthEndExpenses`, `predictedMonthEndBalance`; `FinancialSnapshot` model. | `src/modules/forecasting/forecast.test.ts` → `Forecasting Onboarding Stability & Confidence (F7) > computeProjectedIncome > uses weighted 3-month average when 3 or more history months exist`; `> uses salaryAmount as baseline for month 1 onboarding when no history exists`; `computeDataConfidence` tests. | pre-existing |
| 9 | The **daily snapshot job runs at 00:10 Asia/Manila**. | `src/config/env.ts` → `SNAPSHOT_CRON` default `'10 0 * * *'` (:30) and `WORKER_TIMEZONE` default `'Asia/Manila'` (:29); `src/worker.ts` → `cron.schedule(env.SNAPSHOT_CRON, ..., { timezone: env.WORKER_TIMEZONE })` (:210–215), `runSnapshotJob` (:89–122). | No worker/cron test. | pre-existing implementation; **to be added** worker test |
| 10 | **Hourly bill-instance generation up to two months ahead** and **overdue flips** are server-run. | `src/worker.ts` → hourly cron `'0 * * * *'` (:219–224); `src/modules/bills/service.ts` → `generateBillInstances(userId, monthsAhead = 2)` (:349–431), `updateOverdueBills` (:433–465). | `src/modules/bills/service.test.ts` → `generateBillInstances > keeps a 31st monthly anchor without permanent drift`; `> anchors weekly occurrences to the startsOn weekday and skips past weeks`; `> stops generating recurring instances after endsOn`. No `updateOverdueBills` test; no worker-schedule test. | pre-existing service; **to be added** overdue + worker tests |
| 11 | **Daily safe-to-spend, including excluded wallets**, is device-run. | `kasyaba-app/lib/core/utils/deterministic_math.dart` → `calculateDailySafeSpend` and `adjustedLiquidBalance` (:402–420); `kasyaba-app/lib/core/providers/preference_providers.dart` → `excludedAccountsProvider` / `excluded_safe_spend_accounts` in secure storage. | `test/unit/deterministic_math_test.dart` → `calculateDailySafeSpend > excludes cancelled unpaid bills from safe spend`; `> clamps negative numerator to 0 daily safe spend`; `adjustedLiquidBalance > sums only the non-excluded accounts`; `> falls back to dashboard total when nothing is excluded`. | pre-existing |
| 12 | **Payday countdown for all supported schedules** is device-run. | `deterministic_math.dart` → `computeNextPayday`; schedules include semi-monthly, weekly, bi-weekly, and custom day strings. | `test/unit/deterministic_math_test.dart` → `computeNextPayday > handles February correctly for 30th schedule (clamps to 28)`; `> supports bi-weekly frequency`; `> supports weekly frequency`; `> parses a custom single-day schedule`. | pre-existing |
| 13 | **PH statutory deductions (SSS, PhilHealth, Pag-IBIG, income tax)** are device-run. | `kasyaba-app/lib/core/utils/ph_salary_calculator.dart` → `PhSalaryCalculator` / `PhSalaryBreakdown`. | `test/unit/ph_salary_calculator_test.dart` → `PhSalaryCalculator Statutory Deductions > calculates standard salary ₱30,000 with bracket 2 tax`; `> calculates professional salary ₱45,000 + ₱3,000 non-taxable allowances with bracket 3 tax`; `> respects PhilHealth salary ceiling of ₱100,000`. | pre-existing |
| 14 | The **interactive affordability simulator math** (cash vs installment, interest/amortization, cash preserved, work-hours) is device-run. | `deterministic_math.dart` → `WorkHoursEquivalent`, `InstallmentComparison`, `calculateWorkHoursEquivalent`, `calculateInstallmentComparison`. | `test/unit/deterministic_math_test.dart` → `calculateWorkHoursEquivalent > calculates work-hours and workdays accurately for monthly salary`; `calculateInstallmentComparison > calculates 0% BNPL installment correctly`; `> calculates interest-bearing BNPL installment correctly`. | pre-existing |
| 15 | **Allocation proportions and goal progress** are device-run. | `deterministic_math.dart` → `goalMonthlyNeed` (:153–175), `GoalContributionDetail`; dashboard/savings widgets consume these values. | `test/unit/deterministic_math_test.dart` → `goalMonthlyNeed > prefers the server monthly requirement`; `> uses the target date when provided`; `> returns zero when the goal is already funded`. | pre-existing |
| 16 | The **final affordability verdict / cash-after-bills / earliest safe buy date** are server-computed at `/forecasting/purchase-check`. | `src/modules/dashboard/routes.ts` → `POST /api/v1/forecasting/purchase-check` (:37–46); `src/modules/forecasting/purchase-check.ts` → `cashAfterBills` (:65), `earliestSafeBuyDate` (:111–122), response fields (:163–165). | `src/modules/forecasting/purchase-check.test.ts` → `verdict is AFFORDABLE when balance, bills, and threshold are safely met`; `verdict is NOT_RECOMMENDED when purchase prevents covering upcoming bills`; `calculates savings goal delay accurately`. | pre-existing |
| 17 | Authentication tokens and app preferences (theme, notification preferences, excluded accounts) are kept in **encrypted secure storage**. | `kasyaba-app/lib/core/storage/secure_storage_service.dart` (tokens; `FlutterSecureStorage`); `lib/core/providers/preference_providers.dart` (excluded accounts); `lib/core/notifications/notification_preferences.dart` (notification prefs); `lib/core/providers/theme_provider.dart` (theme). | `test/unit/notification_preferences_test.dart` → `hydrates persisted values`, `persists updates`, `toggles and persists account exclusions`; `test/unit/session_reset_test.dart` → logout clears `access_token`. Encryption is provided by the OS keystore; no automated assertion of keystore backing. | pre-existing behavior; **to be added** storage-backend assertion |
| 18 | The device keeps a **plaintext snapshot cache** of dashboard, wallets, recent transactions, bills, goals, budgets, alerts, and categories in Drift/SQLite. | `kasyaba-app/lib/core/database/database.dart` → `CachedSnapshots` table keyed by `{userId, key}` (schema v4; legacy `cached_dashboard` row migrated); `cache_service.dart` → `putSnapshot`/`getSnapshot`/`deleteSnapshotsFor`/`deleteAllForUser` plus transaction-view pruning; `api_providers.dart` → write-through and snapshot fallback for dashboard, accounts, categories, bills, goals, alerts, budgets, and paginated transactions. No SQLCipher; plaintext as disclosed. | `kasyaba-app/test/unit/offline_cache_test.dart` → `CacheService snapshot store > putSnapshot/getSnapshot round-trips json and fetchedAt`; `> snapshots are isolated per user`; `> transaction snapshots prune to the 10 newest views only`; `provider snapshot fallbacks > dashboard failure serves snapshot with pending overlay`; `schema migration v3 -> v4 > migrates the legacy dashboard row and preserves queued rows`. | **implemented** (Phase B) |
| 19 | The **offline queue** captures expense/income/transfer/goal-deposit entries; replays when connectivity returns; retry cap 5; failed entries are surfaced in-app. | `cache_service.dart` → `queueTransaction` (:119–139), `syncPendingTransactions` (:177–254; `goal_contribution` posts to `/goals/:goalId/contributions` at :211–222), `recordRetry` caps at 5 (:291–307); `offline_sync_service.dart` replays on connectivity/auth changes; `api_providers.dart` → `addExpense`/`addIncome`/`addTransfer`/`addGoalContribution` queue on connection errors. | `kasyaba-app/test/unit/offline_capture_test.dart` → `offline expense capture > queues a non-UUID category offline and replays the resolved UUID`; `offline goal contributions > queues, replays once with the same clientMutationId, and ignores the already-synced row on a second replay`; `offline replay refresh > a successful replay invalidates the full finance provider set`. Retry-cap behavior still has no test. | **implemented** (Phase C); retry-cap test **open** |
| 20 | Signing out clears read caches and tokens but **retains the offline queue** (D4). | `kasyaba-app/lib/core/providers/session_refresh_provider.dart` → `sessionDataResetProvider` calls `deleteSnapshotsFor(prev)` when `userId` becomes null (:39–46); `cache_service.dart` → `deleteSnapshotsFor` deletes only `cached_snapshots` (:77–81), leaving `offline_transactions`; `auth_provider.dart` → `logout` clears tokens (:463–480). | `test/unit/offline_cache_test.dart` → `sign-out clears snapshots but keeps the offline queue`; `CacheService snapshot store > deleteSnapshotsFor keeps the queue; deleteAllForUser clears both`; `test/unit/session_reset_test.dart` provider-reset tests. | **implemented** (Phase B-4) |
| 21 | Deleting the account wipes device tokens, caches, and the offline queue. | `kasyaba-app/lib/features/settings/screens/delete_account_screen.dart` → after a successful `deleteAccount`, `cacheService.deleteAllForUser(userId)` wipes snapshots and queue (:51–63); `auth_provider.dart` → `deleteAccount` clears tokens after server confirmation (:418–461); `cache_service.dart` → `deleteAllForUser` (:83–91). | `src/modules/auth/service.test.ts` → `deleteAccount > cascades deletion across user records within a transaction`; `src/modules/auth/auth.e2e.test.ts` → `Google Play Mandated Account Deletion & Export > successfully deletes account on DELETE /api/v1/auth/me`; `test/unit/offline_cache_test.dart` → `deleteSnapshotsFor keeps the queue; deleteAllForUser clears both`. Widget coverage asserts the delete screen UI, not the wipe call. | **implemented** (Phase E-5) |
| 22 | Export: **JSON = full account snapshot; CSV = transaction history only.** | `src/modules/auth/service.ts` → `exportUserData` (:358–399) returns user + all collections; `kasyaba-app/lib/core/utils/data_export_helper.dart` → `DataExportHelper` CSV generation; `lib/features/settings/widgets/data_backup_sheets.dart` → JSON export and paginated CSV export. | `test/unit/data_export_helper_test.dart` → `DataExportHelper - CSV Generation > generates valid RFC 4180 CSV with escaped fields and signed amounts`; `DataExportHelper - JSON Schema Validation > validates full Kasyaba envelope backup successfully`; `test/widget/qa_csv_pagination_test.dart` → `CSV export pages /transactions at 100 rows and exports all 150 rows`; `src/modules/auth/service.test.ts` → `exportUserData > exports all financial records without passwordHash`. | pre-existing |
| 23 | Account deletion is available **in-app** and through the **web portal** at `/account-deletion`. | `src/modules/legal/routes.ts` (`/account-deletion`); `src/modules/auth/routes.ts` (`DELETE /api/v1/auth/me`); `kasyaba-app/lib/features/settings/screens/delete_account_screen.dart`; `auth_provider.dart` → `deleteAccount`. | `src/modules/auth/auth.e2e.test.ts` → `Public Legal & Health Check Routes > serves Account Deletion instructions at /account-deletion`; `Google Play Mandated Account Deletion & Export > successfully deletes account on DELETE /api/v1/auth/me`. | pre-existing |
| 24 | **No Google sign-in claim** appears in the shipped policies. | `legal/routes.ts` contains no Google sign-in copy. The backend still exposes a dormant `/api/v1/auth/google` route (`auth/routes.ts`, `auth/service.ts`), which is not described as an offered feature (plan §8 keeps it dormant/out of scope). | `src/modules/legal/routes.test.ts` → `contains no retired or unverified claims on any legal page` (banned list includes `Google Sign-In`). | pre-existing copy; **implemented** test |
| 25 | Data is **encrypted in transit using HTTPS/TLS**; no protocol or at-rest specifics are claimed. | Deployment/TLS termination configuration; code uses standard HTTPS clients. `legal/routes.ts` §5 says only “encrypted in transit using HTTPS/TLS”. | No automated test; deployment check in Phase E/F. | **deployment** (D6) |
| 26 | RA 10173 rights: informed, access, rectify, erase, portability. | Informed: `/privacy`; access/portability: `exportUserData` and app export; rectify: `updateProfile` in `auth/service.ts` and profile editing UI; erase: `deleteAccount` and `/account-deletion`. | `auth.e2e.test.ts` export/delete tests; `src/modules/auth/service.test.ts` export/delete tests. Right-to-rectify has no dedicated policy test. | pre-existing partial; **to be added** copy/rights test |
| 27 | Records are retained while the account is active; expired sessions are pruned. | `src/modules/auth/service.ts` → `refreshSession` rejects sessions with `expiresAt <= now` (:200–230) and `logoutUser` sets `revokedAt` (:232–242); `prisma/schema.prisma` → `AuthSession.expiresAt` / `revokedAt`. `src/modules/auth/session-prune.ts` → `pruneExpiredSessions` deletes `expiresAt < now` OR `revokedAt < now - 30 days` via batched `deleteMany`; `src/worker.ts` → `runSessionPruneJob` (:157–182) with `JobRun` bookkeeping and daily cron `30 3 * * *` in `WORKER_TIMEZONE` (:228–234). | `src/modules/auth/session-prune.test.ts` → `deletes expired and long-revoked sessions in one batch`; `keeps fetching while a full batch is returned`; `is a no-op when nothing matches`; `propagates delete failures...`; `uses a 30-day revocation retention window`. Worker cron wiring is exercised by typecheck, not a process-level test. | **implemented**; worker wiring test **open** |
| 28 | Breach notification: notify the **NPC and affected users within 72 hours** of discovery of a qualifying breach. | Process control; no code path. | No test. | **process**; **to be added** runbook/templates |
| 29 | Zero AI, no third-party trackers, no selling/brokering of data. | Backend `package.json` has no AI/analytics SDK; app `pubspec.yaml` has no analytics/AI SDK; `legal/routes.ts` §6 and Core Commitments. | No dependency-audit/CI test. | pre-existing code absence; **to be added** CI grep/dependency audit |
| 30 | Children’s privacy: not directed to under-13s; no knowing collection from minors. | Policy copy only; no age gate in registration code. | No test. | **process**; **to be added** age-gate decision |
| 31 | Support/privacy contact is served from `env.SUPPORT_EMAIL`. | `src/config/env.ts` → `SUPPORT_EMAIL` (:24); `legal/routes.ts` → `escapeHtml(env.SUPPORT_EMAIL)` in all three pages. | No direct assertion; the legal suite checks claim/footer copy only. | pre-existing implementation; **to be added** render assertion |
| 32 | All three pages show **Last updated: November 6, 2026**; `/privacy` includes a versioned changelog. | `legal/routes.ts` (updated lines and §11). | No date assertion yet; legal suite covers the required architecture/security claims. | pre-existing copy; **to be added** date assertion |
| 33 | `/privacy` includes a short **Architecture Summary** describing what runs where. | `legal/routes.ts` → `/privacy` Architecture Summary list and §3. | `src/modules/legal/routes.test.ts` asserts the server-run/device-run claims and the `online-first` headline, but not the “Architecture Summary” heading itself. | pre-existing copy; substantially covered |
| 34 | Android builds **target API 36** for Play submission and **exclude app data from cloud backup/device transfer**. | `kasyaba-app/android/app/build.gradle.kts` → `compileSdk = 36`, `targetSdk = 36`; `AndroidManifest.xml` → `allowBackup="false"`, `fullBackupContent="@xml/backup_rules"`, `dataExtractionRules="@xml/data_extraction_rules"`; `res/xml/backup_rules.xml`; `res/xml/data_extraction_rules.xml`. | No automated Gradle/manifest assertion; `.github/workflows/app-ci.yml` builds the APK. Install → backup → restore verification is open (§8). | **implemented** (Phase E-6); device verification **open** |

---

## 2. Google Play Data Safety mapping

Play Console must match this table. “Shared” means transfer to a third party for a business purpose; infrastructure processors acting on our instructions are disclosed as service providers, not as data sharing for advertising.

| Data type | Collected? | Purpose | Stored where | Shared with third parties? | Deletable? | Encrypted in transit? |
|---|---|---|---|---|---|---|
| **Email address** | Yes — account registration/sign-in | Account identity, authentication, support, deletion requests | PostgreSQL `users.email`; device secure storage caches the signed-in identity | **No** | **Yes** — account deletion | **Yes** — HTTPS/TLS |
| **Display name** | Yes — optional profile field | Personalization and account identity | PostgreSQL `users.displayName`; device secure storage caches the signed-in identity | **No** | **Yes** — account deletion | **Yes** — HTTPS/TLS |
| **Password** | Yes — authentication credential; stored only as a salted **Argon2id hash** | Authentication and credential verification | PostgreSQL `users.passwordHash` (no cleartext) | **No** | **Yes** — account deletion | **Yes** — HTTPS/TLS |
| **Financial info** (wallets, transactions, bills, budgets, goals, contributions, snapshots, alerts) | Yes — core app functionality | Budgeting, ledger synchronization, server planning/health/forecast, bill generation | PostgreSQL (authoritative); plaintext Drift/SQLite snapshot cache and offline queue on device | **No** | **Yes** — account deletion (server rows deleted; device caches/queue wiped) | **Yes** — HTTPS/TLS |
| **IP address** | Yes — transient request metadata | Rate limiting and abuse prevention only | Transient in-memory rate-limit state; request logs omit `remoteAddress` (`src/app.ts` `requestLogSerializer`) | **No** | **Yes** — account-linked data deleted; transient rate-limit state expires | **Yes** — HTTPS/TLS |
| **Hashed refresh tokens** | Yes — session management; stored only as **SHA-256 hashes** | Keep sessions authenticated and rotate/revoke them | PostgreSQL `auth_sessions.refreshTokenHash` (no cleartext) | **No** | **Yes** — account deletion / session revocation | **Yes** — HTTPS/TLS |

**Play Console notes**

- Declare **no** advertising, analytics, or data-broker sharing. The app has no third-party analytics SDK and no AI integration.
- Do **not** declare location, contacts, photos, health, messages, or browsing history; they are not collected.
- The account-deletion URL in Play Console must be the deployed `/account-deletion` page; the privacy URL must be the deployed `/privacy` page (D1).
- IP is not a user-facing profile field; it is transient rate-limit metadata. Request logs redact it, so the “only for rate limiting” wording is accurate.

---

## 3. Retention & deletion matrix

| Data class | Where stored | While account active | On sign-out | On account deletion | Evidence / status |
|---|---|---|---|---|---|
| User profile (email, display name, Argon2id hash) | PostgreSQL `users` | Retained | Unchanged | Deleted in `deleteAccount` transaction | `auth/service.ts` `deleteAccount`; pre-existing test |
| Ledger (accounts/wallets, income, expenses, transfers, categories, budgets, goals, contributions) | PostgreSQL | Retained | Unchanged | Explicit FK-safe `deleteMany` cascade | `auth/service.ts` `deleteAccount`; `auth/service.test.ts` cascade test; pre-existing |
| Bills (templates + generated instances) | PostgreSQL | Retained; instances generated hourly up to 2 months ahead | Unchanged | Deleted | `deleteAccount`; `bills/service.ts`; pre-existing |
| Snapshots and alerts | PostgreSQL | Retained; daily snapshot job appends | Unchanged | Deleted | `deleteAccount`; `forecasting/service.ts`; pre-existing |
| Sessions / refresh-token hashes | PostgreSQL `auth_sessions` | Retained until expiry or revocation; expired rows and rows revoked more than 30 days are pruned daily at 03:30 `WORKER_TIMEZONE` | Token cleared locally; server row remains if the logout call did not reach the server, and is pruned after expiry | All rows deleted | `auth/service.ts`; `auth/session-prune.ts`; `worker.ts`; `session-prune.test.ts` |
| Password-reset OTPs | PostgreSQL `password_reset_otps` | 10-minute expiry; `usedAt` marks consumption | Unchanged | Deleted by cascade | `auth/service.ts`; **to be added** expired-OTP cleanup job |
| Authentication tokens (access/refresh) | Device encrypted secure storage | Present while signed in | Cleared | Wiped | `secure_storage_service.dart`; `auth_provider.dart`; pre-existing |
| Cached signed-in identity (user id/email/display name) | Device encrypted secure storage | Present while signed in | Cleared with tokens | Wiped | `secure_storage_service.dart`; pre-existing |
| App preferences (theme, notification prefs, excluded accounts) | Device encrypted secure storage | Present | **Retained** (not cleared by sign-out) | Not explicitly wiped today; decide in Phase E (policy only promises tokens/caches/queue) | `preference_providers.dart`, `notification_preferences.dart`, `theme_provider.dart`; **open decision** |
| Read caches (dashboard, wallets, recent transactions, bills, goals, budgets, alerts, categories) | Device plaintext Drift/SQLite `cached_snapshots` (v4) | Present / refreshed on read | **Cleared** per D4 via `deleteSnapshotsFor` | Wiped via `deleteAllForUser` | `database.dart`; `cache_service.dart`; `session_refresh_provider.dart`; `offline_cache_test.dart` |
| Offline queue (expense/income/transfer/goal deposit) | Device plaintext Drift/SQLite | Present until synced or failed (retry cap 5) | **Retained** per D4; re-attached by `userId` on next sign-in | Wiped via `deleteAllForUser`; unsynced entries are lost by design | `cache_service.dart`; `api_providers.dart`; `offline_capture_test.dart`; `offline_cache_test.dart` |
| Android cloud backup copies | Device/OS backup | Excluded from cloud backup and device transfer | N/A | Not restorable through backup | `AndroidManifest.xml` (`allowBackup="false"`, `fullBackupContent`, `dataExtractionRules`); `backup_rules.xml`; `data_extraction_rules.xml`; install→backup→restore verification **open** |

**Deletion semantics**

- In-app deletion is the immediate path: server deletion, token clear, and device snapshot/queue wipe (`deleteAllForUser`).
- Web-portal deletion cannot reach a powered-off device. On the next sign-out/session reset the app clears read snapshots, but the offline queue is retained by design; the policy sentence about clearing “local data” after web-portal deletion should be read with that D4 exception or reworded. Tracked in §8.
- Deleting an account discards unsynced offline entries; the policy and the deletion portal tell the user to sync/export first.
- The policy promises no separate ledger archive after deletion, with a qualified statement about infrastructure backups. Legal should confirm the hosting provider’s actual backup retention cycle before publication.

---

## 4. Android backup posture

**Implemented state (2026-11-06)**

- `kasyaba-app/android/app/src/main/AndroidManifest.xml` declares `android:allowBackup="false"`, `android:fullBackupContent="@xml/backup_rules"`, and `android:dataExtractionRules="@xml/data_extraction_rules"`.
- `kasyaba-app/android/app/src/main/res/xml/backup_rules.xml` (API ≤ 30) and `data_extraction_rules.xml` (API 31+) exclude the root, file, database, sharedpref, external, and device-transfer domains.
- `kasyaba-app/android/app/build.gradle.kts` pins `compileSdk = 36` and `targetSdk = 36` for the Play target-API requirement; `minSdk` remains Flutter’s supported floor (24).
- Drift stores the plaintext database under the app’s databases directory; `flutter_secure_storage` uses Android shared preferences backed by the Keystore. The backup exclusions keep both the plaintext cache/queue and the Keystore-backed preferences out of cloud backup and device-to-device transfer.

**Remaining verification**

- Run the install → backup → restore cycle on a test device (or Play pre-launch report) and record that neither the cache nor secure-storage preferences are restored. This is device-level verification; the code/config control is present.

**Policy alignment**

`/privacy` §4 already discloses that the device snapshot cache and queue are plaintext. Excluding them from cloud backup is defense-in-depth and does not change the disclosure.

---

## 5. TLS / at-rest position (D6, softened)

**Shipped wording**

- “Data is encrypted in transit using HTTPS/TLS.”
- No TLS version and no at-rest encryption claim.

**Verified in code**

- Passwords: Argon2id (`auth/service.ts`).
- Refresh tokens: SHA-256 hashes only (`auth/service.ts`).
- HTTPS/TLS is a deployment property; verify TLS termination and HSTS on the VPS/reverse proxy.

**Not claimed / not verified**

- Exact TLS protocol version (do not restore “TLS 1.3” until enforced and verified).
- PostgreSQL disk/volume encryption (do not restore “AES-256 at rest” until verified).
- Backup encryption.

**Follow-up (non-blocking per D6)**

Record the deployed TLS policy and Postgres volume-encryption result in this document only when evidence exists. If both are verified, the wording may be upgraded deliberately; otherwise keep the softened statement.

---

## 6. RA 10173 / NPC thesis appendix checklist

Use this as the compliance appendix checklist. `[x]` = present today; `[ ]` = pending.

### 6.1 Lawful basis and consent

- [x] Registration requires acceptance of Terms/Privacy (existing checkbox; verify copy after Phase A-4).
- [x] Privacy notice is hosted at `/privacy` and linked from the app.
- [ ] Confirm the registration checkbox wording says online-first and links the hosted policy (Phase A-3/A-4).
- [ ] Record consent version/timestamp if the product needs demonstrable consent (currently no dedicated consent ledger).

### 6.2 Data-subject rights

- [x] Right to be informed — `/privacy`, `/terms`.
- [x] Right to access / portability — JSON full account snapshot (`/api/v1/auth/export`; app export).
- [x] Right to rectify — profile/salary/payday editing (`updateProfile`; profile UI).
- [x] Right to erase — in-app deletion + `/account-deletion` portal.
- [x] Right to object/withdraw — account deletion and sign-out.
- [ ] Add a policy test asserting all five rights are named (Phase A-5).

### 6.3 Breach response

- [ ] Written incident runbook: detection, containment, assessment, 72-hour NPC notification, affected-user notification, evidence log.
- [ ] NPC notification template and user-notification template.
- [ ] Named incident owner / Data Protection Officer contact (support email is the current public contact).
- [ ] Tabletop exercise before production launch.

### 6.4 DPIA-lite considerations

- [ ] Data inventory (this matrix + Play Data Safety table).
- [ ] Necessity/proportionality: email, display name, financial records, hashed credentials, IP-for-rate-limiting; no advertising identifiers.
- [ ] Risk register: plaintext device cache/queue, offline queue on shared devices, request-log IP redaction, dormant Google route, backup copies, lost/stolen device.
- [ ] Retention schedule: active-account retention, session expiry, OTP expiry, device-cache clearing on sign-out, deletion wipe.
- [ ] Processor register: hosting/VPS, PostgreSQL, email delivery (Resend), any backup provider.
- [ ] Security controls: Argon2id, SHA-256 token hashes, HTTPS/TLS, rate limiting, least-privilege DB access.
- [ ] Review cadence: re-run this matrix when policy copy, data flows, or infrastructure changes.

### 6.5 NPC / governance

- [ ] Determine whether KASYABA is a Personal Information Controller and whether NPC registration applies.
- [ ] Document the DPO or privacy contact and the request-handling SLA (email deletion currently says within 30 days).
- [ ] Keep the policy version/changelog and this matrix under review (D1 single source).
- [x] Banned-phrase gate: `src/modules/legal/routes.test.ts` (backend-rendered HTML) and `kasyaba-app/test/unit/policy_copy_test.dart` (in-app copy) run in the backend/app CI workflows.

---

## 7. Verification commands

### 7.1 Backend gates

```powershell
cd kasyaba-backend
npm run typecheck
npm test
```

Expected baseline on 2026-11-06: typecheck clean; **24 test files, 188 tests passed** (includes `src/modules/legal/routes.test.ts`, `src/app.test.ts`, and `src/modules/auth/session-prune.test.ts`).

Focused legal-render test:

```powershell
cd kasyaba-backend
npx vitest run src/modules/auth/auth.e2e.test.ts -t "Public Legal"
```

### 7.2 Deployed-page smoke test (PowerShell)

```powershell
$base = "https://your-api-host.example"
foreach ($path in @("/privacy", "/terms", "/account-deletion")) {
  $res = Invoke-WebRequest -Uri "$base$path" -UseBasicParsing
  "{0} -> {1} ({2} bytes)" -f $path, $res.StatusCode, $res.RawContentLength
}
```

### 7.3 Deployed-page smoke test (bash/curl)

```bash
BASE="https://your-api-host.example"
for page in privacy terms account-deletion; do
  curl -fsS "$BASE/$page" -o "/tmp/$page.html"
  printf '%s -> %s bytes\n' "$page" "$(wc -c < "/tmp/$page.html")"
done
```

### 7.4 Banned-phrase gate on deployed HTML

```bash
BASE="https://your-api-host.example"
PATTERN='TLS 1\.3|AES-256|Google Sign-In|local-first|entire database|100% on-device|Every calculation runs|fully functional offline|standard JSON or CSV'
for page in privacy terms account-deletion; do
  if curl -fsS "$BASE/$page" | grep -Eiq "$PATTERN"; then
    echo "FAIL: banned phrase found on /$page"
  else
    echo "PASS: /$page"
  fi
done
```

### 7.5 Required-claim assertions on deployed HTML

```bash
BASE="https://your-api-host.example"
curl -fsS "$BASE/privacy" | grep -q "00:10 Asia/Manila"      && echo "OK snapshot time"
curl -fsS "$BASE/privacy" | grep -q "Argon2id"               && echo "OK Argon2id"
curl -fsS "$BASE/privacy" | grep -q "SHA-256"                && echo "OK refresh hashing"
curl -fsS "$BASE/privacy" | grep -q "72 hours"               && echo "OK breach notice"
curl -fsS "$BASE/terms"   | grep -q "online-only"            && echo "OK online-only terms"
curl -fsS "$BASE/account-deletion" | grep -q "full account snapshot" && echo "OK export scope"
```

### 7.6 Local source grep (before deploy)

```powershell
rg -n -i "TLS 1\.3|AES-256|Google Sign-In|local-first|entire database|100% on-device|Every calculation runs|fully functional offline|standard JSON or CSV" kasyaba-backend/src/modules/legal/routes.ts
```

A clean result means no banned phrase was found. The only acceptable “Google” reference in the backend source is the non-policy comment/context around Google Play requirements; it must not appear in the rendered pages.

---

## 8. Open items for the coordinator

Resolved on 2026-11-06:

- Request-log IP redaction (§1 row 5; `src/app.ts`, `src/app.test.ts`).
- Daily session pruning (§1 row 27; `src/modules/auth/session-prune.ts`, `src/worker.ts`).
- Phase B–E device claims verified in app code: unified snapshot keys, goal-deposit offline queue, sign-out snapshot clearing, in-app deletion wipe, Android backup exclusion, and `targetSdk 36` (§1 rows 18–21, §3, §4).
- Backend legal copy regression test and banned-phrase gate (§1 rows 1, 5, 24).

Remaining gaps and follow-ups:

1. **Web-portal deletion vs. the retained offline queue.** In-app deletion wipes snapshots and queue (`deleteAllForUser`). A web-portal deletion on a powered-off device clears read snapshots on the next sign-out/session reset, but D4 intentionally retains the offline queue, so `/privacy` §4’s “clears local data” sentence is broader than the code. Either add an “account no longer exists” flow that also wipes the queue, or reword the policy to say snapshots clear and the queue follows the D4 retention rule.
2. **Password-reset OTP rows are not pruned.** `password_reset_otps` expires logically after 10 minutes, but no job deletes expired/used rows. Extend the session-prune job or add an OTP prune step.
3. **Offline retry-cap test.** `recordRetry` caps at 5 and sets `failedAt`, but no unit test asserts the cap. Add a test alongside `offline_capture_test.dart`.
4. **Worker cron process-level test.** The prune predicate is unit-tested, but `src/worker.ts` remains a process entrypoint; cron registration/bookkeeping is not exercised by an automated test. Verify on staging (job row + deleted count) or extract worker wiring behind an importable bootstrap.
5. **Device backup verification.** Manifest and XML rules are present; the install → backup → restore cycle on a test device (or Play pre-launch report) has not been recorded.
6. **At-rest encryption remains unverified and unclaimed.** Keep the D6 wording; do not restore protocol/at-rest specifics until deployment evidence exists.
7. **Dormant Google auth route.** `/api/v1/auth/google` still exists in the backend but is not offered in the app or described in the policy. Decide whether to keep it dormant (plan §8) or remove the route to reduce DPIA surface.
8. **Backup wording.** The policy says no separate ledger archive, with a qualified infrastructure-backup statement. Legal should confirm the hosting provider’s actual backup retention cycle.
9. **Email deletion SLA.** `/account-deletion` promises processing within 30 days. Confirm support capacity and identity-verification steps.
10. **Play Data Safety form.** Re-check the Console form against §2 after deployment; the privacy URL must serve the rewritten `/privacy`.
11. **Remaining policy assertions.** The new tests cover the headline claims and banned phrases but not: stored Argon2id hash format, SHA-256-only refresh-token persistence in the DB, the “Last updated” date, support-email rendering, and all five RA 10173 rights being named.
12. **Email-delivery logs include the recipient address.** `src/lib/email.ts` logs `to` on send success/failure. This is operational PII (not financial data); decide whether to mask it or document log retention.

---

## Policy hardening update — v2.1 (2026-11-06, late)

| Policy statement (added) | Implementation evidence |
|---|---|
| Developer identity: "KASYABA is developed and operated by Jelo Abihay" (privacy intro + §10) | `legal/routes.ts` intro + Contact section; must match the Play developer account |
| Not-a-lender scope: "not a bank, financial institution, or lender; does not facilitate money transfers, credit issuance, or loan disbursements" | `legal/routes.ts` intro; prevents Finance-category misclassification against the BNPL/loans scanner |
| Offline queue is account-tagged: "tagged to your unique account ID; only re-attached if the same account signs back in; never shown to a different account" | `kasyaba-app/lib/core/database/cache_service.dart` (`queueTransaction` stores userId; `syncPendingTransactions(userId)`; `deleteAllForUser(userId)`), `database.dart` `OfflineTransactions.userId` — wording now matches code exactly |
| Backup retention bound: "automatically overwritten within 30 days" | Owner decision (30-day cycle); keep any pg_dump/snapshot job <= 30 days; privacy §Retention, terms §6, account-deletion page all state it |
| Absolute canonical URLs (https://api.kasyaba.site/privacy | terms | account-deletion) in all three pages + footer | `legal/routes.ts` (footer + deletion §7); canonical host matches `app_info.dart` defaults |
| SUPPORT_EMAIL default | jelooabihayy@gmail.com (env default, `.env.example`, prod compose) |
| Copy gate additions | `legal/routes.test.ts` now requires: "Jelo Abihay", "not a bank, financial institution, or lender", "are automatically overwritten within 30 days", absolute deletion URL; footer-link assertions upgraded to absolute URLs |
