# KASYABA — Light Theme Enablement + Money-Input Tappability Fix Plan

> **Date:** 2026-11-06 · **Status:** PLAN ONLY — no code written/edited (owner request).
> **Two workstreams:** (1) **P0 shippability blocker** — money/amount fields render zero-width and untappable on 4 forms; (2) **Light theme** — make `ThemeMode.light`/`system` a first-class, production-grade theme after the post-redesign dark freeze (D2).
> **Launch order:** Workstream 1 first (hotfix, blocks real usage today — cannot add a goal/deposit/expense/bill by keyboard). Workstream 2 second (theme waves), both before Play Store submit.
> **Branch:** continue on `redesign/figma-ui` (baseline branch for all executed waves), merge to `main` when green.

---

## Workstream 1 (P0): zero-width amount inputs — "can't type, just the peso sign"

### 1.1 Problem statement (user-confirmed)
On **Add Goal → Target amount**, the user sees the `₱` glyph but cannot tap or type into the field. The name field works; the amount doesn't. Root cause:

**`IntrinsicWidth` around an empty `TextField` collapses to zero width.** Flutter's `IntrinsicWidth` asks the child for its intrinsic width; an empty `EditableText` intrinsic width is ~0 (caret-only), so the field becomes a 0-px-wide column — invisible, untappable on a real device. It used to work only because a mock prefill (`'30000'`, `'5000'`) gave the field non-zero content; the stabilization pass removed mock prefills (by plan — P2-08/M-03) and exposed this 5-line latent pattern.

**Why our test gates stayed green:** widget tests use `tester.enterText()`, which writes to the controller without requiring a focusable, visible input box — so a zero-width field passes every existing suite. The plan therefore adds **render-box size + tap-focus regression tests** to close the gap.

### 1.2 Affected fields (full sweep, file:line verified today)

| # | Field | Location | Symptom when empty | Notes |
|---|---|---|---|---|
| 1 | Goal — Target amount (hero) | `lib/features/savings/screens/create_goal_screen.dart:356` (`IntrinsicWidth > TextField`, fontSize 40) | ✋ user-confirmed broken | blocks creating any goal |
| 2 | Goal deposit — amount (hero) | `lib/features/savings/widgets/goal_deposit_sheet.dart:211` | ✋ latent (prefill removed same pass) | blocks saving toward goals |
| 3 | Add transaction — amount hero | `lib/features/transactions/screens/add_transaction_screen.dart:771` (`Flexible > IntrinsicWidth > TextFormField`) | ✋ latent | blocks expense/income/transfer tracking |
| 4 | Add bill — amount | `lib/features/bills/screens/add_bill_screen.dart:422` (`Flexible > IntrinsicWidth`) | ✋ latent | blocks bills |

Reference-good pattern inside the same screens: "Already saved" field (`create_goal_screen.dart:478`, `Expanded(child: TextField)`) — tappable and fine; keep as-is.

### 1.3 Fix design (mechanical, identical at all 4 sites)
Replace the collapsing wrapper while preserving the "grows with typing" hero look:

```dart
// before (breaks when empty)
IntrinsicWidth(child: TextField(...))

// after (min floor, still grows with content)
IntrinsicWidth(
  child: ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 96), // ≈ 4 digits at hero size
    child: TextField(...),
  ),
)
```
- `ConstrainedBox` participates in intrinsic-width computation (max(minWidth, child intrinsic)), so an empty field is **96 px wide, centered, tap-and-type from the first digit**, and continues to widen as the amount grows — identical visual language, zero layout regressions in the baseline row.
- Keep `currencyAmountInputFormatter` + numeric keyboard args (verified unrelated to the defect; formatting rules stay).
- Do NOT change controllers/submit logic — inputs and validation remain as-is.

### 1.4 Verification & regression armor
- [ ] **W1-T1** New widget test `test/widget/money_input_fields_test.dart`: for each of the 4 fields → pump with overrides → `tester.tap(field)` → pump → assert `EditableText` acquiring focus AND `tester.getSize(field).width >= 96`; then `enterText('30000')` → controller text `'30000'` and formatter accepts it. (Box-size assertion is the regression armor — it would have caught this bug.)
- [ ] **W1-T2** Quick formatter sanity (existing currency formatter unit tests) — confirm unaffected.
- [ ] **W1-T3** Full gates: `flutter analyze`, full `flutter test`, `flutter build apk --debug`.
- [ ] **W1-T4** Manual device check checklist (software keyboard, GBoard): add goal → type 30000 → save; deposit → type 500 → save; add expense → type 250 → save; add bill → type 999.75 → save.

### 1.5 Acceptance
All four money fields tap-focus and accept keyboard entry from an empty state on device; full suite green; committed as a standalone hotfix commit (deployable on its own).

---

## Workstream 2 (Light theme): make `ThemeMode.light` / `system` production-grade

