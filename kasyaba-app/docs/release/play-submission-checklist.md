# KASYABA — Google Play Submission Checklist (Android)

> **Scope:** Android release side of Phase E in `plan-offline-compliance.md`
> (E-4 release build, E-6 Android compliance pins, E-7 reviewer access).
> **Owner:** release engineer; backend owner for the deploy gate.
> **Last updated:** 2026-11-06
> **Application ID:** `com.kasyaba.app`

This checklist is intentionally ordered. Do not start Play Console declarations
until the backend is publicly deployed and the demo account is seeded — the
privacy URL, account-deletion URL, and reviewer login are all checked during
review and a dead URL is an automatic fail.

---

## 0. Android release pins already applied (E-6)

| Setting | Pinned value | Source of truth |
|---|---|---|
| `compileSdk` | **36** (explicit) | `android/app/build.gradle.kts` |
| `targetSdk` | **36** (≥ Play minimum 35) | `android/app/build.gradle.kts` |
| `minSdk` | `flutter.minSdkVersion` = **24** | `android/app/build.gradle.kts` |
| `ndkVersion` | `flutter.ndkVersion` = **28.2.13676358** | Flutter 3.44.2 |
| Toolchain | Flutter 3.44.2 / Dart 3.12.2, AGP 9.0.1, Gradle 9.1.0 | `android/settings.gradle.kts`, wrapper |
| Kotlin incremental | **disabled** (`kotlin.incremental=false`) | `android/gradle.properties` — Windows cross-drive workaround (Pub cache on `C:`, workspace on `D:`); re-enable if they share a drive |
| Backup | `allowBackup="false"` + `fullBackupContent` + `dataExtractionRules` | `AndroidManifest.xml`, `res/xml/*` |

SDK platforms API 34/35/36/36.1 and NDK 28.2.13676358 are installed in the
current build environment. If the toolchain moves, re-verify with
`flutter build apk --debug` before changing these pins. **Never lower
`targetSdk` below 35.**

`android:enableOnBackInvokedCallback` is intentionally not added: it is not a
Play submission requirement. Flutter 3.44 handles system back through its
embedding. If predictive-back animations are desired later, add the attribute in
a dedicated change and regression-test navigation (`PopScope`, modal sheets,
`go_router` back stacks).

### Backup/exfiltration posture

`android:allowBackup="false"` is the primary control. Both rules files exclude
`root`, `file`, `database`, `sharedpref`, `external`, and the `device_*`
equivalents for **cloud backup** and **device transfer**:

- `android/app/src/main/res/xml/backup_rules.xml` — Android 11 and below.
- `android/app/src/main/res/xml/data_extraction_rules.xml` — Android 12+.

This covers `flutter_secure_storage` (EncryptedSharedPreferences under
`shared_prefs/`), the plaintext Drift cache (`files/kasyaba_cache.db`), cached
policy text, and preferences. The app remains fully functional on-device; only
backup/transfer copies are suppressed. Server data is re-fetched after sign-in.

---

## 1. BLOCKING gate — deploy the backend before review

- [ ] Backend deployed on public HTTPS (the same host the AAB points at).
- [ ] `/privacy` serves the **Phase A-1 rewrite** (online-first wording).
      It must not say "local-first", "100% on-device math", or claim
      "TLS 1.3 & AES-256 at rest" (D6 softened wording).
- [ ] `/terms` serves the rewritten terms.
- [ ] `/account-deletion` serves the web deletion portal.
- [ ] `/health` (or `/api/v1/health`) returns 200 without auth.
- [ ] `/api/v1` is reachable; login/register work from a clean install.
- [ ] Production migrations applied: `npm run db:migrate:prod`.
- [ ] Bill repair run (backend owner): `npm run db:repair-bills` — dry run first,
      then apply.
- [ ] `TRUST_PROXY`, `CORS_ALLOWED_ORIGINS`, `SUPPORT_EMAIL`, `DATABASE_URL`
      set for production. No secrets in the repo.
- [ ] Privacy and deletion URLs open in a mobile browser without login, without
      an interstitial, and without redirecting to a marketing page.

