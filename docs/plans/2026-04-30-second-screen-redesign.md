# All car expenses — Circuit redesign

**Date:** 2026-04-30
**Screen:** Expenses tab (`All car expenses`)
**Files in scope:** `EVChargingTracker/Expenses/ExpensesView.swift`, `EVChargingTracker/Shared/FilterChip.swift`, `EVChargingTracker/ChargingSessions/SubViews/SessionCard.swift`
**Spec:** `docs/guidelines/design.md` (Circuit Design System)
**Tokens already shipping:** `Shared/AppColors.swift`, `Shared/AppCard.swift`

## Compliance scan vs. Circuit spec

| Element | Current | Spec violation |
|---|---|---|
| Nav container `ExpensesView.swift:24` | `NavigationView` | CLAUDE.md: must be `NavigationStack` |
| `CostsBlockView` | `AppCard`, `AppColors.ink/inkSoft`, eyebrow uppercase, `.monospacedDigit()` | already on-system |
| `FilterChip.swift:23` | `Color.orange` + `Color(UIColor.systemGray5)`, `cornerRadius(20)` | §6.2: pill `radius 999`, selected = `orangeSoft` bg + `orangeDeep` fg, unselected = `surfaceAlt` / `inkSoft` |
| Sort label `ExpensesView.swift:154` | `.foregroundColor(.secondary)` | §3.3: should be `AppColors.inkSoft` |
| "Swipe to edit" hint `ExpensesView.swift:218` | `.gray`, `.appFont(.caption)` | §4.3: caption color = `inkSoft` |
| Empty states `ExpensesView.swift:104,121` | `.gray` / `.gray.opacity(0.5)` | use `inkSoft` / `inkFaint` |
| `SessionCard.swift:74-81` | `cornerRadius(12)`, gray.12 fill + gray.3 stroke, raw `.yellow / .blue / .cyan / .green` | §6.1: radius **20**, `AppColors.surface` bg, no border in light, inset hairline in dark; §3.5: tokenized icon colors with soft-tint icon tile (32×32, radius 9) |
| Cost label `SessionCard.swift:42` | `.green` (raw) | §3.1: `AppColors.green` + `.monospacedDigit()` per §2 tabular numerics |
| Pagination `ExpensesView.swift:283-348` | Raw `.blue / .gray.opacity(...)`, `cornerRadius 8` | §6.3: `Btn(tinted)` (surfaceAlt) for prev/next, `Btn(ghost)` for current page, brand tokens |
| FAB `ExpensesView.swift:81-98` | `AppTheme.tabMenuTintColor` (green tab tint) | §6.9: cost-related tabs use **orange** FAB, shadow `rgba(orange, 0.45)` |
| Screen background | List default | §3.2: `AppColors.bg` (`#F2F2F7` light / `#000` dark) |
| Eyebrow over each row title | Missing on `SessionCard` | §4.3 recurring pattern: 11 / 600 / UPPERCASE / +0.3 tracking / `inkSoft` |

## ASCII — current vs. proposed

### Current

```
┌──────────────────────────────────────────────┐
│  ◀ All car expenses                          │  NavigationView (deprecated)
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ TOTAL COSTS                            │  │  AppCard / eyebrow / mono
│  │ 12 345.67 KZT                          │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ⬛All  ⬜Charging  ⬜Maintenance  ⬜Repair    │  raw .orange / systemGray5 / r20
│                                              │
│  Sort by  [ Date │ Cost │ Mileage ]          │  .secondary label
│                                              │
│  For editing or deleting, swipe left         │  .gray hint
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ⚡ 35.2 kWh                    $12.50  │  │  r=12, gray.12 fill + gray.3
│  │ 📅 2026-01-15   ⏱ 45 678 km            │  │  raw .yellow / .green
│  └────────────────────────────────────────┘  │  no eyebrow, no mono digits
│  ┌────────────────────────────────────────┐  │
│  │ 🔧 maintenance                $200.00  │  │  raw .blue
│  │ 📅 2026-01-14   ⏱ 45 600 km            │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  [◀ Previous]  [ 2 ]  [ Next ▶]              │  raw .blue / .gray, r=8
│  Total records: 42, total pages: 3           │
│                                              │
│                                  ╔══════╗    │
│                                  ║  +   ║    │  green tab-tint FAB
│                                  ╚══════╝    │  (should be ORANGE)
└──────────────────────────────────────────────┘
```