### 2.1 Where we are (evidence-based inventory)
- **Frozen by design (D2, executed)**: `theme_provider.dart` forces `ThemeMode.dark` and ignores saved/system; the settings theme selector was removed in the stabilization pass.
- **`ThemeData.light` is stale legacy**: `app_theme.dart` light path still builds the old zinc/obsidian system (`scaffoldBg #F8F9FA`, emerald `#10B981` accents, Inter text) — it does NOT match the new navy/periwinkle design language and must be fully rebuilt (porcelain counterpart).
- **Screens hard-paint dark tokens**: every migrated screen uses static `KasyabaTokens.*`/`DashboardTokens.*` (ebony scaffold backgrounds, initial-large grays, periwinkle texts, bigStone cards, cello60 heroes, canvasGradient glows). Static access can't respond to brightness — this is the core technical work.
- **System surfaces locked dark**: floating dock, offline banner (`app.dart`), toasts/dialogs via dark theme, `kasyaba_date_picker.dart` forces `Brightness.dark`, skeletons/empty/error/offline badges/cards, `ModernBottomSheet` remnant, adaptive sheet chrome.
- **Assets tuned for dark**: nav dock SVGs + some screen SVGs are periwinkle/light-blue fills (`app_shell.dart:97-117` etc.) — need light-mode variants or runtime `ColorFilter`; the new logo mark is multi-tone and reads fine on white tiles.
- **`flex_color_scheme`** and light-mode accent remnants were removed from pubspec earlier — no dependency available; not needed (tokens-first approach).
- **Test tooling**: `pumpScreen` harness is dark-only today; needs a `themeMode` parameter plus per-screen light parity suites.

### 2.2 Product goal
`Settings → Appearance` gains a working selector — **Dark (default) / Light / System**. Both themes are fully coherent六年级 zero legacy zinc surfaces, zero unreadable text, brand-consistent (porcelain counterpart of the navy system; logo mark works on both).

### 2.3 Decisions to lock before execution (owner)
- **D-LT1 Token strategy (recommended): semantic dual-palette class + `ThemeExtension`**
  Introduce `KasyabaColorScheme` interface exposing the ~26 semantic tokens currently in `KasyabaTokens` (ebony, bigStone, cello60, periwinkle/…, apricot, bermuda, casablanca, gradients...) with two implementations: `…Dark` (exact current values) and `…Light` (porcelain map below). Access via `context.kColors` (extension on BuildContext backed by `Theme.of(context).extension<KasyabaThemeExt>()`). Static access stays temporarily via a deprecated shim that returns the DARK instance (so the app still compiles mid-migration), with each sweep-wave replacing usages in its owned files. Alternative rejected: context-only enum-tree rewrite of 400+ call sites in one pass (too risky).
- **D-LT2 Default mode stays Dark** — selector default `Dark`, `Light` and `System` opt-in (protects existing users + screenshots); shipped setting persisted via secure storage like pre-freeze behavior.
- **D-LT3 Light palette (porcelain)** — draft semantic map (contrast-checked targets, WCAG AA for text 14px+):
  | Token | Light value (proposed) | Dark (current) |
  |---|---|---|
  | canvas/scaffold | `#F6F8FB` (porcelain-white, cool tint) | `#0A1220` |
  | card fill | `#FFFFFF` (r28 + border) | `#16293F` |
  | hero fill | `#EFF5FA` | `#1E3A56 @60%+blur` |
  | borders/dividers | `#DCE5EE` / `#E7EDF4` | `poloBlue22/30` |
  | primary text | `#0D1826` | `#C9DCEA` |
  | secondary text | `#5A6E85` | `#B4CDE0` |
  | primary button fill | `#4F7596` (kashmirBlue, white text) | `periwinkleGray` + ebony text |
  | success / warn / danger text+fill pairs | `#2E8A63` / `#B7791F` / `#C24B41` (+ 15% tints) | bermuda/casablanca/apricot |
  | glow (canvasGradient) | soft steel-blue `#9DB8D2 @35%` radial top-center | `#4F7596 @AB` |
  | dock fill/border | `#FFFFFF @92%` + `#DCE5EE` | `ebony85` + `poloBlue30` |
  Exact final values frozen in Phase LT-A with a contrast audit (label ≥ 4.5:1, chips ≥ 3:1) before screens sweep.
- **D-LT4 Asset strategy**: prefer runtime `ColorFilter.mode(lightToken)` on the existing dock/nav SVGs *if* source SVGs are single-fill (inspect `app_shell.dart` consumers during LT-C); else ship `*_light.svg` variants alongside. Logo mark asset = single asset, both modes (verified multi-tone).
- **D-LT5 Icon/launcher unaffected**: navy adaptive launcher stays (correct brand anchor in both modes).

### 2.4 Phased execution