If any item above fails, **do not upload for review**. Fix the deployment first.

---

## 2. Version bump and Play App Signing (E-4)

### 2.1 Version

Current `pubspec.yaml` is `version: 0.1.0+1` and is owned by the app-code agent.
Before the submission build the owner must change it to:

```yaml
version: 0.2.0+2
```

Then:

```sh
flutter pub get
# Verify Flutter regenerated the Gradle values:
# android/local.properties -> flutter.versionName=0.2.0, flutter.versionCode=2
```

Do **not** hardcode `versionName`/`versionCode` in `build.gradle.kts`; Flutter
must keep sourcing them from `pubspec.yaml`. Every Play upload needs a new,
monotonically increasing `versionCode` (2, 3, 4, …).

### 2.2 Upload key (do this outside this phase; never commit the key)

`android/key.properties` and `**/*.jks` are already gitignored. If they are
absent, release builds currently fall back to the debug signing config — that
artifact **must not** be uploaded to Play.

Generate a dedicated upload key once, store it in the team password manager /
CI secret store, and never print its passwords in logs:

```sh
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 4096 -validity 10000
```

`android/key.properties` (outside version control):

```properties
storePassword=<from secret store>
keyPassword=<from secret store>
keyAlias=upload
storeFile=C:/secure/keys/upload-keystore.jks
```

### 2.3 Enroll in Play App Signing

1. Play Console → your app → **Setup → App integrity → App signing**.
2. Choose **Use Play App Signing** (Google manages the app signing key; the
   upload key above signs your AAB).
3. Upload the first AAB to **Internal testing**. Accept the Play App Signing
   prompt if shown.
4. Record the upload certificate SHA-256 in the release runbook.
5. If the upload key is lost, use Play Console's upload-key reset flow; the app
   signing key itself remains with Google.

### 2.4 Release build command

Replace `<API_HOST>` with the deployed backend host (no trailing slash):

```sh
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<API_HOST> \
  --dart-define=PRIVACY_POLICY_URL=https://<API_HOST>/privacy \
  --dart-define=TERMS_URL=https://<API_HOST>/terms
```

`API_BASE_URL` is required at startup; the privacy/terms defines keep the
hosted links aligned with the deployed backend. Never ship a build pointed at
`staging.invalid` or `10.0.2.2`.

Before upload:

- [ ] `flutter analyze` clean.
- [ ] `flutter test` green.
- [ ] `flutter build apk --debug` passes.
- [ ] AAB built with the real upload key (not debug).
- [ ] `versionCode` incremented; `versionName` = 0.2.0.
- [ ] Signature verified (`jarsigner -verify -verbose -certs <aab>`), or
      confirmed in Play Console after upload.
- [ ] AAB archived with its git SHA and dart-define values.

---

## 3. Data Safety form

Play Console → **App content → Data safety**. Answers must match the deployed
`/privacy` page and the actual code. Do **not** claim at-rest encryption (D6).

### 3.1 Overall answers

| Question | Answer |
|---|---|
| Does the app collect or share required user data types? | Yes |
| Does the app share data with third parties? | No (confirm runtime font fetches — see §10) |
| Is data encrypted in transit? | Yes (HTTPS/TLS) |
| Can users request data deletion? | Yes |
| Is data used for advertising or marketing? | No |
| Is data sold? | No |
| Account creation required? | Yes |

### 3.2 Field mapping (from plan §2.2)

| KASYABA field | Stored where | Data Safety type | Collected | Shared | Purpose | Required? |
|---|---|---|---|---|---|---|
| Email address | PostgreSQL `users.email` | Personal info → **Email address** | Yes | No | Account management; App functionality | Yes |
| Display name | PostgreSQL `users.displayName` | Personal info → **Name** | Yes | No | Account management; App functionality | Optional (registration allows omission) |
| Password | PostgreSQL, Argon2id hash only | Personal info → **User IDs** / **Other info** (choose the closest label in the form; it has no password type) | Yes | No | Account management; Security | Yes |
| Refresh tokens | PostgreSQL `auth_sessions.refreshTokenHash` (hashed) | **Other info** / **User IDs** (internal credential material) | Yes | No | Account management; Security | Yes |
| Wallets, transactions, transfers, bills, budgets, goals, balances | PostgreSQL ledger tables | Financial info → **Other financial info** | Yes | No | App functionality | Yes |
| IP address (rate limiting + request logs) | Server request logs / in-memory limiter | Device or other IDs → **Device or other IDs** | Yes | No | Security and fraud prevention | Yes |
| Health score, planning, forecasts | Computed server-side from ledger data | Covered by **Other financial info** | Yes | No | App functionality | Yes |
| Analytics / crash SDK data | None collected | Do not declare | — | — | — | — |

