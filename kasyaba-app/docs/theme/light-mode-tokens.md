# Light mode tokens — Phase LT-A foundation

> Source of truth: `lib/app/theme/kasyaba_color_scheme.dart`.
> Plan: `plan/LIGHT_MODE_AND_GOAL_INPUT_PLAN.md` §2.3/§2.4.
> Dark remains the default appearance (D-LT2); light/system are opt-in via
> **Settings → Appearance**.

## Semantic palette

Dark values are the pre-existing `KasyabaTokens` navy values verbatim, so the
frozen dark redesign is visually unchanged. Light values are the locked
porcelain palette. Contrast numbers below are measured with the WCAG 2.1
relative-luminance formula against `canvas` unless noted.

| Semantic token | Dark (current) | Light (porcelain) | Usage / contrast |
|---|---|---|---|
| `canvas` | `#0A1220` (ebony) | `#F6F8FB` | Scaffold / page base. |
| `backgroundGradient` | `canvasGradient` (`#4F7596 @AB → @00`, radial 0.8,-1.0, r1.4) | `#9DB8D2 @35% → @00`, radial 0.8,-1.0, r1.4 | Ambient top-right glow. |
| `card` | `#16293F` (bigStone) | `#FFFFFF` | Standard card / sheet surfaces. |
| `cardHero` | `#1E3A56 @60%` (cello60) | `#EFF5FA` | Hero / profile cards. |
| `cardBorder` | `#8FB2CE @22%` | `#DCE5EE` | Card + input hairlines (non-text, 1.20:1). |
| `cardBorderStrong` | `#8FB2CE @30%` | `#C6D4E3` | Emphasised card outlines. |
| `divider` | `#8FB2CE @16%` | `#E7EDF4` | Separators (non-text, 1.11:1). |
| `textPrimary` | `#C9DCEA` | `#0D1826` | Titles/body. Dark 13.31:1, light 16.79:1. |
| `textSecondary` | `#B4CDE0` | `#5A6E85` | Subtitles/body. Dark 11.38:1, light 4.93:1. |
| `textMuted` | `#8E97B6` (baliHai) | `#7C8FA3` | Hints/meta labels. Light 3.13:1 (large/non-essential text only). |
| `icon` | `#8FB2CE` (poloBlue) | `#6B8299` | Decorative icons. |
| `primaryButton` | `#C9DCEA` | `#4F7596` | Primary CTA fill. |
| `onPrimaryButton` | `#0A1220` | `#FFFFFF` | CTA label. Dark 13.31:1, light 4.86:1. |
| `secondaryBorder` | `#4F7596` (kashmirBlue) | `#4F7596` | Secondary CTA outline (light 4.57:1). |
| `success` | `#7FD8B5` (bermuda) | `#1F7A54` | Positive status. Dark 11.06:1; light 4.97:1. |
| `successTint` | `#7FD8B5 @15%` | `#1F7A54 @14%` | Positive badge fill. |
| `warning` | `#F5B942` (casablanca) | `#8A5A16` | Warning status. Dark 10.62:1; light 5.55:1. |
| `warningTint` | `#F5B942 @15%` | `#8A5A16 @14%` | Warning badge fill. |
| `danger` | `#F2928A` (apricot) | `#B03A32` | Destructive/error. Dark 8.26:1, light ≥4.5:1 (canvas and 14% tint). |
| `dangerTint` | `#F2928A @15%` | `#B03A32 @14%` | Destructive badge fill. |
| `accentViolet` | `#6E5BFF` (cornflowerBlue) | `#6E5BFF` | Forecast/chart accent. |
| `accentTeal` | `#19C3B4` (java) | `#138D82` | Secondary data accent. |
| `dockFill` | `#0A1220 @85%` (ebony85) | `#FFFFFF @92%` | Floating dock fill. |
| `dockBorder` | `#8FB2CE @30%` | `#DCE5EE` | Floating dock border. |
| `inputFill` | `#16293F` | `#F1F5F9` | Text-field fill. |
| `inputBorder` | `#8FB2CE @22%` | `#DCE5EE` | Text-field outline. |
| `skeletonFill` | `#16293F @50%` | `#E9EFF6 @50%` | Loading skeleton blocks. |
| `scrim` | `#000000 @72%` | `#000000 @72%` | Modal/sheet barrier. |
| `shadow` | `#000000` | `#0D1826 @8%` | Elevation shadow tint. |