### Proposed (Circuit-conformant)

```
┌──────────────────────────────────────────────┐
│  All car expenses                            │  NavigationStack, large title
│                                              │  34 / 800 / -1, selected face
│  ┌────────────────────────────────────────┐  │
│  │ TOTAL COSTS                            │  │  AppCard r=20, eyebrow 11/600/UC
│  │ 12 345.67 KZT                          │  │  mono digits  (already correct)
│  └────────────────────────────────────────┘  │
│                                              │
│  ╭─All─╮ ╭Charging╮ ╭Maintenance╮ ╭Repair╮   │  pill r=999
│   ▲ orangeSoft bg / orangeDeep fg            │  unselected: surfaceAlt / inkSoft
│                                              │
│  Sort by  [ Date │ Cost │ Mileage ]          │  inkSoft label, stock segmented
│                                              │
│  For editing or deleting, swipe left         │  inkSoft caption
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ┌──┐ CHARGING                          │  │  AppCard r=20 surface
│  │ │⚡│  35.2 kWh             $12.50      │  │  greenSoft tile r=9, eyebrow,
│  │ └──┘                       $0.36/kWh   │  │  mono numerics, AppColors.green
│  │      🗓 2026-01-15   ⏱ 45 678 km        │  │  sub-rate 13 / inkSoft (per §6.4)
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ┌──┐ MAINTENANCE                       │  │  orangeSoft tile, wrench glyph
│  │ │🔧│  Wheel alignment      $200.00     │  │
│  │ └──┘                                   │  │
│  │      🗓 2026-01-14   ⏱ 45 600 km        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│   ◁ Previous     [ 2 ]     Next ▷            │  Btn(tinted) prev/next,
│   Total records: 42  ·  3 pages              │  Btn(ghost blue) page badge
│                                              │
│                                  ╔══════╗    │
│                                  ║  +   ║    │  FAB orange (§6.9 cost tab)
│                                  ╚══════╝    │  shadow rgba(orange, 0.45)
└──────────────────────────────────────────────┘
Background: AppColors.bg  (#F2F2F7 light / #000 dark)
```

## Plan

### Will change

1. **Nav + screen chrome** — `ExpensesView.swift:24`: replace `NavigationView` with `NavigationStack`; set `AppColors.bg` behind the `List` (large-title style, per §6.7).
2. **`FilterChip.swift`** — pill radius 999; selected = `AppColors.orangeSoft` bg + `orangeDeep` fg; unselected = `surfaceAlt` + `inkSoft`. Keep API surface identical so call sites don't change.
3. **`SessionCard.swift`** — wrap content in `AppCard` (radius 20, surface, dark inset hairline auto-handled); add 32×32 r=9 icon tile with soft brand / system tint; add **uppercase eyebrow** with type label; switch raw colors to `AppColors.green / yellow / blue / teal / red`; apply `.monospacedDigit()` on cost / kWh / odometer; use `AppColors.green` for cost; right-side adds `$/kWh` sub-rate when applicable (charging only).
4. **In-list ancillary text** in `ExpensesView.swift` — sort label, swipe-hint, empty states: swap `.gray` / `.secondary` / `.opacity(...)` for `AppColors.inkSoft` / `inkFaint`; replace `.appFont(.caption)` hint weight per §4.3 where appropriate.
5. **Pagination + FAB** — pagination becomes `Btn(tinted)` / `Btn(ghost)` style with brand tokens and mono digits in the page badge; FAB switches to `AppColors.orange` background with `rgba(orange, 0.45)` shadow per §6.9 (cost-related tab).

### Will NOT change

- `ExpensesViewModel` (filter / sort / pagination logic, repository access, analytics events).
- `AddExpenseView` sheet content or its presentation flow.
- `CostsBlockView` — already conforms.
- Localization keys / strings (only adopt existing ones via `L()`).
- Database access, migrations, App Group / entitlement config.
- Any tab-bar / `MainTabView` wiring (only the per-screen FAB color changes).

## Verification

- `./run_tests.sh` — full suite must pass (CLAUDE.md rule).
- `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` — clean build.
- Manual smoke in simulator: filter chips toggle, sort changes, pagination prev / next, swipe-to-delete / edit, FAB opens AddExpense sheet, light + dark mode parity.