Notes for the form:

- The app contains no advertising SDK and no third-party analytics SDK.
- Password is one-way hashed with Argon2id; it is never stored or logged in
  plaintext. Refresh tokens are stored only as hashes and rotated.
- IP addresses are retained in operational logs for security/rate limiting.
  State the retention window used by the deployed policy; do not invent one.
- Data deletion: in-app **Settings → Delete Account and Data** plus the public
  web portal (see §7). Deletion removes ledger rows, profile, sessions, and
  device caches; the demo/reviewer account must not be deleted.
- Re-open the Data Safety summary after the A-1 policy deploy and re-check every
  answer against `/privacy`. A mismatch is a common review rejection.

---

## 4. Content rating (IARC questionnaire)

Play Console → **App content → Content rating → Start questionnaire**.

Suggested truthful answers for this product:

| Topic | Answer |
|---|---|
| App category | **Finance** (or Utility if Finance is unavailable; be consistent with the listing) |
| Violence, blood, sexual content, nudity | No |
| Profanity, crude humor | No |
| Alcohol, tobacco, drugs | No |
| Gambling, simulated gambling | No |
| Horror/fear | No |
| User-generated content / social interaction / chat | No |
| Users can share personal information | No (no social features) |
| Shares current location | No |
| Unrestricted web access | No (only fixed legal links open in the external browser) |
| In-app purchases / ads | No / No |
| Provides financial or investment advice | No — it is a personal ledger/tracker |
| Provides medical/health advice | No |

Record the issued rating (typically Everyone/3+ or Teen) in the release notes.
The **target audience** is set separately in §5 and is the stronger control.

---

## 5. Target audience: 13+

Play Console → **App content → Target audience and content**.

- [ ] Select age groups **13-15, 16-17, 18+**.
- [ ] Do **not** select 0-12.
- [ ] "Is your app designed for children?" → **No**.
- [ ] Do not enroll in the Families program.
- [ ] Ads → **No ads**.
- [ ] Financial features declaration: personal finance tracking only; no lending,
      banking, cryptocurrency exchange, or investment advice.
- [ ] Confirm the store listing does not appeal to children (no cartoon
      mascots/child-oriented copy).

---

## 6. App access / reviewer credentials (E-7)

The app requires login, so Play Console must be told how to access it.

### 6.1 Create the reviewer account

Create a dedicated account on the **production** backend (the same one the AAB
points at). Do not use `demo@kasyaba.com`; that backend seed is local-only and
disabled in production (`SEED_DEMO_USER=false`).

- Email: `play.review+<yyyymmdd>@<your-domain>` (or another dedicated address)
- Password: generate a long random value; store it in Play Console and the team
  password manager. **Never commit the password, and never print it in CI logs.**
- Display name: `Play Reviewer`
- Accept the registration terms/consent checkbox.

Register through the app (recommended) so the same flow the reviewer sees is
exercised. If using the API directly, capture the access token from the register
response:

```sh
curl -X POST https://<API_HOST>/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"play.review+20261106@example.com","password":"<from secret store>","displayName":"Play Reviewer"}'
```

### 6.2 Seed sample data via JSON restore

The seed file is [`demo-account-seed.json`](./demo-account-seed.json). It
contains 3 wallets, 5 categories, 2 incomes, 6 expenses, 1 transfer, 1 goal with
2 contributions, 3 budgets, and 3 recurring bills. Bills are generated
immediately by the restore endpoint.

**Option A — in the app (preferred):**