### Contrast audit (LT-A3 gate)

`test/unit/theme_contrast_test.dart` enforces:

- `textPrimary` on `canvas` ≥ 7:1 (both palettes: dark 13.31, light 16.79).
- `textSecondary` on `canvas` ≥ 4.5:1 (dark 11.38, light 4.93).
- `onPrimaryButton` vs `primaryButton` ≥ 4.5:1 (dark 13.31, light 4.86).
- `danger` on `canvas` ≥ 4.5:1 (dark 8.26, light 4.51).
- `success`/`warning` on `canvas` ≥ 4.5:1 (dark 11.06 / 10.62, light
  4.97 / 5.55).

**LT-B palette revision:** the locked light `success` (`#2E8A63`, 4.00:1) and
`warning` (`#B7791F`, 3.42:1) did not reach 4.5:1 on `#F6F8FB`. Phase LT-B
darkened them to `#1F7A54` (4.97:1) and `#8A5A16` (5.55:1); both tints are 14%
of the new base (`0x24…`). Dark values are unchanged, and the unit gate now
asserts ≥ 4.5:1 for both palettes.

## Access API

```dart
import 'package:kasyaba/app/theme/kasyaba_color_scheme.dart';

// Inside any widget build:
final colors = context.kColors; // KasyabaColorScheme
Container(color: colors.card);
```

- `KasyabaColorScheme` — abstract semantic getters.
- `KasyabaColorsDark` / `KasyabaColorsLight` — palette implementations.
- `kasyabaDarkColors` / `kasyabaLightColors` — top-level const instances.
- `KasyabaThemeExt(colors: …)` — `ThemeExtension` registered in both
  `AppTheme.dark` and `AppTheme.light` (`Theme.of(context).extension`).
- `context.kColors` — falls back to the dark palette when no extension is
  registered, keeping non-themed widget tests safe.

## Migration guide for later waves (LT-B … LT-D)

Replace static token reads with semantic lookups. Mapping:

| Static token usage | Replace with |
|---|---|
| `KasyabaTokens.ebony`, `DashboardTokens.ebony` (scaffold) | `context.kColors.canvas` |
| `KasyabaTokens.canvasGradient` | `context.kColors.backgroundGradient` |
| `KasyabaTokens.bigStone` (card) | `context.kColors.card` |
| `KasyabaTokens.bigStone` (field fill) | `context.kColors.inputFill` |
| `KasyabaTokens.cello60` | `context.kColors.cardHero` |
| `poloBlue22` | `cardBorder` (cards/fields) |
| `poloBlue30` | `cardBorderStrong` (emphasis) or `dockBorder` (dock) |
| `poloBlue16` | `divider` |
| `periwinkleGray` (text) | `textPrimary` |
| `periwinkleGraySubtitle` (text) | `textSecondary` |
| `baliHai` | `textMuted` |
| `poloBlue` (icon stroke) | `icon` |
| `periwinkleGray` (CTA fill) | `primaryButton` |
| `ebony` (on CTA) | `onPrimaryButton` |
| `kashmirBlue` (outline/glow border) | `secondaryBorder` |
| `bermuda` / `bermuda15` | `success` / `successTint` |
| `casablanca` / `casablanca15` | `warning` / `warningTint` |
| `apricot` / `apricot15` | `danger` / `dangerTint` |
| `cornflowerBlue` | `accentViolet` |
| `java` | `accentTeal` |
| `ebony85` (dock) | `dockFill` |
| `Colors.black.withValues(alpha: .72)` (barrier) | `scrim` |
| `Colors.black` (shadow) | `shadow` |

