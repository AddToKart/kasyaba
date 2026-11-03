# Kasyaba — Stabilization, UI Alignment & Cleanup Execution Plan

> **Audit date:** 2026-11-04 · **Scope:** `kasyaba-app/` Flutter client (73 Dart files: 70 hand-written + 3 generated) · **Status:** EXECUTED on 2026-11-04. Verification: `flutter analyze` clean, `flutter test` 103/103 passing, `flutter build apk --debug` succeeded, backend `tsc --noEmit` clean.
>
> **Method:** Four parallel read-only audit agents — (1) Route & Dead Code Scanner, (2) UI-to-State Wiring Auditor, (3) Financial Engine & Reactive Flow Verifier, (4) Design System Consistency Auditor. All file references below are `path:line` as reported by the audits.

## Execution status (2026-11-04)

**Decisions applied:** D1 implemented tokens canonical · D2 dark mode frozen · D3 goals use router routes · D4 `/transfers/add` deleted · D5 `fl_chart` kept for the live forecast chart · D6 recovery-analysis engine deleted · D7 Google login deleted · D8 Add-Bill "Pay from" removed, "Remind me"/"Category" wired to backend fields.

**Completed:**
- **Phase 1 / Step D:** 7 dead widget files deleted (+2 broken tests), `AnimatedCurrencyText`, `FloatingDockFabLocation`, `AuthGradientButton`, `CategoryIconHelper.getColor`, 6 dead methods, dead route `/transfers/add` + wrapper screen, orphaned assets (`goal_back.svg`, `dashboard_forecast_chart.svg`), and 3 unused packages (`table_calendar`, `flex_color_scheme`, `lucide_icons_flutter`). `recoveryAnalysisProvider` bundle deleted.
- **Phase 2 / Step A:** All mock-money fallbacks removed (₱825,149.80, ₱50k/₱10k goal, ₱45k salary, ₱255.68/hr, ₱50k phantom item, ÷3 installment, runway 90). Notification settings fully persisted/wired (7 controls + per-bill lead days). Safe-to-spend exclusions persisted and wired into every safe-spend calculation. Month picker wired to `transactionFilterProvider`; bills recurrence/category/reminder fields wired; income-source chips made coherent; Add-Transaction CTA gets a real disabled/loading state; add-bill prefill mocks removed; CSV export now paginates all transactions; backup timestamp recorded; error-swallow and raw-exception sweeps done across active screens.
- **Phase 3 / Step B:** Invalidation chains fixed (goal deposit→goal detail, profile→planning, bill paid/unpaid→budget status, restore→planning/alerts/goal-detail, account/goal/bill→alerts). `goalDetailProvider` is autoDispose. Payday schedules now support `10th & 25th`, custom day strings, and bi-weekly. Unified `goalMonthlyNeed`; installment "Cash left" now uses `postInstallmentBalance`; runway derived from the safe-spend numerator with an explicit "unknown" state; planned transactions excluded from month totals.
- **Phase 4 / Step C:** `KasyabaTokens` single source of truth (DashboardTokens kept as adapter), dark `ThemeData` rebuilt on the navy system with DM Sans, shared kit created (`KasyabaBackground`, `KasyabaCard`, `PillButton`, `LabelRowField`, `AppSheet`, `showKasyabaSheet`, `showKasyabaConfirmDialog`, `KasyabaEmptyState`, `KasyabaErrorCard`, `KasyabaLoadingSkeleton`, `kasyabaDatePickerTheme`). Legacy splash/reconcile/backup-sheets/offline-banner/release-error surfaces restyled; 18 raw SnackBars migrated to `KasyabaToast`; string font families replaced; ledger legacy surfaces removed.
- **Phase 5 / Step gates:** analyze clean at every gate; unit + widget suites green; debug APK builds; backend compiles.

**Remaining follow-ups (intentionally not blocking):**
- P3-01/P3-13: dedicated provider-invalidation matrix test + CI wiring (current coverage is formula/prefs/widget-level).
- P4-15: custom lint guard banning raw `Color(0x…)`/`Colors.*` outside the tokens file.
- P3-26/F-10: unify the accounts client-sum vs server `totalBalance` display policy.
- V-4: on-device manual smoke (offline reconcile→sync, deposit→goal detail, bill-paid→budget, profile→planning).
- Backend: deploy the `listBills` template-include change (the client parses both nested and top-level fields, so it remains compatible pre-deploy).
- Light theme branches in auth/theme remain as dormant legacy; dark mode is the shipped mode (D2).

## Architecture reality (context for every phase below)

- The **backend REST API is the financial source of truth** (`lib/core/api/api_client.dart:20`). Drift is **not** a data store for financial data — `lib/core/database/database.dart:38` declares only 2 tables: `CachedDashboard` (JSON cache) and `OfflineTransactions` (offline mutation queue).
- Therefore there are **no Drift `watch()` streams backing financial data**. Real-time UI updates depend 100% on the manual `ref.invalidate()` chains inside `TransactionMutator` (`lib/core/providers/api_providers.dart:1199-1210`). The only true reactive stream is the offline queue watcher (`lib/core/database/cache_service.dart:100-109`).
- Structure drift vs. documented layout: `lib/shared/models`, `lib/core/widgets`, `lib/core/formatting`, `lib/core/network`, and `lib/features/onboarding` **do not exist**. Models are consolidated inside `lib/core/providers/api_providers.dart`. New-user "onboarding" lives inline on the dashboard (`_QuickStartChecklistCard`, `lib/features/dashboard/screens/dashboard_screen.dart:502`).
- **Token-source-of-truth discrepancy (must be decided before Phase 4, see §5.2/D1):** the Figma brief hexes (`#070D17`, `#16263A`, `#2A3F5A`, `#0B131E`, `#D8E2EE`, `#8FA3B8`) appear **nowhere in code**. The implemented (and cross-screen consistent) navy system is `DashboardTokens` (`lib/features/dashboard/widgets/dashboard_tokens.dart:6-49`): base `#0A1220` (ebony), card fill `#16293F` (bigStone), elevated fill `#1E3A56` (cello @60%), borders `#8FB2CE` at 22%–30% alpha, primary text `#C9DCEA`, secondary text `#B4CDE0`, radial glow `#4F7596`. Either the Figma file is the authority (re-migrate hexes) or the implemented tokens are (update Figma). **All Phase 4 work is keyed to the implemented tokens until decided otherwise.**

### Audit summary

| # | Sub-agent | Headline result |
|---|---|---|
| 1 | Route & Dead Code | 23 routes declared / 3 dead; 5 orphaned files, 11 dead classes, 6 dead methods; 1 orphaned provider (+3 models); 1 orphaned asset; 4 removable packages (1 conditional) |
| 2 | UI-to-State Wiring | 0 literal `onPressed: () {}` stubs — but ~15 dead controls (setState-only, never persisted/sent), ~25 hardcoded mock values in live paths, 5 silent-error swallows, ~10 fake empty states on failure, 10 raw-exception leaks |
| 3 | Financial Engine | Reactivity analog: mutation→display chains are SAFE for transactions/accounts; **BROKEN for: goal deposit→goal detail, profile→planning, bill paid→budget status, restore→planning/alerts**; 6 formula verdicts CORRECT, 3 SUSPECT, 1 dummy chart |
| 4 | Design System | 17/27 surfaces compliant; 3 competing token classes (legacy `AppColors`/`AppTheme` still powers `ThemeData`); 4 hard-legacy surfaces; 18 raw SnackBars; 3 bottom-sheet architectures; light mode broken by design |

---

# Phase 1: Route & Dead Code Audit (Safe Pruning)

## 1.1 Navigation & Router Mapping

Entry chain: `main.dart:30` (`runApp(ProviderScope(KasyabaApp))`) → `lib/app/app.dart:16-29` (`MaterialApp.router(routerConfig: ref.watch(routerProvider))`) → `lib/app/router/router.dart:32` (`routerProvider`).

- App-level keep-alives (`app.dart:17-21`): `isOnlineProvider`, `themeModeProvider`, `offlineSyncProvider`, `billReminderSyncProvider`, `accountBootstrapProvider`; offline banner overlaid via `MaterialApp.builder` (`app.dart:30-79`).
- **Initial location `/splash`** (`router.dart:36`); single global `redirect` guard (`router.dart:37-54`): hold on splash while `authState.isInitializing` (`:48`) → splash resolves to `/dashboard` (authed) or `/login` (`:49`) → unauthed non-auth route → `/login` (`:51`) → authed auth-route → `/dashboard` (`:52`).

### Active route map (all verified to exist; global redirect guard applies to every route below)

**Bottom-dock ShellRoute** (shell = `lib/app/router/app_shell.dart:41`, dock `_LuxuryFloatingDock` `:86`):

| Path | Screen |
|---|---|
| `/dashboard` | `lib/features/dashboard/screens/dashboard_screen.dart` |
| `/transactions` | `lib/features/transactions/screens/transactions_screen.dart` |
| `/planning` | `lib/features/planning/screens/planning_screen.dart` |
| `/planning/breakdown` | `lib/features/planning/screens/math_breakdown_screen.dart` (extra: `DailySafeSpendCalculation?`) |
| `/goals` | `lib/features/savings/screens/goals_screen.dart` |
| `/bills` | `lib/features/bills/screens/bills_screen.dart` |
| `/settings` | `lib/features/settings/screens/settings_screen.dart` |
| `/budgets` | `lib/features/budgets/screens/budgets_screen.dart` |
| `/alerts` | `lib/features/alerts/screens/alerts_screen.dart` |

**Root-level / sub-routes (no dock):**