1. Sign in to the reviewer account.
2. Go to **Settings → Backup and export → Restore**.
3. Paste the full contents of `demo-account-seed.json`.
4. Confirm the validation summary, then **Restore Now**.
5. Expected result: 3 accounts, 5 categories, 2 incomes, 6 expenses, 1 transfer,
   1 goal, 3 budgets, 3 bills; the Bills tab is populated.

**Option B — API:**

```sh
curl -X POST https://<API_HOST>/api/v1/auth/restore \
  -H "Authorization: Bearer <access token>" \
  -H "Content-Type: application/json" \
  --data-binary @docs/release/demo-account-seed.json
```

After either option, refresh the app. If the seed dates age past the current
month, edit the JSON dates before restoring so bills/reminders look current; do
not re-use the same IDs after a previous restore unless you intend an upsert.

### 6.3 Play Console App access entry

Play Console → **App content → App access → Manage**.

1. Choose **All or some functionality is restricted**.
2. Add an instruction set named `Reviewer account`.
3. Enter the email and password from the password manager.
4. Add reviewer notes:

   > Kasyaba is online-first. Sign in with the credentials above. The account is
   > pre-seeded with sample wallets, transactions, bills, budgets, and a savings
   > goal. If an offline banner appears, reconnect and pull to refresh. Do not
   > delete the account; it is used for review only. Grant notification
   > permission when prompted to see bill reminders.

5. Save and verify the Play Console "App access" section shows the credentials
   in the review build.

### 6.4 Fresh-install smoke (must pass in under 60 seconds)

- [ ] Install from the internal-testing track on a clean device/emulator.
- [ ] Login screen appears; demo credentials sign in successfully.
- [ ] Dashboard, wallets, transactions, bills, goals, and budgets render seeded
      data.
- [ ] Airplane mode: cached dashboard + offline banner; queued expense replays
      after reconnect.
- [ ] Bill reminder permission prompt appears when relevant.
- [ ] No crash on cold start; no account-deletion prompt.

Rotate the reviewer password after each review cycle and update Play Console.
Keep the account active until the listing is live.

---

## 7. Privacy policy and account-deletion URLs

| Play Console field | Value |
|---|---|
| Privacy policy URL | `https://<API_HOST>/privacy` |
| Account deletion URL | `https://<API_HOST>/account-deletion` |
| Terms (in-app link) | `https://<API_HOST>/terms` |
| API base URL | `https://<API_HOST>/api/v1` |

Verification:

```sh
curl -I https://<API_HOST>/privacy
curl -I https://<API_HOST>/account-deletion
curl -I https://<API_HOST>/terms
```

All must return 200 over HTTPS with no auth. Open them on a phone-sized viewport;
check that `/privacy` contains the retention, breach-notification, export, and
deletion sections from Phase A-1, and that no retired "local-first"/"100%
on-device"/"TLS 1.3 & AES-256 at rest" claims remain.

If the app is listed in multiple countries, confirm the policy and deletion page
are reachable from each target region (no geo-blocking).

---

## 8. Store listing assets and copy

Play Console → **Grow → Store presence → Main store listing**.

| Asset / field | Requirement |
|---|---|
| App name | ≤ 30 characters, e.g. `Kasyaba — Personal Finance` |
| Short description | ≤ 80 characters |
| Full description | ≤ 4,000 characters; online-first wording; no banned claims |
| App icon | 512 × 512 PNG, 32-bit |
| Feature graphic | 1024 × 500 PNG/JPEG, no transparency |
| Phone screenshots | ≥ 2; recommend 4-6 at 1080 × 1920 or higher (16:9/9:16) |
| Tablet screenshots | Optional; add if tablet support is claimed |
| Category | Finance |
| Contact email | `SUPPORT_EMAIL` from the deployed backend |
| Privacy policy | Deployed `/privacy` URL |

Copy rules (D6/Phase A):

- Say **online-first**, not "local-first".
- Say tokens/preferences are in encrypted secure storage; the ledger snapshot
  cache is plaintext on-device.
- Say "encrypted in transit (HTTPS/TLS)"; do not claim a specific TLS version or
  AES-256 at rest unless deployment verification is complete.