Rules:

1. Never branch on `Theme.of(context).brightness` to pick palette colors; read
   `context.kColors` instead.
2. Do not hand-write `Colors.white` / `Colors.black` / raw hex in screens.
3. Sheets/dialogs opened from a converted screen use the same `context.kColors`
   palette, not the legacy static tokens.
4. Keep sizing tokens (`KasyabaTokens.radius*`, `dockClearance`) as-is.

## Current state / rollout

- **LT-A (foundation):** palette, `ThemeExtension`, `context.kColors`,
  porcelain `AppTheme.light`, persisted theme mode, harness support, contrast
  gate. Dark visuals are untouched.
- **LT-B (this phase):** shared widgets (background, cards, pill buttons, sheet
  chrome, dialogs, empty/error/skeleton states, toasts, offline notices, toggle,
  segmented pill) now resolve `context.kColors`; dark visuals stay identical.
  Light success/warning were darkened for WCAG AA (see audit above).
  `AppSheet` still honors explicit `color:` overrides from un-migrated screens.
- **LT-C:** system surfaces (dock, offline banner, splash, date picker) are
  converted in their own wave.
- **LT-D:** screens convert their owned files to `context.kColors` wave by wave.
  Expect dark tiles/screens to remain while waves are in flight, especially when
  the user selects Light.

## Rollout verification (Phase LT-E)

> Completed 2026-11-08. Gates: `flutter analyze` clean, full `flutter test`
> **367 passed / 0 failed / 0 skipped**, `flutter build apk --debug` succeeded
> (`build/app/outputs/flutter-apk/app-debug.apk`).

### Light/dark parity coverage

`test/widget/light_theme_parity_test.dart` pumps each routed screen **twice**
(`ThemeMode.dark` and `ThemeMode.light`) through `QaHarness.pumpScreen` with
`qaDefaultDataOverrides()`; screen-specific overrides mirror
`qa_screens_smoke_test.dart`. Every run asserts:

1. no `tester.takeException()` (layout overflow / build crash),
2. `Theme.of(tester.element(Scaffold)).brightness` matches the pumped mode,
3. the first `Scaffold` and at least one rendered `Material` paint the palette
   canvas — `#0A1220` in dark, `#F6F8FB` in light.

Splash / Login / Register use fixed pumps because their indeterminate
animations never reach `pumpAndSettle`.

| Screen | Dark | Light |
|---|:--:|:--:|
| `SplashScreen` | ✔ | ✔ |
| `LoginScreen` | ✔ | ✔ |
| `RegisterScreen` | ✔ | ✔ |
| `ForgotPasswordScreen` | ✔ | ✔ |
| `DashboardScreen` | ✔ | ✔ |
| `PlanningScreen` | ✔ | ✔ |
| `TransactionsScreen` | ✔ | ✔ |
| `BillsScreen` | ✔ | ✔ |
| `GoalsScreen` | ✔ | ✔ |
| `BudgetsScreen` | ✔ | ✔ |
| `AlertsScreen` | ✔ | ✔ |
| `SettingsScreen` | ✔ | ✔ |
| `AccountsScreen` | ✔ | ✔ |
| `NotificationSettingsScreen` | ✔ | ✔ |
| `BackupExportScreen` | ✔ | ✔ |
| `DeleteAccountScreen` | ✔ | ✔ |
| `PrivacyAndAboutScreen` | ✔ | ✔ |
| `MathBreakdownScreen` | ✔ | ✔ |
| `AddTransactionScreen` | ✔ | ✔ |
| `AddBillScreen` | ✔ | ✔ |
| `CreateGoalScreen` | ✔ | ✔ |
| `GoalDetailScreen` | ✔ | ✔ |

### Contrast results (LT-A3 / LT-B gate)