| Path | Screen | Notes |
|---|---|---|
| `/splash` | `lib/features/splash/screens/splash_screen.dart` | |
| `/login` | `lib/features/auth/screens/login_screen.dart` | |
| `/register` | `lib/features/auth/screens/register_screen.dart` | |
| `/forgot-password` | `lib/features/auth/screens/forgot_password_screen.dart` | |
| `/transactions/add` | `lib/features/transactions/screens/add_transaction_screen.dart` | extra `String?` initialType; also serves transfer mode via wrapper |
| `/transactions/edit` | same file | extra must be `TransactionEntry`, else stub scaffold (`router.dart:151-168`) |
| `/transfers/add` | `lib/features/transactions/screens/add_transfer_screen.dart` | **DEAD ROUTE** — zero navigation calls (§1.2) |
| `/accounts` | `lib/features/accounts/screens/accounts_screen.dart` | |
| `/settings/notifications` | `lib/features/settings/screens/notification_settings_screen.dart` | |
| `/settings/backup` | `lib/features/settings/screens/backup_export_screen.dart` | |
| `/settings/delete-account` | `lib/features/settings/screens/delete_account_screen.dart` | |
| `/bills/add` | `lib/features/bills/screens/add_bill_screen.dart` | extra preset name |
| `/goals/new` | `lib/features/savings/screens/create_goal_screen.dart` | **DEAD ROUTE** — bypassed by raw `Navigator.push` (§1.2) |
| `/goals/:id` | `lib/features/savings/screens/goal_detail_screen.dart` | **DEAD ROUTE** — bypassed by raw `Navigator.push` (§1.2) |

Imperative `context.go/push` calls from every screen were catalogued (dashboard:197-1479, transactions:202-1136, bills:443-998, settings:1127-1534, etc. — see route table above for the key ones). All targets are declared routes; **no navigation to undeclared paths** was found.

**Dialogs / bottom sheets** (19 sheet + 5 dialog call-sites) are catalogued per screen in Phase 2/4 (each is listed with owner file:line in §2 and the design audit §4).

- [ ] **P1-01** Decide fate of the 3 dead route declarations: delete `/transfers/add` (D4), and either rewire goals screens to `/goals/new` + `/goals/:id` or delete those routes (D3).
- [ ] **P1-02** Fix dock highlight mismatch: `/budgets`, `/alerts`, `/accounts`, `/transactions/add` fall back to tab index 0 (Home lights up) — `lib/app/router/app_shell.dart:47-54`. (`/bills`→Forecast is intentional `:49`.)
- [ ] **P1-03** Replace raw `Navigator.push(MaterialPageRoute(...))` with router navigation (kills deep-links + motion transitions): `lib/features/savings/screens/goals_screen.dart:138-142, :368-372, :407-414` and `lib/features/savings/screens/goal_detail_screen.dart:459-463`.
- [ ] **P1-04** Remove or collapse the unreachable edit-mode stub scaffold (`router.dart:153-167` renders "Transaction details unavailable." plain text) — type-guard the `/transactions/edit` extra.

## 1.2 Orphaned Pages & Widgets (safe to delete)