- Export: JSON (full) / CSV (transactions only).
- No "100% on-device math", "every calculation runs on your device", or
  "fully functional offline".

Also complete:

- [ ] **Store settings → App category** = Finance; add tags.
- [ ] **Store settings → Contact details**.
- [ ] **App content → Ads** = No ads.
- [ ] **App content → Government apps** = No.
- [ ] **App content → News apps** = No.
- [ ] **App content → COVID-19 contact tracing** = No.
- [ ] **App content → Data safety** (see §3).
- [ ] **App content → Content rating** (see §4).
- [ ] **App content → Target audience** (see §5).
- [ ] **App content → App access** (see §6).

---

## 9. Build and manifest verification

### 9.1 Debug build (must pass in this phase)

```sh
flutter build apk --debug
```

Inspect the merged manifest (AGP 9 path):

```powershell
$m = "build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml"
[xml]$doc = Get-Content $m -Raw
$app = $doc.manifest.application
$perms = @($doc.manifest.'uses-permission' | ForEach-Object { $_.name })

"minSdk=$($doc.manifest.'uses-sdk'.minSdkVersion) targetSdk=$($doc.manifest.'uses-sdk'.targetSdkVersion)"
"allowBackup=$($app.allowBackup)"
"fullBackupContent=$($app.fullBackupContent)"
"dataExtractionRules=$($app.dataExtractionRules)"
$perms | Where-Object { $_ -match 'INTERNET|POST_NOTIFICATIONS|ALARM' }
"USE_EXACT_ALARM present: $($perms -contains 'android.permission.USE_EXACT_ALARM')"
```

> Do not grep the raw file for `USE_EXACT_ALARM`: the explanatory XML
> comment contains that string. Check the parsed permission list instead.

Expected:

- `android:allowBackup="false"`
- `android:fullBackupContent="@xml/backup_rules"`
- `android:dataExtractionRules="@xml/data_extraction_rules"`
- `android.permission.INTERNET`
- `android.permission.POST_NOTIFICATIONS` (merged from
  `flutter_local_notifications`; not declared twice by the app)
- **No** `android.permission.USE_EXACT_ALARM`
- `android.permission.SCHEDULE_EXACT_ALARM` (intentional, local bill reminders)
- A `<queries>` intent with `android.intent.action.VIEW` and
  `android:scheme="https"` (url_launcher/package visibility)
- `minSdkVersion="24"`, `targetSdkVersion="36"`
- No `android:enableOnBackInvokedCallback` requirement

Confirm the packaged XML resources exist in the AAB/APK and inspect the final
APK manifest:

```sh
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep -E 'res/xml/(backup_rules|data_extraction_rules)'
aapt2 dump xmltree build/app/outputs/flutter-apk/app-debug.apk --file AndroidManifest.xml \
  | grep -E 'allowBackup|fullBackupContent|dataExtractionRules|USE_EXACT_ALARM|SCHEDULE_EXACT_ALARM|POST_NOTIFICATIONS|scheme'
```

Release manifest/resources can be checked without signing or assembling the
AAB:

```powershell
cd android
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\gradlew.bat :app:processReleaseMainManifest :app:processReleaseResources
```

Then repeat the parsed-manifest checks against
`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`.
Both debug and release must show the backup attributes, `INTERNET`,
plugin-provided `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, and no
`USE_EXACT_ALARM`.

### 9.2 Release AAB (only with a real upload key)

```sh
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<API_HOST> \
  --dart-define=PRIVACY_POLICY_URL=https://<API_HOST>/privacy \
  --dart-define=TERMS_URL=https://<API_HOST>/terms
```

- If `android/key.properties` or the referenced keystore is missing, **stop**.
  Do not upload the debug-signed fallback artifact.
- Do not upload a pre-existing `build/app/outputs/bundle/release/app-release.aab`
  that predates the version bump; rebuild after changing `pubspec.yaml`.
- Verify the bundle manifest and signature:
  - `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
  - `bundletool dump manifest --bundle=...` (optional)
  - Play Console will also show the certificate after upload.

---