#### Phase LT-A — Foundation (2 agents)
- [ ] **LT-A1** Token layer: `KasyabaColorScheme` interface + `dark` implementation (current values verbatim) + `light` implementation (§2.3, after contrast audit), `KasyabaThemeExt` ThemeExtension registration in both ThemeData builders, `context.kColors` extension, deprecated static shim returning dark instance; `app_theme.dart`: rebuild `AppTheme.light` porcelain (DM Sans/Bricolage typography, same text scaletreatments as dark), keep dark untouched; update `theme_provider.dart` to honor stored preference (`dark|light|system`) instead of force-dark (unlock setThemeMode per `theme_selector_test.dart` history).
- [ ] **LT-A2** Harness: `pumpScreen(... themeMode:)` in `qa_harness.dart`; ban-list test extension (`policy_copy_test.dart` pattern) — new `theme_usage_test.dart` banning `Colors.white/black/green` raw usage *outside tokens file* and (temporarily) failing screens migrated-but-hardcoded; doc `docs/theme/light-mode-tokens.md` mirroring matrix style.
- [ ] **LT-A3** Contrast audit gate for the light map (manual + programmatic luminance check inside a unit test, labels/CTA pairs listed in the doc).

#### Phase LT-B — Shared widgets (1 agent)
- [ ] Convert every shared component to `context.kColors`: `KasyabaBackground` (gradient variant per brightness), `KasyabaCard` variants, `PillButton` (light fills + disabled/danger), `AppSheet`/`showKasyabaSheet` chrome/barrier, `showKasyabaConfirmDialog`, `KasyabaEmptyState/ErrorCard/LoadingSkeleton`, `KasyabaToast`, `OfflineStatusBadge`/`NeedsInternetNotice`, `FigmaToggleSwitch`, `SlidingSegmentedPill` (+ private variants in affordability/settings), `MotionPageTransitions` overlay colors if any.

#### Phase LT-C — System surfaces (1 agent)
- [ ] `app.dart` offline banner; dock (`app_shell.dart` fills/borders/labels + SVG ColorFilter or variants); splash screen; date-picker helper (respect brightness — remove the forced dark lock); `error_handlers.dart` ErrorWidget + `main.dart` config-error screen; `modern_bottom_sheet.dart` if still referenced-deprecated.

#### Phase LT-D — Screen sweep (4 agent waves, ownership-disjoint)
- [ ] Wave 1: dashboard screen + widgets (hero/quick stats/forecast/spending/more/affordability sheet/breakdown sheet)
- [ ] Wave 2: auth trio + register extras + forgot + otp
- [ ] Wave 3: transactions screen + add-transaction +-add bill + bills screen (+ action/account/category sheets)
- [ ] Wave 4: planning + math breakdown + goals trio + deposit sheet; budgets; alerts
- [ ] Wave 5: accounts (+ reconcile sheet), settings (+ salary/privacy/about/notif settings sub-screens), backup/export + data sheets, delete-account
- Each wave: replace static token usages in its owned files with `context.kColors`, verify offline components, run full gates.

#### Phase LT-E — QA & ship gate (1 agent + device pass)
- [ ] Light parity widget smoke for all routed screens (dark + light runs, screenshot-like assertions on scaffold bg brightness + key text colors)
- [ ] Settings selector E2E-ish test (set Light → restart harness → persists; System follows platform brightness override in tests)
- [ ] Full gates + release build; device smoke checklist (images: dock, sheets, dialogs, date pickers, toasts, offline cards in both modes) → screenshots archived in `docs/theme/` for the thesis.

### 2.5 Risks & mitigations
| Risk | Mitigation |
|---|---|
| Contrast misses (periwinkle-on-white is 2.1:1 — cannot reuse text tokens) | D-LT palette freeze with unit-test luminance checks; dark/light text tokens differ by design |
| Gradient misuse on light (fixed-alpha glows overwhelm white) | dedicated light `canvasGradient`; banned static-gradient usage in screens post-sweep |
| SVG miscolor | LT-C audit + ColorFilter/variant decision before wave 1 |
| Missed dark-only hardcode | LT-A2 ban-list test + grep-driven ownership docs + final sweep audit |
| Date pickers / sheets stuck dark | converted in LT-B/LT-C with dedicated tests |
| Scope creep into re-theming dark | dark values are the `dark` implementation untouched; only additive light map |

### 2.6 Acceptance (whole workstream)
- [ ] Selector visible again in Settings; system follow tested; app restart persistence test
- [ ] Zero legacy zinc/emerald/Inter references in the light pipeline (grep gate)
- [ ] All screens fish visually in both modes (device matrix + archived screenshots); zero `Colors.*` raw uses outside tokens; full suite + release build green
- [ ] Policy copy check: does not contradict dual-theme (it doesn't mention color/theming today) ✔

---

## Execution order & shipping gates

1. **W1 hotfix (P0)** — one agent: `IntrinsicWidth` → `ConstrainedBox` at the 4 sites + `money_input_fields_test.dart` + full gates → commit as standalone hotfix (ship-safe even before light mode lands).
2. **LT-A/LT-B** foundation+shared, gated.
3. **LT-C/LT-D** system + 5 screen waves, gated.
4. **LT-E** QA + device smoke → then Play Store submission flow may proceed (with `plan.md`'s earlier deploy gates: backend deploy, keystore/AAB, Console forms).

**Out of scope for this plan:** monochrome themed-icon layer for the launcher, dynamic-color (Material You) support, tablet layouts.

**Owner to-dos during execution (non-code):** pick final porcelain accent in LT-A review (one screenshot review), device screenshots for the thesis, re-verify both modes on the physical device before sign-off.