Full reverse-import graph was built (every file's basename searched as import/part across `lib/` and `test/`). **All 22 routed screens and their widgets are ACTIVE.** The dead inventory:

| File | Contents | Verdict | Evidence |
|---|---|---|---|
| `lib/shared/widgets/stat_card.dart` | `StatCard` (:8) | ORPHANED | imported by nothing |
| `lib/shared/widgets/modern_card.dart` | `ModernCard` (:11), `CardStyle` enum (:9) | ORPHANED | only importee = dead `stat_card.dart` |
| `lib/shared/widgets/modern_text_field.dart` | `ModernTextField` (:7) | ORPHANED | imported by nothing |
| `lib/shared/widgets/empty_state_view.dart` | `EmptyStateView` (:7) | TEST-ONLY | `test/widget/screens_test.dart:4` only |
| `lib/shared/widgets/rolling_counter.dart` | `RollingCounter` (:10) + internals | TEST-ONLY | `test/widget/motion_widgets_test.dart:4` only |

Dead classes inside otherwise-active files:

| Class | Location | Evidence |
|---|---|---|
| `FloatingDockFabLocation` | `lib/app/router/app_shell.dart:14-39` | 55-line `FloatingActionButtonLocation` subclass, never assigned (shell has no FAB) |
| `AuthGradientButton` | `lib/features/auth/widgets/auth_widgets.dart:792-861` | never constructed |
| `PasswordStrengthBar` | `lib/features/auth/widgets/auth_widgets.dart:882-939` | never constructed — ironically the register screen's missing strength indicator |
| `PasswordMatchIndicator` | `lib/features/auth/widgets/auth_widgets.dart:941-978` | never constructed |
| `AnimatedCurrencyText` | `lib/shared/widgets/motion_components.dart:216-248` | broken dead code: `Tween(begin: value, end: value)` (`:235`) can never animate; TEST-ONLY + never instantiated in lib |
| `CardStyle` | `lib/shared/widgets/modern_card.dart:9` | inside orphaned file |

Dead route screens/wrappers (delete with their routes):

| File | Contents | Evidence |
|---|---|---|
| `lib/features/transactions/screens/add_transfer_screen.dart` | 10-line wrapper for the dead `/transfers/add` route (`:4-11`); transfer mode is served by `/transactions/add` (`add_transaction_screen.dart:715` segmented pill) | constructed only by router |
| Old-generation safe-spend breakdown sheet (inline) | `_showSafeSpendBreakdownSheet` at `lib/features/dashboard/screens/dashboard_screen.dart:1055`, opened from `dashboard_screen.dart:329` | **duplicate generation** — Planning + Affordability sheet use the new-gen `lib/features/dashboard/widgets/kasyaba_safe_spend_breakdown_sheet.dart:9-13` → `/planning/breakdown`; dashboard hero still opens the old inline one |

- [ ] **P1-10** Delete 5 orphaned files: `stat_card.dart`, `modern_card.dart`, `modern_text_field.dart`, `empty_state_view.dart`, `rolling_counter.dart` — **after** their widget tests are removed/rewritten (they are still exercised by `screens_test.dart`, `motion_widgets_test.dart`, `motion_suite_test.dart`).
- [ ] **P1-11** Delete dead classes: `FloatingDockFabLocation`, `AuthGradientButton`, `PasswordStrengthBar`, `PasswordMatchIndicator`, `AnimatedCurrencyText` (+ its broken tween), `CardStyle`.
- [ ] **P1-12** Resolve the duplicate safe-spend breakdown generations: switch dashboard hero tap (`dashboard_screen.dart:329`) to the new-gen sheet/route, delete the old inline sheet (`dashboard_screen.dart:1055` region), then delete `ModernBottomSheet` usage in dashboard if that was its only consumer.
- [ ] **P1-13** Capture the `PasswordStrengthBar`/`PasswordMatchIndicator` designs before deletion — they are the natural wiring candidates for the Register screen password field (see Phase 2, R-05).

## 1.3 Unused State & Logic (truly dead vs UI-disconnected-but-alive)

### Truly dead (legacy of stripped features)

| Item | Location | Evidence |
|---|---|---|
| `AuthNotifier.googleLogin(String)` | `lib/core/auth/auth_provider.dart:257-294` | fully implemented POST `/auth/google` flow, but no Google button exists anywhere in the redesigned UI. (Note: original product plan `plan/PLAN.md` listed Google Sign-In as MVP scope — delete or restore deliberately.) |
| `AuthNotifier.clearError()` | `lib/core/auth/auth_provider.dart:409-411` | zero callers |
| `checkConnectivityOnce()` | `lib/core/connectivity/connectivity_service.dart:55-58` | superseded by `isOnlineProvider` |
| `NotificationService.cancelAllNotifications()` | `lib/core/notifications/notification_service.dart:97-99` | per-bill cancels at `:77,89` handle cleanup; never called even at logout |
| `CurrencyFormatter.formatNumber()` | `lib/core/utils/currency_formatter.dart:42-47` | 0 callers |
| `CurrencyFormatter.formatInteger()` | `lib/core/utils/currency_formatter.dart:57-63` | 0 callers |

### UI-disconnected-but-alive (do NOT delete — re-wire or decide)

| Item | Location | Meaning |
|---|---|---|
| `recoveryAnalysisProvider` (+ models `RecoveryAnalysis` :1638, `RootCauseItem` :1599, `ActionStepItem` :1617) | `lib/core/providers/api_providers.dart:1691-1699` | Old "financial recovery / health analysis" engine: fetched from `/alerts/analysis`, invalidated on every transaction mutation (`:1203`), **rendered nowhere**. `/alerts` shows only the flat `alertsProvider` list. Also **never makes an API call until something watches it** — deleting the UI wiring nothing back is zero-cost; keeping it costs nothing until re-wired. Decide (D6). |
| `transactionFilterProvider` | `lib/core/providers/api_providers.dart:771-773` | Watched by `paginatedTransactionsProvider` (`:779`) but **no UI mutates it** — the redesigned transactions screen (`transactions_screen.dart:288-316`) has a month picker that never writes this filter. Active UI gap, not dead logic (Phase 2 wires it). |
| Notification-settings state | `lib/features/settings/screens/notification_settings_screen.dart:21-27` | All 7 toggles + reminder time are local-only; the live reminder engine hardcodes "day before 09:00" (`notification_service.dart:81-93`). Settings keys don't exist server-side or in storage — plumbing must be built (Phase 2). |

### Verified ACTIVE (do not touch)

- All other 27 providers in `api_providers.dart` have verified watch/read/invalidate sites (full site list held in audit transcript).
- All 17 `TransactionMutator` methods have ≥1 call site (`api_providers.dart:999-1407`).
- Drift `CacheService` methods: no dead query methods; both tables (`CachedDashboard`, `OfflineTransactions`) actively written/read.
- `budgetRepositoryProvider` (`:1415`) is an **alias** of `transactionMutatorProvider` — naming duplication, not dead code; consider renaming in cleanup (cosmetic).
- `NotificationService.syncBillReminders` + `BillReminder`: ACTIVE (`lib/core/connectivity/bill_reminder_sync.dart:20-27`).

- [ ] **P1-20** Delete truly-dead items in §1.3 table row 1 (6 methods) once build-verified.
- [ ] **P1-21** Decide `recoveryAnalysisProvider` fate (D6): ship an Alerts top card consuming it, or delete provider + 3 models + its hub invalidation line `:1203`.
- [ ] **P1-22** Keep `transactionFilterProvider` — flagged for re-wiring in Phase 2 (T-01).
- [ ] **P1-23** (Optional, safe) Rename `budgetRepositoryProvider` alias or collapse it to `transactionMutatorProvider` at call sites (`goal_deposit_sheet.dart:74`, `create_goal_screen.dart:127`, `goal_detail_screen.dart:80`).

## 1.4 Asset & Dependency Check

**Assets** — 26 files in `assets/images/`; 25 referenced. Orphan:

| Asset | Evidence |
|---|---|
| `assets/images/goal_back.svg` | 0 references in `lib/` and `test/` (legacy goal-detail back arrow from old UI) |

**pubspec dependencies** (`kasyaba-app/pubspec.yaml:9-44`) verified by import grep:

| Package | Verdict |
|---|---|
| `fl_chart ^0.70.2` | **0 imports** — all charts are hand-drawn SVG or `CustomPainter`. ⚠ **Conditional removal:** Phase 3 (F-02) needs a real forecast chart; if it will be built with `fl_chart`, KEEP the package and mark used; if the chart uses `CustomPainter` (consistent with `month_end_forecast_card.dart:252` painter), remove. Decide before pruning (D5). |
| `table_calendar ^3.1.3` | **0 imports** — the 7-day strip on transactions is hand-rolled (`transactions_screen.dart:318,376`). Remove. |
| `flex_color_scheme ^8.1.1` | **0 imports** — `app_theme.dart` builds raw `ThemeData`. Remove. |
| `lucide_icons_flutter ^4.0.0` | **0 imports** — icons are `Icons.*` + project SVGs. Remove. |
| `json_annotation` | no direct import but required codegen runtime (`api_providers.g.dart:6`). **Keep.** |
| `sqlite3_flutter_libs` | no dart import — required by drift Native on Android. **Keep.** |
| `reactive_forms` | used by auth only (`auth_widgets.dart:5`, login/register/forgot). **Keep while auth forms remain.** |
| All others (riverpod, go_router, dio, freezed_annotation, secure_storage, intl, notifications, timezone, connectivity_plus, drift, path_provider, path, uuid, flutter_svg, google_fonts) | ≥1 active import. **Keep.** |

- [ ] **P1-30** Delete `assets/images/goal_back.svg`.
- [ ] **P1-31** Remove `table_calendar`, `flex_color_scheme`, `lucide_icons_flutter` from pubspec; `flutter pub get`; build-verify.
- [ ] **P1-32** Resolve `fl_chart` (D5): keep-and-use for Phase 3 chart rebuild, or remove with dependencies batch. Either way, no pubspec change before the chart decision is made.

---

# Phase 2: UI-to-Backend & State Reconnection

Severity key: 🔴 blocks/correctness · 🟡 polish/visibility. "Dead control" = has local `setState` but is never persisted, sent, or consumed anywhere.

## 2.1 Form & Action Wiring (per screen, with exact file:line)

### 2.1.1 Cross-cutting dead controls (highest concentration)

| ID | Dead control | Location | Real backing that exists |
|---|---|---|---|
| W-01 | **Entire Notification Settings screen** — 7 controls (bill reminders, days-before, budget alerts, payday reminder, goal milestones, weekly summary, reminder time), all local State, **0 providers, 0 storage, 0 API calls** | `notification_settings_screen.dart:21-27` | `NotificationService.syncBillReminders` (`notification_service.dart:73-95`) hardcodes 1-day-before/09:00; `billReminderSyncProvider` re-syncs from `billsProvider` emission. **Needs a persisted prefs store + service signature change** (R-14). |
| W-02 | **"Count in safe to spend" toggle** writes local `_excludedAccountIds` only — never persisted, never read by `calculateDailySafeSpend` (`lib/core/utils/deterministic_math.dart:104-186` takes all accounts); footnote at `accounts_screen.dart:659` promises behavior that doesn't exist | `accounts_screen.dart:24, :713, :856-876` | Needs persistence + a filter param on `calculateDailySafeSpend` + invalidation wiring (R-15). |
| W-03 | **"Remind me" chips** on Add Bill — selectable, never sent (`addBill` payload `api_providers.dart:1340-1345` has no reminder field) | `add_bill_screen.dart:36, :599-640` | Same prefs plumbing as W-01. |
| W-04 | **"Pay from" account picker** on Add Bill — selected, never sent | `add_bill_screen.dart:37, :646-673` | Could preload the default account for later `markBillPaid(acct)` (`api_providers.dart:1354`) or be removed. |
| W-05 | **"Category" picker** on Add Bill — selected, never sent; `addBill` has no category param | `add_bill_screen.dart:38, :677-691` | Backend field needed or remove control. |
| W-06 | Income "SOURCE" chips — only overwrite note text conditionally (`:1073-1078`); actual submitted `source` is the description field (`:526`) | `add_transaction_screen.dart:73, :1065-1110` | Clarify semantics: commit chip → note, or remove. |

### 2.1.2 Hardcoded mock values in live paths (ranked by money-damage)

| ID | Mock | Location | Live data that exists |
|---|---|---|---|
| M-01 | 🔴 **Fake ₱825,149.80 wallet balance**: `balances[selectedAccount.id] ?? 825149.80` — **submittable path**: fallback `Account(id: 'cash_wallet', ...)` (`:117-126`) with a non-UUID id is sent as `accountId` → guaranteed server rejection | `goal_deposit_sheet.dart:129` | `accountBalancesProvider` (`api_providers.dart:70`). Fix: block submit + show error state when accounts/balances not loaded; remove constant (it is the Figma test fixture, `dashboard_redesign_test.dart:24`). |
| M-02 | 🔴 **Fabricated goal fallback**: `SavingsGoal(id: goalId, name: 'Savings Goal', targetAmount: 50000, currentAmount: 10000)` rendered in both fallback branches | `goal_detail_screen.dart:108-121` | `goalsProvider`/`goalDetailProvider` exist. Fix: skeleton/error state instead of mock. |
| M-03 | 🔴 **Deposit prefill ₱5,000**; `CreateGoal` prefills `'New phone'`/`'30000'`; AddBill prefills `'Electricity'`/`'2500'`; income prefills `'Monthly salary'` submitted as source if untouched | `goal_deposit_sheet.dart:45` · `create_goal_screen.dart:36-38` · `add_bill_screen.dart:52-55` · `add_transaction_screen.dart:137,176` | Empty-form discipline; remove defaults (or make them only-placeholders). |
| M-04 | 🔴 **Static Figma SVG as the forecast chart**: whole chart = `assets/images/dashboard_forecast_chart.svg` (`:127-131`); `data.dailyBalance` (`api_providers.dart:296, 320-325`) is fetched+parsed+cached and **never rendered**. Badge also mislabels balance-sign as "Bills covered" (`:26-29`) | `month_end_forecast_card.dart:122-132` | `DashboardData.dailyBalance` + `fl_chart` (locked in pubspec) or existing `CustomPainter` pattern. |
| M-05 | 🔴 **₱45,000 dummy salary fallback** powering "work hours" math, displayed as if real (`:814`, incl. ₱255.68/hr + 176h fallbacks); **₱50,000 phantom item price** for empty preview (`:124`); **÷3 magic installment fallback** (`:870`) | `kasyaba_affordability_sheet.dart:119-122, :124, :814, :870` | `userProfileProvider.salaryAmount`. Fix: hide/disclaim work-hours box when salary unset; disable evaluate until amount typed. |
| M-06 | 🔴 **₱90-capped runway / "Buffer"** computed client-side ignoring bills & goals; hardcoded `return 90` when expenses 0 → every new user sees "90+ days" | `dashboard_screen.dart:217-225` (display `quick_stats_row.dart:29`, sheet `:131,170-172`) | Align to the safe-spend engine (zero state = truth) or compute from `dailyBalance`. |
| M-07 | 🟡 Planning allocation bars show Figma defaults 25/31/44% when sum is 0 (labeled in comment) | `planning_screen.dart:388-393` | Real proportions computable from `safeSpendCalc` in scope (`:375-378`). |
| M-08 | 🟡 Hardcoded `'Monthly'` in every bill subtitle (4×) + transaction row (1×) while `addBill` accepts `recurrence` | `bills_screen.dart:864-873`, `transactions_screen.dart:1155` | `BillItem` doesn't model recurrence yet — model it or drop the word. |
| M-09 | 🟡 Hardcoded `'On track'` goal status ×2 while `SavingsGoal.canAffordByTargetDate`/`earliestAffordableDate` (`api_providers.dart:867-889`) are parsed and never read | `goals_screen.dart:533`, `goal_detail_screen.dart:270` | Wire the existing parsed helpers. |
| M-10 | 🟡 Settings: fake profile chips `'Full-time employee'`/`'25–34'` (no such fields on `UserProfile` `api_providers.dart:1420-1449`); salary fallback ₱45,000 (`:1002`); semi-monthly ÷2 math for every frequency (`:1003,1075`); static `'Over budget this month'` (`:1191`); static `'Never'` last-backup (`backup_export_screen.dart:101-109`); static `'On the 15th and 30th'` (`notification_settings_screen.dart:282`) | `settings_screen.dart:946-988, :1002-1003, :1075, :1191` | Show profile truth or "Set salary" CTA; wire `budgetStatusProvider` subtitle (R-16); write last-backup timestamp after `exportData()` (`auth_provider.dart:321`) to secure storage. |
| M-11 | 🟡 `'STEP 1 OF 2'` with no step 2 anywhere (onboarding feature doesn't exist) | `register_screen.dart:139` | Remove or build step 2 (note `accountBootstrapProvider` auto-creates "Cash Wallet", `api_providers.dart:145-174`). |
| M-12 | 🟡 Hardcoded fallback names in balance preview `'Cash Wallet'` / `'GCash'` | `add_transaction_screen.dart:598,603` | `accountsProvider` names. |
| M-13 | 🟡 Privacy sheet claims "records… encrypted on device" while app is API-backed (drift holds cache+queue in plaintext JSON) | `settings_screen.dart:724-725` | Correct the copy or the storage. |
| M-14 | 🟡 CSV export "Your transactions" = page-1 only (limit 50) | `data_backup_sheets.dart:1054` vs claim `backup_export_screen.dart:180,371` | Paginate loop or raise filter limit (mind R-17 offline-merge edge). |

### 2.1.3 Structural binding gaps

| ID | Issue | Location |
|---|---|---|
| B-01 | 🔴 Transactions **month picker mutates `_currentMonth` but never re-queries debt to `transactionFilterProvider.fromDate/toDate`** (supported end-to-end: `api_providers.dart:724-796`); monthly totals computed from page-1 (limit 50) — >50 tx/month silently wrong | `transactions_screen.dart:288-316, :353-365` |
| B-02 | 🔴 Installment-mode "Cash left" subtracts the **full purchase price** (`postCashBalance = currentBalance - purchaseAmount`, `deterministic_math.dart:295`) although only installment #1 is due today; UI shows it (`kasyaba_affordability_sheet.dart:879-880`) | Fix in Phase 3 (F-06). |
| B-03 | 🟡 `create_goal_screen` finds the newly created goal **by name** after `addGoal`: `firstWhere((g) => g.name == name, orElse: () => goals.first)` — stale list or duplicate names send the initial contribution to the **wrong goal** | `create_goal_screen.dart:143-147` |
| B-04 | 🟡 State mutation inside `build()` (no setState): `_selectedAccount/_selectedToAccount` ×3 | `add_transaction_screen.dart:585-594`, `goal_deposit_sheet.dart:113-115`, `add_bill_screen.dart:335-337` |
| B-05 | 🟡 Controllers created in helper methods, never disposed (leak per open) | `accounts_screen.dart:27-28` (name/balance) |
| B-06 | 🟡 Category chips use hardcoded `_defaultExpenseCategories` with fake ids (`'cat_food'`…) — live `categoriesProvider`/`defaultCategoriesList` (`api_providers.dart:191-222`) only used in "More" sheet; works only because `TransactionMutator._resolveCategoryId` name-matches (`:1212-1254`) | `add_transaction_screen.dart:75-83` |
| B-07 | 🟡 Add-Transaction submit CTA is a `GestureDetector(onTap: null)` during submit — no visual disabled state → double-taps presumed failures | `add_transaction_screen.dart:850-852` |
| B-08 | 🟡 Reconcile sheet double-registered handler (`PressableScale.onTap` **and** `ElevatedButton.onPressed` both call `_handleSync`) → double haptics | `reconcile_balance_sheet.dart:757-784` |
| B-09 | 🟡 Bills month picker partially wired: label updates, list shows all months (only calendar dots filter, `:789-794`) | `bills_screen.dart:57-86 vs :343-363` |
| B-10 | 🔄 (Positive findings to preserve) Every `TextEditingController`/`FocusNode` in auth + add-tx screens is disposed; auth forms fully `reactive_forms`-bound; offline queue write path fully wired (`add_transaction_screen.dart:339-576`); reconcile math+logging wired (`reconcile_balance_sheet.dart:76-99`). | — |

## 2.2 Async & Error States

**Global patterns (grep-verified counts):**

| Pattern | Sites | Locations |
|---|---|---|
| `error: (_, _) => const SizedBox.shrink()` (silent card disappearance) | 5 | `dashboard_screen.dart:374, :402, :416`; `planning_screen.dart:123`; `budgets_screen.dart:363` |
| `valueOrNull ?? []` with no error branch → **fake empty state on failure** | ~10 | dashboard MoreCard (`:429-431` + `dashboard_more_card.dart:28,36,42`), transactions bills strip (`:333, :894`), planning inputs (`planning_screen.dart:36-38`), goal-detail deposits (`:105→:416`), goal deposit accounts, add-tx/add-bill account pickers, bills screen (`:343-363` failure renders "No bills this week" `:938`), transactions main list failure renders "No transactions recorded yet" (`:995-1021→:1012`) |
| Raw exception interpolation in UI (`'$e'`/`'$err'`) despite `friendlyErrorMessage` (`lib/core/utils/error_messages.dart:5`) existing | 10 | `kasyaba_affordability_sheet.dart:94`, `goals_screen.dart:197`, `create_goal_screen.dart:163`, `goal_detail_screen.dart:91`, `goal_deposit_sheet.dart:91`, `budgets_screen.dart:721`, `settings_screen.dart:637`, `data_backup_sheets.dart:452, :1417`; `notification silently failing mark-read` (`alerts_screen.dart:151`) |
| Empty `catch (_) {}` | 13 in lib | feature-level: `login_screen.dart:70`, `register_screen.dart:74` (both mitigated by `authState.error` banner display), `alerts_screen.dart:151` (silent mark-read failure = dot never clears) |
| Ad-hoc spinners instead of token skeletons | 3 | `budgets_screen.dart:130-142`, `goals_screen.dart:661-676`, `alerts_screen.dart:451-478` |

**Well-handled reference implementations (use as the template):** dashboard hero card full `when()` with retry (`dashboard_screen.dart:312-317`), offline banner (`:301` + `:466-497`), dashboard skeleton (`:931-947`), goals/budgets/alerts/accounts/planning hero `when()` blocks, `friendlyErrorMessage` usage in add-bill.

- [ ] **P2-01** (W-01) Build a persisted notification-prefs store (secure storage key set), change `NotificationService.syncBillReminders(daysBefore, timeOfDay)` signature, read prefs in `billReminderSyncProvider`, wire all 7 controls to it (see R-14 risk note).
- [ ] **P2-02** (W-02) Persist "Count in safe to spend" exclusions (secure storage), add `excludedAccountIds` param to `calculateDailySafeSpend` + provider chain, update the dashboard/planning/affordability/math-breakdown call sites (single source; see R-15).
- [ ] **P2-03** (W-03) Wire "Remind me" → the same prefs layer (default per-bill override) or remove the control if per-bill reminders are out of scope for now.
- [ ] **P2-04** (W-04/W-05) Remove "Pay from"/"Category" from Add Bill, or model `payFromAccountId`/`category` server-side; do not leave stateful decoration.
- [ ] **P2-05** (W-06) Decide income-source semantics: commit chip → note field, or remove.
- [ ] **P2-06** (M-01) Goal deposit sheet: remove `825149.80` and `'cash_wallet'` fallbacks; disable submit when `accounts`/`balances` aren't loaded; show an in-sheet error state.
- [ ] **P2-07** (M-02) Goal detail: replace fabricated `SavingsGoal` fallback with loading skeleton + error/retry; also remove hardcoded `:140` fallback (`365` days) and `:326-329` hardcoded `_DetailRow('Counts toward', 'Safe to spend')` and fabricated "Initial balance" ledger row (`:392-412`).
- [ ] **P2-08** (M-03) Strip form prefill mocks (deposit `5000`, goal `'New phone'`/`'30000'`, bill `'Electricity'`/`'2500'`, salary `'Monthly salary'` as source).
- [ ] **P2-09** (M-04/D5) Rebuild month-end forecast chart from `DashboardData.dailyBalance` (fl_chart or the existing painter); fix badge semantics (`isPositive` ≠ "bills covered").
- [ ] **P2-10** (M-05) Affordability sheet: require salary or show "set salary" path instead of ₱45,000; remove ₱50,000 phantom price and ÷3 (disable evaluate instead); hide ₱255.68/176h fallbacks. Route raw `$e` (`:94`) through `friendlyErrorMessage`.
- [ ] **P2-11** (M-06) Reconcile runway/Buffer with the safe-spend engine or `dailyBalance`; remove the 90-day cap hack.
- [ ] **P2-12** (M-07) Planning allocation: compute real proportions or render an explicit empty state (never Figma constants).
- [ ] **P2-13** (M-08) Model bill `recurrence` on `BillItem` and render real values; same for the transaction row subtitle.
- [ ] **P2-14** (M-09) Wire `canAffordByTargetDate`/`earliestAffordableDate` into the "On track" badge (`goals_screen.dart:533`, `goal_detail_screen.dart:270`).
- [ ] **P2-15** (M-10) Settings truth sweep: profile chips (remove or add fields server-side), salary "Set salary" CTA instead of ₱45,000, per-frequency payday math (`:1003,1075`), `budgetStatusProvider`-backed Budgets subtitle, real last-backup timestamp (write after successful export), fix privacy-sheet copy.
- [ ] **P2-16** (M-11) Register: remove `'STEP 1 OF 2'` or add step 2; while in-pass, wire the orphaned `PasswordStrengthBar`/`PasswordMatchIndicator` (deliberately captured in P1-13) into the password field.
- [ ] **P2-17** (M-12) Balance preview: use real `accountsProvider` names; remove `'Cash Wallet'`/`'GCash'` literals.
- [ ] **P2-18** (M-13) Correct backup/privacy copy to reflect API-backed storage.
- [ ] **P2-19** (M-14) CSV export: loop pagination (or filter limit) so it exports "everything" as claimed; validate against offline quantum (R-17).
- [ ] **P2-20** (B-01) Wire transactions month picker → set `transactionFilterProvider.fromDate/toDate`; extend totals to full filtered set; **keep offline merge coherent** (R-17: merge currently only happens unfiltered, `api_providers.dart:823-833`).
- [ ] **P2-21** (B-02) Fix installment "Cash left" (Phase 3 F-06 UI half).
- [ ] **P2-22** (B-03) Use the POST response's created-goal id (instead of name-matching) for the initial contribution; keep a typed result out of `addGoal`.
- [ ] **P2-23** (B-04) Hoist the 3 build()-time assignments to predecessor lifecycle events (initState/didChangeDependencies + handlers).
- [ ] **P2-24** (B-05) Dispose the add-account sheet controllers.
- [ ] **P2-25** (B-06) Drive initial chips from `categoriesProvider`/`defaultCategoriesList` (or at minimum keep name-matching but drop fake ids).
- [ ] **P2-26** (B-07) Add disabled visuals to the submit CTA (`_isSubmitting` opacity/color change) or adopt a real button w/ progress.
- [ ] **P2-27** (B-08) Reconcile sheet: single tap registration.
- [ ] **P2-28** (B-09) Bills month picker: decide — filter the list, or remove the picker.
- [ ] **P2-29** (Async sweep) Replace all 5 `SizedBox.shrink()` error-swallows with a shared **ErrorCard** (Phase 4 component) with retry.
- [ ] **P2-30** (Async sweep) Give every `valueOrNull ?? []` consumer an explicit error branch (never masquerade failure as "empty"). Inventory: dashboard MoreCard, transactions (list + bills strip), planning inputs, goal detail deposits, goal deposit sheet accounts, add-tx/add-bill account pickers, bills list.
- [ ] **P2-31** (Async sweep) Route all 10 raw `$e`/`$err` strings through `friendlyErrorMessage`.
- [ ] **P2-32** (Async sweep) Alerts mark-read failure: feedback (toast) instead of silent catch.
- [ ] **P2-33** (Async sweep) Replace ad-hoc spinners with the tokenized skeleton/loader from dashboard (`dashboard_screen.dart:931-947` template).
- [ ] **P2-34** (Empty states) Add empty state to Accounts (currently zero accounts renders nothing distinct, `accounts_screen.dart:619`).

## 2.3 Navigation Flows (post-action redirects)

Verified correct (keep): login→`/dashboard` (`login_screen.dart:69`, mounted-checked), register→`/dashboard` (`:73`), forgot back→`/login` (`:53-55,209`), logout→`/login` (`settings_screen.dart:1501-1504`), delete-account→`/login` (`delete_account_screen.dart:51`), add/edit/close flows pop-then-go (`add_transaction_screen.dart:164-168`, `add_bill_screen.dart:67-69`, budgets/alerts pop-or-go fallbacks). Dashboard CTAs pass typed extras (`'expense'|'income'`) and all pushed routes exist.

- [ ] **P2-40** (P1-03) Goals flow: route via go_router (`/goals/new`, `/goals/:id`) to gain deep-links + `MotionPageTransitions` consistency; keep typed extra (`SavingsGoal?`).
- [ ] **P2-41** Guard every navigation-after-await with `context.mounted` (verified OK in most; add to any remaining sites flagged by analyzer/lint).
- [ ] **P2-42** After the deposits list becomes reactive (P3-05), confirm the deposit sheet closes and returns to whichever screen summoned it (goals vs goal-detail) with updated state — no redirect needed, just invalidation.

---

# Phase 3: Cross-Feature Data Interconnectivity (Core Financial Engine)

## 3.1 Reactive invalidation audit

The central hub `TransactionMutator._afterTransactionMutation` (`api_providers.dart:1199-1210`) invalidates: `dashboardProvider`, `paginatedTransactionsProvider`, `transactionsProvider`, `alertsProvider`, `recoveryAnalysisProvider`, `accountsProvider`, `accountBalancesProvider`, `planningProvider`, `budgetStatusProvider`, `goalsProvider`, `billsProvider`.

### SAFE chains (verified end-to-end)

| Mutation | Path | Verdict |
|---|---|---|
| Add/Edit expense & income | `add_transaction_screen.dart:493-523` → `addExpense:999`/`addIncome:1048`/`updateExpense:1087`/`updateIncome:1109` → hub (`:1044,1083,1106,1125`) | ✅ PASS |
| Transfer (+fee as 2nd expense) | `add_transaction_screen.dart:401-420` → `addTransfer:1138` (`:1170`) + `addExpense` | ✅ PASS (subtracted once/side; offline overlay math `:114-133`, `:510-570` correct & unit-tested `models_test.dart:137-190`) |
| Delete transaction | `transactions_screen.dart:245` → `deleteTransaction:1128` | ✅ PASS |
| Reconcile balance | `reconcile_balance_sheet.dart:76-99` → addExpense/addIncome | ✅ PASS |
| Derived chains | `accountBalancesProvider`←`accountsProvider.future` (`:73`), `transactionsProvider`←`paginatedTransactionsProvider.future` (`:850`), `pendingSyncCountProvider`←drift stream (`:616`), dashboard hero recomputed in build (`dashboard_screen.dart:245-250`), bill reminder re-sync on bills emit (`bill_reminder_sync.dart:16-31`) | ✅ PASS |
| Offline sync on reconnect | applies via drift stream + dashboard overlay; full-set invalidation arrives with sync (`offline_sync_service.dart:28-31`) | ✅ (partial invalidation mid-queue — see P3-14) |

### BROKEN chains (stale until restart / manual refresh)

| # | Broken link | Evidence |
|---|---|---|
| 1 | 🔴 **Goal deposit → Goal Detail deposits/progress**: `addGoalContribution` (`:1307`, invalidates at `:1325-1331`) omits `goalDetailProvider(goalId)` — a keep-alive `.family` (`:916-917`) watched at `goal_detail_screen.dart:105`. `updateGoal` DOES invalidate the family (`:1293-1296`) → proven bug, not policy | P3-05 |
| 2 | 🔴 **Profile change → Planning/Forecast**: `updateProfile` (`:1377`) invalidates only `userProfile`+`dashboard` (`:1392-1393`); `planningProvider` (server bakes `minimumBalanceThreshold` into PlanningOverview, `:482`) goes stale — planning screen (`planning_screen.dart:34`) & forecast math show pre-change numbers until restart/refresh | P3-06 |
| 3 | 🔴 **Bill marked paid → Budget status**: `markBillPaid` (`:1354`, invalidates `:1359-1364`) skips `budgetStatusProvider` although the server records an expense; regular expenses DO invalidate it (hub `:1207`) → budgets screen (`budgets_screen.dart:34`) stale | P3-07 |
| 4 | 🟡 **Bill add/pay → Alerts (+recovery)**: `addBill`/`markBillPaid`/`markBillUnpaid` never invalidate `alertsProvider` (upcoming-bill alerts lag) | P3-08 |
| 5 | 🟡 **Create/archive account → alerts/recovery/budgetStatus**: `createAccount:1174`/`archiveAccount:1191` invalidate only accounts/balances/dashboard/planning (`:1185-1196`) | P3-08 (bundle) |
| 6 | 🔴 **Restore backup → planning/alerts/goalDetail(\*)**: `restoreData` invalidates 8 providers (`data_backup_sheets.dart:587-594`) but skips `planningProvider`, `alertsProvider`, and every `goalDetailProvider` family entry | P3-09 |
| 7 | 🟡 **Offline retry/delete-queued-tx → planning/goals/bills/budgetStatus/alerts**: only paginated+dashboard+balances invalidated (`transactions_screen.dart:123-138`) | P3-10 (superseded mid-queue by sync full-set) |
| 8 | 🟡 `goalDetailProvider` family leaks: keep-alive, never disposed, stale after goal delete too (`deleteGoal:1299` invalidates goals/dashboard/planning `:1302-1304` but not the family entry) | P3-11 |

- [ ] **P3-01** Add a `verifyInvalidateMatrix` unit test harness (ProviderContainer): assert each mutation invalidates exactly the provider set defined in a central matrix constant (this is the regression test gear for the whole phase).
- [ ] **P3-05** Goal deposit: invalidate `goalDetailProvider(goalId)` (+ include in hub decision D? see P3-12) — `api_providers.dart:1325-1331`.
- [ ] **P3-06** Profile: invalidate `planningProvider` (+ `alertsProvider` if salary/threshold feed alerts) — `:1392-1393`.
- [ ] **P3-07** Bill paid/unpaid: invalidate `budgetStatusProvider` (+ `goalsProvider` where goal-pledged payments exist) — `:1359-1374`.
- [ ] **P3-08** Bill create/pay + account create/archive: invalidate `alertsProvider`/`recoveryAnalysisProvider` consistently (or consciously exclude both everywhere — pick one policy).
- [ ] **P3-09** Restore backup: invalidate `planningProvider`, `alertsProvider`, and all `goalDetailProvider` entries (family-level invalidating via the `.family` base, or per-visited-goal on restore).
- [ ] **P3-10** Offline retry/delete: align invalidation set with the sync path (or accept sync-supersedes and document).
- [ ] **P3-11** Dispose/refresh `goalDetailProvider` family semantics: either make it `autoDispose` (mind mid-flight invalidation) or invalidate on goal delete + deposit (covered above).
- [ ] **P3-12** Evaluate folding account/goal/bill mutations into the standard hub so every mutation inherits the full matrix (prevents future one-off omissions like #1-#8).
- [ ] **P3-13** (Anti-regression) Wire the invalidation matrix test into CI (`flutter test` block, §Phase 5).

## 3.2 Formula verification (quote-verified)

### CORRECT (keep, but lock with tests)

- **Daily Safe Spend** (`deterministic_math.dart:103-186`): `dailySafeSpend = max(0, (totalLiquidBalance − unpaidBillsDueBeforeNextPayday − scheduledGoalContributions) / daysUntilPayday)`; unpaid = `status != 'paid'` and `dueDate <= endOfPayday`; goal proration `dailyRate = reqMonthly/30 * daysUntilPayday` else `remaining/daysRemaining` capped. Inputs watched live at dashboard/planning/affordability/math-breakdown. Unit-tested (`deterministic_math_test.dart:52-138`).
- **Goal progress** `currentAmount/targetAmount` clamp 0–1 (`api_providers.dart:873-875`); deposit projection in sheet (`goal_deposit_sheet.dart:131-135`) correct (input data issue only, P2-06).
- **PH statutory calculator** (`ph_salary_calculator.dart:86-181`): SSS 4.5% MSC ₱4k–30k, PhilHealth 2.5% clamped ₱10k–100k, Pag-IBIG ≤₱200, TRAIN brackets — tested (`ph_salary_calculator_test.dart`).
- **Offline balance overlays** (expense/income/transfer deltas + `isPosted` exclusion) and transfer-once-per-side discipline — tested.
- **Bills status classification** overdue/upcoming/paid (`bills_screen.dart:343-354`) — logic sound (needs tests).
- **PH bracket & installment comparator base math** (`calculateInstallmentComparison`, `deterministic_math.dart:266-297`): interest/totalCost/monthlyInstallment formulas arithmetically correct (presentational interpretation issue below).
- **Goals & deposits → disposable balance**: deposits DO reduce safe-spend via `scheduledGoalContributions` (`deterministic_math.dart:133-167`) and deposit invalidates dashboard+planning (`:1325-1331`) → module link PASSES for list/total levels (detail link broken per P3-05).

### SUSPECT / FIX REQUIRED

| # | Finding | Location | Plan item |
|---|---|---|---|
| F-01 | 🔴 `computeNextPayday` handles only `15th & 30th / 1st & 15th / 1st / 30th-end / weekly`. Settings offers **`10th & 25th` and `Custom / Other`** (`settings_screen.dart:586-597`) and `bi-weekly` (`:526`) — all silently fall back to 15th & 30th (`deterministic_math.dart:92-99`) → wrong runway/safe-spend for those users | `deterministic_math.dart:59-100` | P3-20 |
| F-02 | 🔴 Forecast **chart is a static SVG**; `dailyBalance` fetched, parsed, cached, never rendered; badge semantics wrong | `month_end_forecast_card.dart:122-132, :26-29` | P2-09 (shared) |
| F-03 | 🔴 Runway/"Buffer" client-side approximation ignores bills & goals, hardcodes 90-day cap | `dashboard_screen.dart:217-225` | P2-11 |
| F-04 | 🔴 Transactions-screen monthly totals count **planned** (future-dated) transactions as spent/received — contradicts `isPosted` discipline used everywhere else (`api_providers.dart:109-112, :538-539`) | `transactions_screen.dart:353-365` | P3-21 |
| F-05 | 🔴 Installment "Cash left" subtracts full purchase price though only 1st installment is due today (`postCashBalance` `deterministic_math.dart:295`; sheet `:879-880`) | P2-21/P3-22 |
| F-06 | 🟡 Two inconsistent "monthly need" formulas for goals: no-target-date → goals_screen returns the **entire remaining** as monthly need (`goals_screen.dart:65-78`), goal_detail defaults to a 365-day horizon (`goal_detail_screen.dart:138-143`); create-goal uses a third consistent variant | P3-23 |
| F-07 | 🟡 `safeSpendReduction = amount / days` duplicated in sheet (`kasyaba_affordability_sheet.dart:753-755`) vs `cashDailyImpact` (`deterministic_math.dart:280`) — same math, two homes | P3-24 (consolidate on `deterministic_math`) |
| F-08 | 🟡 `earliestSafeBuyDate`/`daysUntilSafeBuy` (`api_providers.dart:1540-1545`) parsed, displayed nowhere; no client "months until affordable" timeline exists | P3-25 (surface or delete fields) |
| F-09 | 🟡 Installment mode exists **only** as the client-side BNPL comparator — no installment entities/table/API anywhere (the roadmap's "installment trackers" don't exist in this client) | Scope note; no client action beyond F-05/F-07 |
| F-10 | 🟡 Two sources of truth for total balance: accounts screen client-sum (`accounts_screen.dart:528-531`) vs server `dashboard.totalBalance` | P3-26 (unify display policy + document) |
| F-11 | ✅ Dashboard cache fallback serves stale `isFromCache:true` data on API failure (`api_providers.dart:593-604`) — banner exists (`dashboard_screen.dart:301`); acceptable, but new consumers of `dashboardProvider` must inherit the semantics (note for chart rebuild) | documentation only |

- [ ] **P3-20** Extend `computeNextPayday` to `10th & 25th`, `Custom / Other: <day-of-month>`, and `bi-weekly` (with anchor date from profile); add the unsupported-path unit tests.
- [ ] **P3-21** Exclude planned/future transactions from transactions-screen monthly totals (`isPosted` discipline).
- [ ] **P3-22** Installment "Cash left": show `balance − firstInstallment` (or a dedicated postInstallmentBalance) instead of full price; keep full-price as a plainly-labeled secondary line if useful.
- [ ] **P3-23** Unify goals "monthly need": one formula in `deterministic_math` (365-day default horizon, or `targetDate`-based) consumed by goals list + goal detail + create-goal preview.
- [ ] **P3-24** Consolidate `safeSpendReduction`/`cashDailyImpact` into `deterministic_math`.
- [ ] **P3-25** Surface `earliestSafeBuyDate`/`daysUntilSafeBuy` in the affordability sheet verdict (server provides it) — and then decide if any placeholder timeline widget is needed.
- [ ] **P3-26** Unify total-balance display (server-authoritative) or label the client sum as estimate; add test.
- [ ] **P3-27** Add unit tests: `TransactionMutator` methods (mock dio), invalidation matrix (P3-01), runway/allocations after fix, bills classification edges, `paginatedTransactionsProvider` pending-merge, `CacheService` queue/sync/retry, goals monthly-need unified formula.

---

# Phase 4: Design System Alignment for Non-Figma Screens & Modals

## 4.1 Token reference as-implemented (single source target: `KasyabaTokens`)

Current split: `DashboardTokens` (`lib/features/dashboard/widgets/dashboard_tokens.dart:6-49`, ⚠ defined in a feature folder) + `AuthFigmaTokens` (`auth_widgets.dart:11-64`, duplicated values) + legacy `AppColors`/`AppTheme` (`lib/app/theme/app_theme.dart:12-111`) which still powers the actual `ThemeData`.

| Semantic token | Value (as implemented) |
|---|---|
| Canvas | `#0A1220` (ebony) + radial glow `#4F7596` @ `0xAB`→transparent, center `(0.8,-1.0)` r 1.4 (`canvasGradient` `dashboard_tokens.dart:40-48`) |
| Canvas 85% | `#0A1220` @ 0xD9 (floating dock, alerts) |
| Card fill | `#16293F` (bigStone); hero variant `#1E3A56` @ 60% + `BackdropFilter` blur σ7 (cello60) |
| Card border | `#8FB2CE` @ 22% (poloBlue22) standard / 30% elevated / 16% hairline dividers |
| Primary text | `#C9DCEA` (periwinkleGray) — headings/amounts, `FontFeature.tabularFigures` |
| Secondary text | `#B4CDE0` (periwinkleGraySubtitle); tertiary `#8E97B6` (baliHai) |
| Primary button | pill r28, fill `periwinkleGray`, text `ebony` |
| Secondary button | pill r26–28, 1px `kashmirBlue`/`poloBlue30` border, text `periwinkleGray` |
| Input pill | h54–58, r27–28, fill `bigStone` (or `ebony@55` inside cards), border `poloBlue22`, focus `poloBlue` 1.5px, hint `periwinkleGray@45%` |
| Danger/warning | `#F2928A` (apricot) @15% fill (overdue/budget-exceeded/destructive) |
| Success | `#7FD8B5` (bermuda) @15% fill (income/status OK) |
| Caution (80–99%) | `#F5B942` (casablanca) + 15% fill (needs `casablanca15` const — currently raw hex `0x26F5B942` at `budgets_screen.dart:218, :524`) |
| Allocation/chart | `#6E5BFF` cornflower, `#19C3B4` java, `#F5B942` casablanca; category palette `periwinkleGray→poloBlue→kashmirBlue→#2F5578` |
| Typography | Titles/numerals `GoogleFonts.bricolageGrotesque` w700 (44/40/32/28/26/24…); body `GoogleFonts.dmSans` (w400 secondary / w700; 9–17px; 11px w700 ls1.0 all-caps labels); legacy Inter only inside `app_theme.dart:206, :432` |
| Radii in use | 28 (cards/pills/inputs), 24 (dialogs/inner), 22 (chips/segments), 16/14/12 (nested), 32 (sheet tops/auth card), 34 (dock), 36 (CTA banner) |
| Motion | `AppMotion` 100/180/320/550ms + `springRecoil`, stagger 35ms (`lib/app/theme/app_motion.dart`) — already centralized |

- [ ] **P4-01** (D1 first) Confirm the implemented token set as canonical (or re-migrate Figma hexes); then create `lib/app/theme/kasyaba_tokens.dart`: merge `DashboardTokens` + `AuthFigmaTokens` + loose near-tokens (`casablanca15`, `kashmirGlow35`, recess fill normalization — undocument raw `0xFF101E31` at `kasyaba_affordability_sheet.dart:798`, `0x26F5B942`) and **fix the inverted import direction** (`app_theme.dart:5` + `app_shell.dart:8` currently import from `features/dashboard/widgets/dashboard_tokens.dart`).
- [ ] **P4-02** Optionally formalize as `ThemeExtension<KasyabaTokens>` for typed access; screens stop hand-painting once the shared kit lands.

## 4.2 Compliance matrix (active surfaces)

| Group | Status | Detail |
|---|---|---|
| **Compliant (keep, token consumers)** | 17 | dashboard set (screen, header, hero, quick stats, forecast card, spending card, more card, affordability card/sheet visuals, breakdown wrapper), planning, math breakdown, transactions + add-tx (+transfer wrapper), bills + add-bill, alerts, create-goal, goal_deposit sheet visuals, notification settings visuals, auth trio (own token family), accounts visuals, settings visuals, backup screen visuals, dock |
| **Partial (fix in place)** | 8 | `budgets_screen.dart` (string-typed `fontFamily` literals ~30 spots, raw `0x26F5B942`, raw SnackBars ×4, theme-default dropdown in-sheet) · `goals_screen.dart` (inline radial gradient duplicate of `canvasGradient` at `:95-105`, raw `$err` at `:197`, MaterialPageRoute) · `create_goal_screen.dart` (raw `$e` `:163`) · `goal_detail_screen.dart` (semi-themed delete dialog `:34-73`, custom apricot snackbar `:87-95`) · `kasyaba_affordability_sheet.dart` (drag handle `Colors.white@70%` `:174`, raw `0xFF101E31` `:798`) · `settings_screen.dart` (string-typed fonts throughout, raw snackbar `:636-637`) · app-level offline banner (`app.dart:51` red gradient `0xFFDC2626/0xFFB91C1C`, white text, default font) · snackbar theme duplication (`app_theme.dart:370-387`) |
| **Legacy (full restyle)** | 4 + theme | `lib/features/splash/screens/splash_screen.dart` (obsidian + emerald + Inter, flat, no glow — `:13-45`) · `lib/features/accounts/widgets/reconcile_balance_sheet.dart` (entire 830-line file on zinc/emerald/rose: `:145-210, :242-255, :270-294, :517-601, :695-731, :771-818`) · `lib/features/settings/widgets/data_backup_sheets.dart` (sky-indigo `0xFF0284C7/0xFF38BDF8`/gold/violet/orange/amber/emerald palette + `Colors.white` text + unthemed AlertDialog `:554-570`, radii 12/14/24) · release `ErrorWidget` (`lib/core/utils/error_handlers.dart:31-67`) + config-error screen (`main.dart:40-57`) + **`lib/app/theme/app_theme.dart` itself (legacy ThemeData powering MaterialApp)** |

**Material-widget airgap (new screens touching unthemed defaults):**
- `ModernBottomSheet` chrome is legacy zinc: fills `AppColors.darkCardSurface #121215`, border white-12%, handle `surface600`, text `textDark` (`lib/shared/widgets/modern_bottom_sheet.dart:59-111`) — used by the compliant dashboard (`dashboard_screen.dart:91, :1064`).
- 5 dialogs: themed-by-hand 1 (login `:83-140` ✅), semi 3 (transactions `:206-241`, goal_detail `:34-73`, router fallback `router.dart:158-161`), unthemed 1 (data_backup `:554-570`).
- 19 bottom sheets: 15 themed inline, 1 shared chrome (ModernBottomSheet, zinc), 4 legacy (data_backup ×3 + reconcile).
- **18 raw SnackBars / 10 sites** bypass the token-perfect `KasyabaToast` (`lib/shared/widgets/kasyaba_toast.dart:99-166`): budgets (`:720-721, :818-834`), settings (`:636-637`), delete-account (`:52-69`), goal_detail (`:87-95`), accounts (`:233-242, :291-293, :409-423`), data_backup (`:439-450, :475-477, :598-599, :627-628, :1404-1416, :1440-1441`).
- Date-picker theme closure duplicated **6×** (transactions `:296-309`, add-tx `:195-208`, add-bill `:80-93`, create-goal `:87-99`, bills `:65-78`, notif-settings `:33-46`), all force `Brightness.dark`.
- ListTiles inside the bigStone sheets render legacy `#FAFAFA`/Inter (`app_theme.dart:403-417`).
- **Light mode (`ThemeMode.light`) is broken by design**: `themeModeProvider` permits it (`theme_provider.dart:10-48`) but every migrated screen hardcodes `backgroundColor: DashboardTokens.ebony`; legacy surfaces flip to porcelain; date/time pickers force dark → decide (D2).

**Duplication clusters to centralize (counts from audit):** input-pill builders ×4+ (`add_transaction_screen.dart:1445-1476`, `add_bill_screen.dart:733-764` — labels 84 vs 96 inconsistent, `create_goal_screen.dart:254-298, :409-464`, `budgets_screen.dart:915-980`, `goal_deposit_sheet.dart:272-310`) · borderless-textbox Theme wrappers ×5 (`transactions:388-400`, `add_tx:642-654`, `add_bill:345-357`, `create_goal:180-192`, `goal_deposit:137-149`) · focus-pill textfields ×3 (`kasyaba_affordability_sheet.dart:233-272, :289-338, :455-511` mirroring `AuthReactiveField`) · primary pill CTA ×~12 · secondary outline pill ×6 · error-cards ×6 copies (`dashboard_screen.dart:949-1051`, `planning_screen.dart:669-711`, `alerts_screen.dart:481-547`, `budgets_screen.dart:143-205`, `goals_screen.dart:178-214`, `accounts_screen.dart:468-525`) · private `SlidingSegmentedPill` duplicates ×2 (`kasyaba_affordability_sheet.dart:609-724` — erroneously with wrong-property cast risk noted, `settings_screen.dart:122-195`) · radial-glow duplicate 1 (`goals_screen.dart:95-105`).

- [ ] **P4-10** Create the shared kit (tokens already exist; map from §4.1): `KasyabaBackground` (ebony + canvasGradient — replaces 13 identical scaffold+gradient stacks), `KasyabaCard` (standard/hero/blur variants), `PillButton` (primary/secondary/destructive), `RecessedTextField` + `LabelRowField` (one label-width constant), `AppSheet` (single bottom-sheet chrome: r32 top, poloBlue handle, ebony/bigStone surface — retires 3 architectures), `AppDialog` (bigStone r24 + poloBlue22 border + bricolage title), `EmptyState` (tokenized), `ErrorCard` (bigStone + apricot border + retry — retire 6 copies), `LoadingSkeleton` (from dashboard `:931-947`), `KasyabaDatePickerTheme` helper (retire 6 closures).
- [ ] **P4-11** Central-first ThemeData swap (no screen edits needed to uplift unthemed defaults): scaffoldBackground `ebony`; cardTheme fill `bigStone` + border `poloBlue22` + r28; inputDecorationTheme recessed-pill; filled/outlinedButton themes → pill r28; chipTheme r22; dialogTheme bigStone r24 + border; bottomSheetTheme r32 top; listTileTheme `periwinkleGray`/`periwinkleGraySubtitle` + DM Sans textTheme; drop Inter from textTheme (fontFamily = `GoogleFonts.dmSans()`); keep custom dock; snackbar content already token'd.
- [ ] **P4-12** Restyle the 4 legacy surfaces with the shared kit: splash (navy + glow + brand mark + bermuda loader), reconcile sheet (full token pass; emerald→bermuda/periwinkle, rose→apricot, zinc→ebony/bigStone, radii ≥24), data_backup_sheets (map sky→poloBlue family for info, amber→casablanca/apricot for states, white→periwinkle text; AlertDialog→AppDialog), offline banner (bigStone + apricot instead of red gradient).
- [ ] **P4-13** Micro-consistency sweep (grep-driven): `Colors.white.withValues` (`kasyaba_affordability_sheet.dart:174`), raw `0xFF101E31` (`:798`), raw `0x26F5B942` (`budgets_screen.dart:218, :524`), all string-typed `fontFamily:` literals → `GoogleFonts.*`/token TextStyles (budgets ~30, settings, accounts, notification, delete, backup), unify label width 84/96, dock radius/values, KasyabaToast adoption at the 10 raw-SnackBar sites.
- [ ] **P4-14** (D2) Theme mode: freeze `themeModeProvider` to dark + hide the settings light option until a light design exists (one-line `theme_provider.dart:20` + `settings_screen.dart:1476-1481`), or spec a light token set (out of scope by default).
- [ ] **P4-15** Add guardrail lint (or checklist item): no raw `Color(0x…)` / `Colors.*` outside `kasyaba_tokens.dart` (+ documented auth glow exception); enforce typography via tokens.
- [ ] **P4-16** Extract motion/spacing constants: extend `AppMotion` with spacing scale `{4,10,12,14,16,19,20,24}` + radius scale `{12,16,20,22,24,28,32,34,36}` and standard screen padding pattern (20 L/R + bottom 110/120 dock clearance) consumed via `KasyabaBackground`/dock.
- [ ] **P4-17** Delete legacy styling surface area with P1 deletions: legacy constant members used only by dead widgets (`AppColors.emerald500` consumers gone, `AppTheme.navbarHeight=76` vs dock 68 conflict resolve), `CategoryIconHelper.getCategoryColor` swatches (`category_icon_helper.dart:115-130`, 0 callers), `KasyabaAffordabilitySheet` static shim (`kasyaba_affordability_sheet.dart:30-32`).

---

# Phase 5: Verification & Execution Roadmap

## 5.1 Risk assessment (do-not-break list)

| # | Risk | Mitigation built into plan |
|---|---|---|
| R-01 | **`DashboardTokens` is imported by `app_theme.dart:5` + `app_shell.dart:8`** — deleting/moving the file breaks the build immediately | P4-01 creates `kasyaba_tokens.dart` first, re-points imports, only then retire `DashboardTokens` |
| R-02 | **Unused-looking providers are invalidated from the hub** (`recoveryAnalysisProvider` at `:1203`) — deleting the provider without the invalidation derails the hub; the watch-nothing provider is a safe delete only as a bundle | P1-21 bundles provider+models+invalidation line; run analyze immediately |
| R-03 | **`budgetRepositoryProvider` alias** (`:1415`) — deleting it (thinking dead) breaks 3 screens | P1-23 is rename/collapse only, via call-site update |
| R-04 | **Dead "flex_color_scheme/lucide" removals are safe; `fl_chart` is not** (chart rebuild may need it) | D5 decision before any pubspec change; table_calendar is safe |
| R-05 | **`transactionFilterProvider` wiring breaks offline merge**: pending transactions only merge into unfiltered page-1 (`api_providers.dart:823-833`) — a naive date filter silently drops queued offline entries | P2-20 includes merge extension for filtered queries + test |
| R-06 | **Notification prefs vs reminder scheduler**: `syncBillReminders` is fired on every `billsProvider` emission with hardcoded values — signature change must be atomic with prefs read, or toggles desync from scheduled OS notifications | P2-01 atomic change + `billReminderSyncProvider` update in same commit |
| R-07 | **`accountBootstrapProvider` auto-creates "Cash Wallet" (0.00) on first auth** (`api_providers.dart:145-174`) — don't conflict when adding explicit account flows or a register "step 2" | noted in P2-16 scope |
| R-08 | **`dashboardProvider` stale-cache fallback** (`:593-604`, `isFromCache:true`) — chart/forecast rebuild must keep banner-visible stale semantics, not silently mix live+cache | P2-09 keeps provider untouched; chart reads parsed field |
| R-09 | **Disabled-CTA refactor on add-tx** — switching `GestureDetector` to a real button can fire submit twice if handlers are re-registered | P2-26 guard `if (_isSubmitting) return` |
| R-10 | **`goal_deposit_sheet` fake account** — if fixed only at render (hide balance) but not submit-path, `accountId:'cash_wallet'` still 400s the server | P2-06 checks both paths; block submit on empty accounts |
| R-11 | **Shared-widget extraction (AppSheet/AppDialog) touches 15+ call sites** — re-ordering sheet internals can break `StatefulBuilder`-based sheets (bills `:101-113`, add-tx sheets) | Replace one call-site at a time; widget-test the big 3 sheets after each swap |
| R-12 | **Test file coupling**: deleting `empty_state_view.dart`/`rolling_counter.dart` breaks `screens_test.dart`/`motion_widgets_test.dart`/`motion_suite_test.dart` | Delete/remove tests in same commit (P1-10) |
| R-13 | **`SlidingSegmentedPill` private duplicates** — consolidating must preserve per-instance semantics (affordability's property mapping appeared to be a bug) | Verify behavior parity before deleting private copies |
| R-14 | **Remember-time notifications** (timezone plugin) — new prefs must serialize `TimeOfDay` & days-before consistently, else scheduled notifications drift | covered by P2-01 spec notes |
| R-15 | **`calculateDailySafeSpend` signature change** hits 4 call sites tests (`deterministic_math_test.dart:52-138`) | Update tests in same commit (P2-02) |
| R-16 | **`budgetStatusProvider` month param** (`?month=`) — subtitle wiring must pass the current month or show wrong-period data | P2-15 passes explicit month |
| R-17 | **Filtered/offline merge** (same as R-05) extended to CSV export pagination (P2-19/M-14) | Design filter+merge once in P2-20, reuse in P2-19 |

## 5.2 Decision points (need owner sign-off before the linked steps)

| ID | Decision | Links |
|---|---|---|
| D1 | Which design-token palette is canonical: implemented `KasyabaTokens` (recommended — 17 surfaces already consistent) or Figma-file hexes (re-migration) | P4-01, all of Phase 4 |
| D2 | Freeze ThemeMode to dark (recommended) vs design light tokens | P4-14 |
| D3 | Goals: adopt router routes (`/goals/new`, `/goals/:id`) (recommended) or delete routes | P1-01, P2-40 |
| D4 | Delete `/transfers/add` + `add_transfer_screen.dart` (recommended — transfer mode lives in `/transactions/add`) or wire the dock/CTA to it | P1-01 |
| D5 | Forecast chart tech: `fl_chart` (keep dependency) vs `CustomPainter` (remove dependency) | P2-09, P1-32 |
| D6 | `recoveryAnalysisProvider`: build the Alerts "recovery/health analysis" card (product value) vs delete the engine | P1-21 |
| D7 | Google Sign-In: delete `googleLogin` (aligns with stripped UI) vs restore button (aligns with original plan `plan/PLAN.md`) | P1-20 scope check |
| D8 | Add-bill "Pay from"/"Category": remove controls vs model backend fields | P2-04 |

## 5.3 Ordered execution map (sub-agent ready)

### Step A — Reconnect broken state bindings & fix unstable backend calls (Phases 2.1–2.3)

- [ ] **A-1** Land prefs/infra prerequisites first: persisted notification-prefs store + `syncBillReminders` signature (P2-01), excluded-accounts persistence + safe-spend param (P2-02) — one commit each, analyzed.
- [ ] **A-2** Fix the two BE-submitting-bad-data bugs before anything cosmetic: goal-deposit sheet (P2-06) and create-goal id-match (P2-22).
- [ ] **A-3** Mock-removal sweep M-01→M-14 in damage order (each its own commit): M-01, M-02, M-03, M-05, M-06, then M-04 chart, then the 🟡 rest (M-07…M-14).
- [ ] **A-4** Wiring items: month picker → filter (P2-20, R-05-aware), bills recurrence model (P2-13), `canAffordByTargetDate` badges (P2-14), settings truth sweep (P2-15), register copy + strength widgets (P2-16), CSV export (P2-19), control cleanups W-03…W-06 (P2-03…P2-05), structural fixes B-04…B-09 (P2-23…P2-28), disabled CTA (P2-26).
- [ ] **A-5** Async/error sweep: ErrorCard adoption at 5 swallows (P2-29), explicit error branches ≈10 sites (P2-30), `friendlyErrorMessage` at 10 sites (P2-31), silent-catch feedbacks (P2-32), skeletons (P2-33), accounts empty state (P2-34).
- [ ] **A-6** Navigation: router adoption for goals (P2-40/P1-01/P1-03), mount-guards (P2-41), edit-stub (P1-04), dock highlight (P1-02).
- [ ] **A-7** Gate: `flutter analyze` clean + full widget tests at end of Step A.

### Step B — Verify reactive state invalidation across Monitoring, Billing, Goals & Forecasting (Phase 3)

- [ ] **B-1** Build the invalidation-matrix test harness first (P3-01) so every fix below is regression-locked.
- [ ] **B-2** Apply the 8 chain fixes in dependency order: P3-05 (goal deposit→detail), P3-06 (profile→planning), P3-07 (bill paid→budgetStatus), P3-08 (bills/accounts→alerts, per policy), P3-09 (restore), P3-10 (offline partial), P3-11 (goalDetail family lifecycle), P3-12 (hub consolidation decision).
- [ ] **B-3** Formula upgrades: P3-20 (payday schedule support), P3-21 (planned-tx exclusion), P3-22 (installment cash-left), P3-23 (unified monthly need), P3-24 (formula consolidation), P3-25 (surface earliestSafeBuyDate), P3-26 (balance unification).
- [ ] **B-4** Add the missing unit tests (P3-27 list) + wire the suite into CI (P3-13). Gate: matrix test green, analysis formulas re-verified (deterministic_math suite), `flutter test`.

### Step C — Standardize design tokens & refactor all non-Figma surfaces (Phase 4)

- [ ] **C-1** D1/D2 resolved → create `kasyaba_tokens.dart` + ThemeExtension option (P4-01/P4-02), fix import direction (R-01).
- [ ] **C-2** Central ThemeData swap (P4-11) — build + run: dialogs/snackbars/listTiles/chips/date-pickers uplift with zero screen edits; verify the 3 semi/dialog states visually via golden/review.
- [ ] **C-3** Land shared kit widgets (P4-10) one by one, migrating call sites progressively (order: KasyabaBackground → PillButton → LabelRowField/RecessedTextField → AppSheet → AppDialog → ErrorCard → EmptyState → LoadingSkeleton → KasyabaToast adoption → date-picker helper). Keep every state binding intact (P2 wiring MUST NOT be regressed — run Step A/B tests).
- [ ] **C-4** Restyle the 4 legacy surfaces (P4-12): splash, reconcile_balance_sheet, data_backup_sheets (+backup AlertDialog), offline banner + release/error surfaces.
- [ ] **C-5** Micro-consistency sweep (P4-13) + motion/spacing constants (P4-16) + lint guardrail (P4-15).
- [ ] **C-6** Gate: visual review of all 27 surfaces + dialogs/sheets/toasts vs token table; analyze clean; widget tests green.

### Step D — Prune dead code LAST (Phase 1), once all active flows verified stable

- [ ] **D-1** Delete dead files (+ their tests) P1-10/P1-11; collapse duplicate safe-spend generations (P1-12) and re-check P1-12's `ModernBottomSheet` consumers (it may be fully replaced by `AppSheet` by now — retire it).
- [ ] **D-2** Delete truly-dead methods (P1-20) after D7 decision on googleLogin.
- [ ] **D-3** `recoveryAnalysisProvider` bundle-delete or card-build per D6 (P1-21); naming cleanup optional (P1-23).
- [ ] **D-4** Asset & dependency batch (P1-30/P1-31) after D5 chart decision lands (P2-09) — fl_chart keep-or-remove resolved first.
- [ ] **D-5** Final prune gate: grep for stale imports, run `flutter analyze`, `flutter test`, targeted `flutter build apk --dart-define=API_BASE_URL=...` (debug + profile release) — zero broken imports/type mismatches.

## 5.4 Static analysis & build verification (final gate)

- [ ] **V-1** `flutter analyze` — zero errors/warnings on every phase gate (commit-level, not just the end).
- [ ] **V-2** `flutter test` (unit + widget) — the new invalidation matrix, `deterministic_math` extensions, widget smoke of migrated sheets.
- [ ] **V-3** `flutter build apk --debug --dart-define=API_BASE_URL=<dev>` — verifies generated code validity post-refactor (riverpod_generator/data/related), then release variant with the full token pass.
- [ ] **V-4** Manual smoke checklist on device/emulator: offline queue reconcile → reconnect sync → dashboard refresh; deposit → goal detail immediate update; bill paid → budgets % immediate update; profile salary change → planning instant recompute; safe-spend hero → breakdown route; register new user → bootstrap wallet → first outreach states.
- [ ] **V-5** Optional guardrail in CI: lint rule banning raw `Color(0x…)`/`Colors.*` outside the tokens file (P4-15) + invalidation matrix test (P3-13).

---

### Execution-order rationale

1. **Fix data-correctness before cosmetics**: mock-money fallbacks (M-01/M-02/M-05) and bad-submit paths (R-10) are user-facing and cheap to fix; anything rebuilt in Phase C would otherwise bake in wrong data.
2. **Central-first styling** (Step C begins with tokens + ThemeData, not screen surgery) — lifts every unthemed Material surface for free and shrinks screen-level diffs.
3. **Prune last** (Step D) so nothing referenced-but-broken gets deleted mid-flight, and package removals respect the chart decision (D5).
4. Every step ends on an analyze/test gate so each phase is independently safe to stop and resume.