`test/unit/theme_contrast_test.dart` still enforces these on the canvas
(dark / light):

| Pair | Threshold | Result |
|---|---|---|
| `textPrimary` on `canvas` | ≥ 7:1 | 13.31 / 16.79 |
| `textSecondary` on `canvas` | ≥ 4.5:1 | 11.38 / 4.93 |
| `onPrimaryButton` on `primaryButton` | ≥ 4.5:1 | 13.31 / 4.86 |
| `danger` on `canvas` | ≥ 4.5:1 | 8.26 / 4.51 |
| `success` on `canvas` | ≥ 4.5:1 | 11.06 / 4.97 |
| `warning` on `canvas` | ≥ 4.5:1 | 10.62 / 5.55 |

### Usage gate

`test/unit/theme_usage_test.dart` scans `lib/features/**`, `lib/shared/**`, and
`lib/app/router/**` (comments stripped with line/column preservation) and fails
on any:

- raw `Colors.white|black|red|amber|blue|green|grey|orange|purple`,
- raw `Color(0x…)` literal,

- static color-token read (`KasyabaTokens.<color>`,
  `DashboardTokens.<color>`, including `canvasGradient`).

Allowlisted: `app/theme/kasyaba_tokens.dart`,
`app/theme/kasyaba_color_scheme.dart`, `app/theme/app_theme.dart`, and the
`dashboard_tokens.dart` adapter. `auth_widgets.dart` has line-exact exceptions
for the four `AuthFigmaTokens` dark gradient recipes and
`Colors.grey.shade600` (legacy dark placeholder; light already uses
`textMuted`). The test also asserts every migrated screen, shared widget, and
system surface reads `context.kColors`, and that sizing tokens
(`radiusCard`, `dockClearance`, …) remain legal.

### Persistence and selector

- `test/unit/theme_persistence_test.dart` (7 tests): default is
  `ThemeMode.dark`; `light`/`system`/`dark` persist as the canonical strings;
  a fresh `ThemeModeNotifier` over the same storage hydrates the saved mode
  (restart simulation); unknown values fall back to dark; `themeModeProvider`
  hydrates through a `secureStorageProvider` override.
- `test/widget/theme_selector_test.dart` also asserts the Appearance row
  subtitle updates (`Dark` → `Light` → `System (follow device)`) alongside the
  provider value and secure-storage write.

### Known deliberate dark micro-deltas

These are intentional and visually reviewed during LT-C/LT-D:

- **Dashboard safe-spend subtitle:** `DashboardTokens.cello` (solid `#1E3A56`)
  → `colors.cardHero` (dark = `cello60`). Semantic consolidation with the hero
  surface; slightly translucent in dark.
- **Planning assumptions label:** `DashboardTokens.zircon` (`#F1F4FF`) →
  `context.kColors.textPrimary` (`#C9DCEA`). Restores text hierarchy; there is
  no semantic zircon token.
- **Nav dock unselected SVG tint:** `periwinkleGraySubtitle` (`#B4CDE0`) →
  `colors.icon` (`#8FB2CE`) via runtime `ColorFilter`. Necessary for the light
  dock; the dark icon is marginally deeper.
- **Auth input placeholder (dark):** `Colors.grey.shade600` remains as the
  documented legacy exception; light mode already uses `textMuted`.

### Destructive-button contrast — RESOLVED (light danger #B03A32, AA-locked)

`PillButtonVariant.destructive` renders `danger` text on a `dangerTint` fill;
over the light canvas that pair measures **≈ 3.96:1**, below the WCAG AA 4.5:1
threshold for small text. This does not block LT-E (the action also carries an
icon/label and is not the sole affordance), was resolved by darkening the light `danger` to `#B03A32` (tint `#B03A32 @14%`); locked by `theme_contrast_test.dart`:
darken the light `danger` slightly, raise the tint opacity, or use
`textPrimary` for the destructive label after a visual review.
