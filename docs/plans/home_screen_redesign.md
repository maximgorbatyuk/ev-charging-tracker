# Home Screen Redesign — Apply Design System to `ChargingSessionsView`

Implementation plan for reskinning the Stats tab (the app's "home" screen) to the design system in `EVChargingTracker/docs/guidelines/design.md`.

---

## Target file

`EVChargingTracker/EVChargingTracker/ChargingSessions/ChargingSessionsView.swift` plus the sub-views it composes:

- `StatsBlockView` — 3-up KPI row (CO₂, kWh/100km, Charges)
- `CostsBlockView` — total spend hero card
- `ChargingConsumptionLineChart` — line + area chart
- `ExpensesChartView` — stacked bar chart by expense type
- The existing "Add Charging Session" CTA

The tab container (`MainTabView`) is **not** in scope — design doc §6.10 mandates stock SwiftUI `TabView`.

---

## Target visual (ASCII reference)

```
┌──────────────────────────────────────────────────────────────┐
│ 9:41                                     ▪︎  ◢  ▮▮▮▮  ◔     │  ← status bar
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Stats                                                       │  ← large title · 34/800/-1 · Display face
│                                                              │
│  ╭────────────────╮ ╭────────────────╮ ╭────────────────╮    │
│  │ CO₂ SAVED      │ │ KWH / 100KM    │ │ CHARGES        │    │  ← eyebrow · 11/600/0.3 · UPPERCASE · inkSoft
│  │                │ │                │ │                │    │
│  │ 184 lb         │ │ 18.4 kWh       │ │ 47             │    │  ← KPI value · Mono 22/700
│  │                │ │                │ │ this month     │    │  ← caption · 11 · inkSoft
│  ╰────────────────╯ ╰────────────────╯ ╰────────────────╯    │
│                                                              │
│  ╭──────────────────────────────────────────────────────╮    │
│  │ TOTAL SPEND                                          │    │
│  │                                                      │    │
│  │ $47.32                            ╭─────────────╮    │    │
│  │                                   │ ↓ -$6 / mo  │    │    │  ← Chip(green) sm
│  ╰──────────────────────────────────────────────────────╯    │     Hero stat · Mono 38/700/-1.4
│                                                              │
│  ╭──────────────────────────────────────────────────────╮    │
│  │            ┃+┃   Add Charging Session                │    │  ← Btn(accent) · lg · 52pt · radius 14
│  ╰──────────────────────────────────────────────────────╯    │     bg orange · fg #fff · UI 17/600
│                                                              │
│  CONSUMPTION · 30 DAYS                                       │  ← SectionHeader
│  ╭──────────────────────────────────────────────────────╮    │
│  │      ╱╲                                              │    │
│  │     ╱  ╲      ╱╲                                     │    │
│  │  ╱╲╱    ╲╱╲╱╱  ╲╱╲    ╱╲                             │    │  ← line · stroke 2.2 · orange
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                       │    │  ← area gradient · orange@0.28 → 0
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                       │    │
│  │ ─────────────────────────────────                    │    │
│  │  Mar 24    Apr 1     Apr 8    Apr 15                 │    │
│  ╰──────────────────────────────────────────────────────╯    │
│                                                              │
│  EXPENSES BY TYPE                                            │  ← SectionHeader
│  ╭──────────────────────────────────────────────────────╮    │
│  │  Mar  ████████████████▓▓▓▓▓▓░░░░──                   │    │  ← stacked bar · category colors
│  │  Feb  ██████████████▓▓▓▓░░──                         │    │
│  │  Jan  ████████████████████▓▓▓▓░░░░────               │    │
│  │                                                      │    │
│  │  ● green Charging   ● orange Maint   ● red Repair    │    │  ← Row-style legend
│  │  ● blue Carwash     ● gray Other                     │    │
│  ╰──────────────────────────────────────────────────────╯    │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│      ⚡           $           🚗            ⚙               │  ← stock TabView · tint green
│     Stats      Expenses      Car         Settings            │
│     ▔▔▔▔▔                                                    │
└──────────────────────────────────────────────────────────────┘
```

---

## Naming convention

New primitives match the existing `App*` namespace in `EVChargingTracker/Shared/` (`AppFont`, `AppTheme`, `AppImageBackground`). No design-system codename in type names — just `AppColors`, `AppCard`, `AppChip`, `AppButton`, `AppSectionHeader`.

---

## Token map (design.md → screen)

| Element | Tokens applied | Source |
|---|---|---|
| Canvas | `bg` `#F2F2F7` (light) / `#000` (dark) | §3.2 |
| All cards | `surface` bg · `cardRadius` 20 · pad 14–16 · light shadow `0 0.5px 0 rgba(0,0,0,.04)` | §3.2, §5.1, §5.3 |
| "Stats" title | Display face · 34pt / 800 / -1 letter-spacing | §4.2 hero row |
| KPI eyebrows ("CO₂ SAVED", "TOTAL SPEND") | UI face · 11/600/0.3 · UPPERCASE · `inkSoft` | §4.3 eyebrow pattern |
| KPI numeric values (`184`, `18.4`, `47`, `$47.32`) | **JetBrains Mono** unconditional · 22/700 (KPI) or 38/700 (hero) | §4.1 numerics rule, §4.2 |
| Section headers ("CONSUMPTION · 30 DAYS", "EXPENSES BY TYPE") | UI face · 13/600/0.3 · UPPERCASE · `inkSoft` · 18pt above / 6pt below | §6.6 |
| Delta chip (`↓ -$6 / mo`) | Chip md `green` tint · `greenSoft` bg · `greenDeep` fg | §6.2 |
| Consumption line + area | Stroke 2.2 · gradient `orange @ 0.28 → 0` (cost metric → orange per principle) | §7.1 |
| Stacked bar | Categories: `green` charging · `orange` maintenance · `red` repair · `blue` carwash · `gray` other | §7.2 stacked variant |
| Bar legend | `Row`-style entries · 10×10 radius-3 color dots · 11pt `inkSoft` | §7.2, §6.4 |
| "Add Charging Session" button | `AppButton(.accent, .lg)` · `orange` bg · `#fff` fg · radius 14 · 52pt · UI 17/600 | §6.3 |
| Tab bar | Stock SwiftUI `TabView` · tint `green` on selected · labels 10.5/600 | §6.10 |

---

## Implementation — split into 3 sequential PRs

Each PR lands reviewable and reversible. Don't bundle.

### PR 1 — Foundational primitives (no screen changes)

Add the design-system primitives so subsequent PRs have something to call into. Files go directly in `EVChargingTracker/Shared/` (flat — matches the existing layout next to `AppFont.swift`, `AppTheme.swift`).

- `AppColors.swift` — `AppColors` enum from design.md §3.6 (brand, surfaces, ink, system pops, dynamic-color helpers).
- `AppCard.swift` — wrapper with `surface` bg, radius 20, pad, light-mode shadow, dark-mode no-shadow. Supports `pad: 0` variant for charts that bleed to the card edges.
- `AppChip.swift` — `Tint` enum (green/orange/blue/red/gray/ink), `Size` enum (sm/md), pill shape per §6.2.
- `AppButton.swift` — `Kind` enum (primary/green/accent/surface/tinted/ghost/outlined), `Size` enum (lg/md/sm) per §6.3.
- `AppSectionHeader.swift` — uppercase eyebrow + optional `action` slot + optional badge slot per §6.6.
- `AppFont.swift` — add `mono(size:weight:)` helper that returns `Font.custom("JetBrainsMono-…", size:)` regardless of the user's selected `AppFontFamily`. Required because the design doc mandates JetBrains Mono for all numerics independent of the picker.
- **No existing screen file touched.**

### PR 2 — Reorder + reskin `ChargingSessionsView` layout

- **Reorder** the VStack to: `StatsBlockView` → `CostsBlockView` → `Add Charging Session` button → `ChargingConsumptionLineChart` → `ExpensesChartView`.
- Replace solid blue `ZStack` background with `AppColors.bg`.
- Replace existing "Add Charging Session" gradient button with `AppButton(.accent, size: .lg, fullWidth: true)` — flat orange, radius 14, 52pt.
- Wrap each chart in an `AppSectionHeader` ("CONSUMPTION · 30 DAYS", "EXPENSES BY TYPE") above an `AppCard(pad: 0)`.
- Reskin `StatsBlockView`: 3-up grid, each cell wrapped in `AppCard(pad: 14)`, eyebrow above value (uppercase via `.textCase(.uppercase)` on existing localized labels — no new L() keys), JetBrains Mono value below.
- Reskin `CostsBlockView`: single `AppCard`, eyebrow `TOTAL SPEND` (uppercase via `.textCase(.uppercase)` on the existing localized title), hero number in JetBrains Mono 28–38/700. Skip the cost-delta chip in this PR (see open Q3).
- Run `./run_tests.sh` — visuals only, no semantics changed; existing tests should pass.

### PR 3 — Reskin charts (highest visual risk, isolated last)

- `ChargingConsumptionLineChart`:
  - Line color → `AppColors.orange`, stroke 2.2.
  - Area fill → `LinearGradient(colors: [.orange.opacity(0.28), .orange.opacity(0)], startPoint: .top, endPoint: .bottom)`.
  - Drop axis gridlines.
  - Axis label color → `AppColors.inkSoft`.
- `ExpensesChartView`:
  - Re-assign category colors per design doc §7.2: `charging=green`, `maintenance=orange`, `repair=red`, `carwash=blue`, `other=gray` (current code uses yellow/green/orange/blue/purple — needs remapping).
  - Move legend out of chart frame into a `Row`-style list below using `AppColors` dots (10×10, radius 3) + 11pt `inkSoft` labels.
- Verify in light + dark mode and across all 7 supported languages (English, German, Russian, Turkish, Kazakh, Ukrainian, Simplified Chinese).

---

## What will NOT change

- `MainTabView` or the tab bar — design doc §6.10 says use stock `TabView`. Tint stays via existing `AppTheme.tabMenuTintColor()` (or update it to `AppColors.green` if not already).
- Pull-to-refresh, empty state, navigation behavior — unaffected.
- Other tabs (Expenses / Car / Settings) — separate work, not in scope here.
- `AppFontFamily` / font picker plumbing — already aligned with design doc; only adds the `mono(...)` helper.
- Any data layer, ViewModel logic, or analytics events.
- Localization files — reuse existing keys; eyebrows use `.textCase(.uppercase)` instead of new uppercase-variant strings.

---

## Open questions before starting

1. **Stats tab title text** — current source uses `L("Car stats")`; design mock shows "Stats". Plan defaults to keeping `L("Car stats")` (no new localization). Override if you want it changed.
2. **Eyebrow labels for KPI cards** — plan uses `.textCase(.uppercase)` on the existing localized labels (e.g. "CO₂ saved (kg)" → "CO₂ SAVED (KG)"). If you want bespoke uppercase strings in all 7 `.lproj` files instead, say so before PR 2.
3. **Cost delta chip** (`↓ -$6 / mo`) — `CostsBlockView` does not currently compute month-over-month delta. Plan defers the chip to a follow-up PR so PR 2 stays visual-only. Override if the chip should ship in PR 2 (would require new aggregation logic in `ChargingViewModel`).