## 10. Submission sequence and rollback

1. Deploy backend + A-1 policy; run migrations and bill repair; verify public
   URLs (§1).
2. Seed the reviewer account on that backend (§6).
3. Bump `version: 0.2.0+2`; configure the upload key and Play App Signing (§2).
4. Build + sign the AAB with production dart-defines (§2.4).
5. Upload to **Internal testing**; install from Play on a clean device; run the
   §6.4 smoke and the E-5 device matrix.
6. Review the pre-launch report; fix crashes/ANRs.
7. Complete Data Safety, content rating, target audience, App access, store
   listing (§3-§8).
8. Promote to **Closed testing** if external testers are needed; then
   **Production** with a staged rollout (e.g. 10% → 50% → 100%).
9. Watch crash/ANR rate, login success, and API 5xx for the first 24-48 hours.

Rollback:

- Halt the staged rollout in Play Console; the previous version remains
  available to users.
- Never reuse a `versionCode`; ship a fix with the next increment.
- Keep the previous AAB, its git SHA, and its dart-define values archived.
- If the backend breaks the app, roll back the backend first (the app is
  online-first; the API is the source of truth).

---

## 11. Open items / owner actions

- [ ] **Phase A-1 backend policy rewrite is in the working tree but not yet
      verified as deployed.** The deployed `/privacy` must be checked for the
      online-first wording, retention/breach sections, and removal of
      unverified TLS/AES-at-rest claims. This blocks review until live.
- [ ] No release keystore or `android/key.properties` in this environment; the
      release AAB step was skipped. Create the upload key and enroll in Play App
      Signing (§2).
- [ ] `build.gradle.kts` currently falls back to debug signing when
      `key.properties` is absent. Treat that as a release blocker; consider
      making the release build fail fast instead of producing a debug-signed
      AAB.
- [ ] Bump `pubspec.yaml` to `0.2.0+2` (app-code owner; this phase did not edit
      `pubspec.yaml`).
- [ ] Confirm whether `google_fonts` downloads fonts at runtime. If it does,
      either bundle the fonts or disclose the third-party request in the privacy
      policy/Data Safety; otherwise the "no sharing" answer is at risk.
- [ ] Verify edge-to-edge insets on Android 15+ (targetSdk 36 enforces
      edge-to-edge). The stabilization UI pass should already cover this; run a
      device smoke.
- [ ] Rotate reviewer credentials after each review cycle; keep the account
      active.
- [ ] Re-verify `/privacy` after every policy deploy; Data Safety and the hosted
      policy must not drift.

---

## 12. Verification snapshot (2026-11-06)

- `flutter build apk --debug` — **PASS**;
  `build/app/outputs/flutter-apk/app-debug.apk` produced.
- Release AAB — **skipped**: `android/key.properties` absent and no keystore
  file present; no signing secrets were available. No keystore was created or
  committed. The checked-in signing fallback would produce a **debug-signed**
  release artifact, which must not be uploaded.
- Debug merged manifest — `allowBackup=false`, both rules attributes present,
  `INTERNET` present, `POST_NOTIFICATIONS` merged once from the notifications
  plugin, `USE_EXACT_ALARM` absent, `SCHEDULE_EXACT_ALARM` present,
  `targetSdkVersion=36`, `minSdkVersion=24`, VIEW/https query present,
  `enableOnBackInvokedCallback` absent.
- APK contents — `res/xml/backup_rules.xml` and
  `res/xml/data_extraction_rules.xml` packaged; `aapt2 dump xmltree` confirms the
  final APK carries the attributes.
- Release manifest/resources — `:app:processReleaseMainManifest` and
  `:app:processReleaseResources` **PASS**; the release merged manifest matches
  the debug posture.
- SDK pins — `compileSdk=36`, `targetSdk=36`, `minSdk=24`,
  `ndkVersion=28.2.13676358`.
- Build note — `kotlin.incremental=false` was added to
  `android/gradle.properties` because Kotlin's incremental cache cannot
  relativize Pub-cache sources on `C:` against this workspace's build directory
  on `D:`. Remove it if the workspace and Pub cache move to the same drive.
