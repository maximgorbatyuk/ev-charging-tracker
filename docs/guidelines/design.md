# Circuit Design System — EV Charging Tracker

Visual-language spec for the EV Charging Tracker iOS app: tokens, typography, spacing, components, motion, and light/dark rules. **This doc defines _how_ things should look — not _which_ screens should exist.** Screen composition stays in feature code.

---

## 1. Source of truth

- **Reference prototype:** generated via Claude Design (claude.ai/design), unpacked locally to `/tmp/design_bundle/app-onboarding/`. Primary file: `project/Circuit EV v4.html`. Use as visual reference only — not every prototype screen maps to a real app screen.
- **Tokens reference:** `project/circuit/tokens.jsx` (colors, typography primitives, `Card` / `Chip` / `Btn` / `StatusBar`).
- **Widget reference:** `project/circuit/widgets.jsx` (`NavBar`, `CircleBtn`, `Row`, `SectionHeader`, `BarChart`, `Segmented`, etc.).
- **Design intent:** the chat transcript at `chats/chat1.md` documents the user's direction — _"Clean & minimal (Apple-native feel) + eco-inspired … Space Grotesk for display, Inter/JetBrains Mono for body"_. Three variations were explored (Forest / Circuit / Voltage); **Circuit** — the Apple-native clean/minimal one — is the approved direction captured here.

When this guideline conflicts with what you see in the prototype, the prototype source wins for _visual language_; this doc wins for _what the app actually ships_.

---

## 2. Design principles

- **Apple-native grammar.** iOS grouped backgrounds, sheet grab handles, large-title nav, stock `TabView`, haptic-ready buttons. Nothing that reads as "web" or "Material".
- **Green = energy.** Brand greens own all "energy / eco / healthy / reward" signals: positive deltas, savings, efficiency chips, CO₂ impact, primary confirmatory CTAs.
- **Orange = action/cost accent.** Cost emphases, scheduled/due chips, primary FAB on cost-related tabs. Orange is reserved — if everything is orange, nothing is.
- **Tabular numerics.** Every numeric value (kWh, $, %, mi/km, duration, dates) renders in the user's selected display face with `.monospacedDigit()` applied — so digit columns line up cleanly across families (System swaps to SF Pro's tabular figures; JetBrains Mono is already monospaced; Space Grotesk uses its tabular-figures feature). The point is column alignment, not literal monospace; the family follows the user's choice. **JetBrains Mono is the app default**; iOS system and (once bundled) Space Grotesk are alternatives — see §4.1.
- **Dark mode is a mirror, not a re-skin.** Canvas goes true black, surfaces climb to `#1C1C1E`/`#2C2C2E`. Drop shadows are replaced by inset 1px white-alpha hairlines. Brand greens stay the same values; their _soft_ variants switch to `rgba(brand, 0.16)`.
- **Charts are flat and quiet.** Thin strokes, gradient fills that fade to zero. Stacked-bar series use brand + system pops — no axis grids inside the chart, legends live below.

---

## 3. Color tokens

All values are taken verbatim from `tokens.jsx` → `buildPalette(tweaks)`.

### 3.1 Brand

| Token | Light | Dark | Use |
|---|---|---|---|
| `green` | `#0FA968` | `#0FA968` | Primary brand, positive deltas, primary confirm CTAs |
| `greenDeep` | `#0A7A4B` | `#0A7A4B` | Chip text on `greenSoft`, emphasized savings copy |
| `greenSoft` | `#E3F5EC` | `rgba(15,169,104,0.16)` | Chip background, row icon tile background |
| `greenLeaf` | `#4CC388` | `#4CC388` | Illustrations / decorative leaf motifs |
| `orange` | `oklch(0.72 0.18 28)` | same | Accent CTA, scheduled/due chips, cost emphases |
| `orangeDeep` | `oklch(0.62 0.19 28)` | same | Chip text on `orangeSoft` |
| `orangeSoft` | `oklch(0.94 0.06 28)` | `oklch(0.32 0.09 28 / 0.35)` | Chip background, row icon tile background |

**On orange & oklch:** the tweakable hue knob defaults to `28°`. In sRGB this approximates `#FF8A4D` (`orange`) / `#E5641F` (`orangeDeep`) / `#FCE5D4` (`orangeSoft` light). SwiftUI can render oklch via `Color(.displayP3, red:green:blue:opacity:)` with the converted coordinates; for back-compat, use the sRGB approximations above. If the orange-hue tweak ever becomes a user setting, re-derive via oklch → sRGB at runtime rather than shipping fixed hex.

### 3.2 Surfaces — iOS grouped vocabulary

| Token | Light | Dark | Notes |
|---|---|---|---|
| `bg` | `#F2F2F7` | `#000000` | Canvas / grouped table background |
| `surface` | `#FFFFFF` | `#1C1C1E` | Card / cell background |
| `surfaceAlt` | `#ECEAEF` | `#2C2C2E` | Tinted button, segmented track, neutral icon tile, info callout |
| `surfaceHigh` | `#FFFFFF` | `#2C2C2E` | Elevated surface (sheets, pinned headers) |

### 3.3 Ink hierarchy (4 levels)

| Token | Light | Dark | Use |
|---|---|---|---|
| `ink` | `#000000` | `#FFFFFF` | Primary text, primary button bg |
| `inkSoft` | `rgba(60,60,67,0.62)` | `rgba(235,235,245,0.62)` | Secondary labels, section sub-captions, units next to numbers |
| `inkFaint` | `rgba(60,60,67,0.32)` | `rgba(235,235,245,0.32)` | Placeholder digits (`$__.__`), inactive glyphs |
| `inkGhost` | `rgba(60,60,67,0.14)` | `rgba(235,235,245,0.16)` | Sheet grab handle, icon tile bg on neutral rows |

### 3.4 Dividers

| Token | Light | Dark | Use |
|---|---|---|---|
| `divider` | `rgba(60,60,67,0.10)` | `rgba(84,84,88,0.45)` | Row separator inside a card |
| `hairline` | `rgba(60,60,67,0.18)` | `rgba(84,84,88,0.60)` | Border on `surface`-kind buttons, card inset stroke |

### 3.5 System pops (icon badges / category tags / chart series)

| Token | Hex |
|---|---|
| `blue` | `#0A84FF` |
| `indigo` | `#5E5CE6` |
| `purple` | `#AF52DE` |
| `pink` | `#FF375F` |
| `red` | `#FF453A` |
| `yellow` | `#FFD60A` |
| `teal` | `#64D2FF` |
| `gray` | `#8E8E93` |

Icon-tile backgrounds for colored system pops follow the pattern `tint @ 0.14–0.20` in light mode (e.g. `#E0EBFF` for blue), `rgba(tint, 0.18)` in dark mode.

### 3.6 SwiftUI extension skeleton

Drop this into `EVChargingTracker/Shared/` (e.g. `CircuitColors.swift`). It is a starter — add it only when a screen actually adopts Circuit, don't pre-seed dead tokens.

```swift
import SwiftUI

enum CircuitColor {
    // Brand
    static let green     = Color(red: 15/255,  green: 169/255, blue: 104/255)
    static let greenDeep = Color(red: 10/255,  green: 122/255, blue: 75/255)
    static let greenLeaf = Color(red: 76/255,  green: 195/255, blue: 136/255)

    // Orange (sRGB approximation of oklch(0.72 0.18 28))
    static let orange     = Color(red: 255/255, green: 138/255, blue: 77/255)
    static let orangeDeep = Color(red: 229/255, green: 100/255, blue: 31/255)

    // System pops
    static let blue   = Color(red: 10/255,  green: 132/255, blue: 255/255)
    static let indigo = Color(red: 94/255,  green: 92/255,  blue: 230/255)
    static let purple = Color(red: 175/255, green: 82/255,  blue: 222/255)
    static let pink   = Color(red: 255/255, green: 55/255,  blue: 95/255)
    static let red    = Color(red: 255/255, green: 69/255,  blue: 58/255)
    static let yellow = Color(red: 255/255, green: 214/255, blue: 10/255)
    static let teal   = Color(red: 100/255, green: 210/255, blue: 255/255)
    static let gray   = Color(red: 142/255, green: 142/255, blue: 147/255)

    // Semantic — light/dark via dynamic Color
    static let bg          = dyn(light: 0xF2F2F7, dark: 0x000000)
    static let surface     = dyn(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let surfaceAlt  = dyn(light: 0xECEAEF, dark: 0x2C2C2E)
    static let surfaceHigh = dyn(light: 0xFFFFFF, dark: 0x2C2C2E)

    // Soft brand fills — switch to alpha in dark
    static let greenSoft  = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 15/255, green: 169/255, blue: 104/255, alpha: 0.16)
            : UIColor(hex: 0xE3F5EC)
    })

    private static func dyn(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat((hex)       & 0xFF) / 255,
            alpha: 1
        )
    }
}
```

---

## 4. Typography

### 4.1 Faces

The display face (titles, greetings, large numbers, nav titles) is **user-selectable** via the existing `FontSelectionView` (Settings → Base settings → Font). Numeric values use the same selected family with `.monospacedDigit()` applied for tabular alignment.

| Role | Face | Status in codebase |
|---|---|---|
| Display / titles / hero copy | **User-selected** — defaults to JetBrains Mono. Options: JetBrains Mono · iOS system · Space Grotesk (pending bundling). | Picker ships today with 2 options (`AppFontFamily.jetBrainsMono` default, `.system`); Space Grotesk is the third option pending bundling. |
| Data / numeric values (kWh, $, %, mi/km, durations, dates) | **User-selected display face** + `.monospacedDigit()` SwiftUI modifier for tabular figures | Shipping. Apply via `.appFont(...).monospacedDigit()` at every numeric Text; do not hard-code a specific font. |
| UI labels, captions, body text next to numbers | Inherits the user's selected display face | Already wired via `AppFontModifier`. |

**Selectable display faces — character & role:**

| Family | Role | Character | Bundling status |
|---|---|---|---|
| JetBrains Mono | **App default** for all installs | Monospaced display + body — coherent, technical, the EV-Tracker house look | ✅ Shipping. Set as `AppFontFamilyManager` fallback. |
| iOS system | Alternative for users who want native OS feel | SF Pro / Dynamic Type defaults — maximum platform parity | ✅ Always available (no asset). |
| Space Grotesk | Alternative for users who prefer the Circuit-prototype look | Geometric, slightly idiosyncratic — the Circuit signature look | 🛑 Not bundled. Add TTFs per `ios-guidelines/font-guideline.md`. |

**Adoption requirement (one-time work to land Space Grotesk as an option):**
- Bundle Space Grotesk TTFs in `EVChargingTracker/Fonts/` (main app target only, **not** ShareExtension).
- Register in `Info.plist` `UIAppFonts` array.
- Extend `AppFontFamily` from 2 cases to 3: add `case spaceGrotesk = "space_grotesk"`. Update `displayName` (e.g. `L("font.family.space_grotesk")`), localized strings in all 7 `.lproj` files, and the `MockUserSettingsRepository` default if needed.
- Update `AppFont.resolve` / `resolveUIFont` so the new family resolves to Space Grotesk across all role styles (display, body, and numeric). Numerics use the same family — `.monospacedDigit()` on the call site supplies tabular alignment.
- `FontSelectionView` already iterates `AppFontFamily.allCases` and renders each row in its own family — no view changes required beyond the enum extension.
- Verify Space Grotesk glyph coverage for `.kk` (Kazakh extended Cyrillic) and `.zhHans` (Simplified Chinese) in `supports(_:)`. If a script is uncovered, fall back to system for that language while keeping Space Grotesk for covered locales.

**Until Space Grotesk is bundled,** the picker exposes only `jetBrainsMono` (default) and `system`. Both are valid Circuit display faces — neither breaks the visual system. When Space Grotesk lands it joins as a third opt-in choice; **JetBrains Mono remains the app default** and existing users keep their selected family.

**Do not substitute one display face for another in code.** Always read from the user's selected `AppFontFamily` via `AppFont.resolve(...)`. Hard-coding `.system(.title, .rounded)` or `Font.custom("JetBrainsMono-Bold", size: 34)` for a title bypasses the picker.

### 4.2 Scale

Values lifted from the prototype. All weights / sizes are in points. **Face column key:**
- **Display** → the user's selected `AppFontFamily` (Space Grotesk / JetBrains Mono / system).
- **Numeric** → the user's selected `AppFontFamily` + `.monospacedDigit()` for tabular figures. Same family as Display; the modifier guarantees column alignment regardless of which face is active.
- **UI** → the user's selected `AppFontFamily`, same as Display but at smaller sizes.

| Role | Size | Weight | Letter-spacing | Face | Example |
|---|---|---|---|---|---|
| Hero title (screen large-title) | 34 | 800 | -1 | Display | "Stats" nav large-title |
| Greeting | 28 | 800 | -0.8 | Display | "Good morning, …" |
| Big numeric (hero stat) | 38 | 700 | -1.4 | Numeric | "$47.32" total spend |
| Card stat | 22–32 | 700 | -0.5 to -1 | Numeric | KPI card values |
| Nav title (compact bar) | 17 | 600 | -0.3 | Display | "New expense" |
| List row title | 15 | 500 | -0.2 | UI | Session label |
| List row right-value | 15 | 700 | 0 | Numeric | "$3.56" |
| Chip / button body | 13 | 600 | -0.1 to -0.2 | UI | "See all", chip text |
| Label (eyebrow over value) | 11 | 600 | 0.3, UPPERCASE | UI | "TOTAL SPEND" |
| Caption | 11–13 | 500–600 | 0.2 | UI | Row sub-label, legend text |
| Tab bar label | 10.5 | 600 | -0.1 | UI | "Stats", "Expenses" |

**Per-family weight notes:**
- Space Grotesk: ships 300/400/500/600/700. Map weight 800 → 700 (the heaviest cut available); the visual weight already reads strong at this size.
- JetBrains Mono: ships 100–800. Use the requested weight directly.
- iOS system: use `.bold` / `.heavy` / `.black` SF Pro weights to approximate 700/800.

**Mapping to existing `AppFont`:**
- `largeTitle` (34, `.largeTitle`) → Hero. Resolves to selected family at the heaviest available weight.
- `title` (28) → Greeting.
- `title2` (22) / `title3` (20) → KPI numeric values when no bigger hero is present. Apply `.monospacedDigit()` at the call site for tabular alignment; the family follows the user's selection.
- `headline` (17, semibold) → compact nav title / section-pinned header (matches).
- `subheadline` (15) → row title (matches at weight 500).
- `caption` / `caption2` (11–13) → eyebrow labels, tab labels, legend captions.

### 4.3 Eyebrow pattern

The small label above a numeric value — everywhere. Use this exactly:

```
fontSize: 11, fontWeight: 600, letterSpacing: 0.3, textTransform: UPPERCASE, color: inkSoft
```

Never omit; never replace with regular-case labels. This is the single most recurring pattern in the prototype and what makes it read as "Apple grouped table."

---

## 5. Radii, spacing, elevation

### 5.1 Radii

| Token | Value | Use |
|---|---|---|
| `cardRadius` | **20** | Default card corner |
| Button lg | 14 | 52pt-tall primary CTAs |
| Button md | 12 | 44pt-tall |
| Button sm | 10 | 34pt-tall chip-button |
| Chip | 999 | Pill |
| Row icon tile | 9 | 32×32 or 34×34 square |
| Circle button | 50% | 34×34 `CircleBtn` for back / close / more |
| FAB | 50% | 56×56 floating action button |
| Progress / breakdown stripe | 2–5 | Hairline progress indicator |

### 5.2 Spacing rhythm

Containers use **16pt** horizontal gutter, cards use **16pt** inner padding (14pt for KPI strip cards). Section headers sit **18pt above / 6pt below** their content block. Stack gaps inside a card are usually **10–14pt** between rows, **8pt** between inline chips/buttons.

Top-of-screen padding for `NavBar` large: **64pt top**, compact: **52pt** (accommodates Dynamic Island + status bar). Bottom padding for scrollable screens above the tab bar: rely on SwiftUI's `.safeAreaInset` / stock `TabView` insets — don't hard-code, since the app uses the stock tab bar.

### 5.3 Elevation

| Surface | Light | Dark |
|---|---|---|
| Card (default) | `boxShadow: 0 0.5px 0 rgba(0,0,0,0.04)` | `boxShadow: none` |
| Card (dark, inset) | — | `inset 0 0 0 1px rgba(255,255,255,0.08)` — NOT a drop shadow |
| CircleBtn | `0 1px 2px rgba(0,0,0,0.06)` | `inset 0 0 0 1px rgba(255,255,255,0.08)` |
| FAB (orange or green) | `0 10px 22px -6px rgba(brand, 0.45)` | `0 10px 22px -6px rgba(brand, 0.50)` |

**Dark-mode rule:** every place that has a drop shadow in light mode gets an inset 1px white-alpha hairline in dark mode instead. Don't try to keep the shadow — it looks dirty on true black.

---

## 6. Component recipes

Structural specs — what to build, what values to use. Build in whatever SwiftUI shape fits the call site; don't create a monolithic component library up-front.

### 6.1 `Card` — `tokens.jsx:65`

- Background `surface`, radius `cardRadius` (20), padding 16.
- Light mode: subtle `0 0.5px 0 rgba(0,0,0,0.04)` shadow.
- Dark mode: no shadow (the `surface` color against `bg` provides the separation).
- `pad={0}` variant: radius still 20, padding 0, content is responsible for its own insets so a chart/preview can bleed edge-to-edge.

### 6.2 `Chip` — `tokens.jsx:93`

Pill, radius 999, height 26 (md) or 20 (sm), padding `0 10px` / `0 8px`, font UI 12/11 weight 600.

Tint pairs (bg / fg):

| Tint | Light bg | Light fg | Dark bg | Dark fg |
|---|---|---|---|---|
| `green` | `greenSoft` | `greenDeep` | `rgba(15,169,104,0.16)` | `greenDeep` |
| `orange` | `orangeSoft` | `orangeDeep` | `rgba(orange, 0.35)` | `orangeDeep` |
| `blue` | `#E0EBFF` | `#0A84FF` | `rgba(10,132,255,0.18)` | `#0A84FF` |
| `red` | `#FFE1DF` | `#FF453A` | `rgba(255,69,58,0.18)` | `#FF453A` |
| `gray` | `surfaceAlt` | `inkSoft` | `surfaceAlt` | `inkSoft` |
| `ink` | `#000` | `#FFF` (light) · `#FFF` bg / `#000` fg (dark) | — | — |

Chips may lead with an 11pt colored icon. Filter-chip variant (used in Expenses): selected = `orange` tint, unselected = `gray` tint; tap toggles state.

### 6.3 `Btn` — `tokens.jsx:113`

Heights/radii/font-sizes: `lg 52/14/17`, `md 44/12/15`, `sm 34/10/13`. Font UI, weight 600, letter-spacing -0.2.

Kinds:
- `primary`: bg `ink`, fg `#fff` (light) / `#000` (dark). Main screen CTA.
- `green`: bg `green`, fg `#fff`. "Save", confirmatory flows. Maps to current `FormButtonsView` Save.
- `accent`: bg `orange`, fg `#fff`. Reserved — major actions, prominent CTAs ("Add Charging Session" gradient maps here once flat-orange replaces gradient).
- `surface`: bg `surface`, fg `ink`, `inset 0 0 0 1px hairline`. Secondary on a colored/dark background.
- `tinted`: bg `surfaceAlt`, fg `ink`. Subtle secondary on neutral cards.
- `ghost`: bg transparent, fg `blue`. Link-style inline actions ("See all", "Cancel", "Edit").
- `outlined`: bg transparent, fg `red`, `inset 0 0 0 1px red @ 0.5`. Destructive secondary (maps to current `FormButtonsView` Cancel / `OutlinedButtonStyle`).

### 6.4 `Row` (list cell) — `widgets.jsx:127`

- Padding `12 16`, gap 14, bottom border `1px solid divider` unless `last`.
- Optional icon tile: 32×32 or 34×34, radius 9, bg `surfaceAlt` (neutral) or a soft brand/system color.
- Title: 15pt / weight 500 / `ink`.
- Sub: 13pt / `inkSoft` / 1pt top margin.
- Right side: either a mono value (15pt / 700) + tiny caption, or an `Icon.chevron` glyph, or nothing.

The right-side "two-line value" pattern (value on top, small green rate below) is the default for money-priced rows (e.g. session list cost + $/kWh).

### 6.5 `FormRow` (inline form cell)

Variant of `Row` for key/value editing. Use inside SwiftUI `Form` sections — don't replace `Form` itself.

- Icon tile 32×32, radius 9.
- Label 12pt / 500 / `inkSoft` on top.
- Value 15pt / 600 / `ink` below. If placeholder/hint, value fg = `blue`.
- Right: `Icon.chevron` 16pt in `inkSoft`, or custom action icon.

### 6.6 `SectionHeader` — `widgets.jsx:153`

- Padding `18 20 6`.
- Label: 13pt / weight 600 / `inkSoft` / letter-spacing 0.3 / **UPPERCASE**.
- Optional `action` slot on the right (e.g. "See all" as a `ghost` button at 13pt / 600).
- Optional badge slot next to the title: small pill (Chip `sm`) showing a count or status. Use `red` tint for warnings (e.g. pending maintenance), `gray` tint for neutral counts. Maps to current `CarDetailsSectionView`.

### 6.7 `NavBar` — `widgets.jsx:87`

The app uses stock `NavigationStack` — these specs override default visual attributes via `AppFontAppearance` and `UINavigationBarAppearance`:

- **Large title:** 34pt / 800 / -1 letter-spacing in selected display family. Stock `.navigationBarTitleDisplayMode(.large)`.
- **Compact title:** 17pt / 600 / -0.3 in selected display family. Stock `.navigationBarTitleDisplayMode(.inline)`.
- Leading/trailing toolbar items: prefer `CircleBtn` for icon-only actions, `Btn(ghost)` for text actions ("Cancel", "Save").

Don't build a custom nav bar component — extend the appearance proxy.

### 6.8 `CircleBtn` — `widgets.jsx:115`

34×34, circular, bg `surface`, light drop shadow (light mode) or inset hairline (dark). Houses a 16–18pt glyph from the icon set. Used for back / close / more / per-row chevron triggers.

### 6.9 `FAB` (floating action button)

Per-screen circular floating button, used on Expenses and Car tabs today.

- Size 56×56, radius 50%, bottom-trailing positioned with 16–20pt margin from screen edges.
- Background: brand color appropriate to the tab's primary action — `green` for confirmatory adds, `orange` for cost-related adds.
- Glyph: `plus` (or context-specific) at 24pt weight 2.6, color `#fff`.
- Shadow: `0 10px 22px -6px rgba(brand, 0.45)` (light) / `0.50` alpha (dark).
- Tap: present a modal sheet OR a context menu (`CarQuickAddSheet` pattern).

### 6.10 `TabBar`

The app uses **stock SwiftUI `TabView`** — do not replace. Apply Circuit only via:
- Tab tint: `green` for selected items (currently `AppTheme.tabMenuTintColor()`).
- Badges: stock `.badge(_:)` modifier with `red` for warnings (pending maintenance), `green` for "New!" announcements.
- Tab labels: `Label(text, systemImage:)` with SF Symbols. No custom drawing.

### 6.11 `Segmented` — `widgets.jsx:330`

For SwiftUI `Picker(.segmented)` style overrides:
- Track: `surfaceAlt` bg, radius 10, inner padding 2, gap 2.
- Item: padding `6 14`, radius 8, font UI 13/600.
- Active: bg `surface`, `0 1px 3px rgba(0,0,0,0.1)` (light) / `inset 0 0 0 0.5px rgba(255,255,255,0.1)` (dark).

Used for sort selection (Expenses) and similar binary/ternary toggles.

### 6.12 Sheet header (modal)

- Grab handle: 36×5, radius 3, `inkGhost`, 12pt top padding, centered.
- Below handle: 3-column header row at 17pt — `Cancel` (ghost button, blue, weight 500) · centered title (weight 700, -0.3, in selected display family) · `Save` (ghost button, blue, weight 600).

For destructive cancel actions inside the sheet, use `Btn(outlined)` (red) at the bottom action area instead of header `Cancel`.

---

## 7. Charts

The app uses SwiftUI `Charts`. These specs are visual treatments, not chart-framework primitives.

### 7.1 Line + area chart

Used in Stats for consumption trends.

- Line: stroke 2.2, `linecap: round`, `linejoin: round`.
- Area fill: linear gradient from `color @ 0.28` (top) to `color @ 0` (bottom).
- Color choice by metric:
  - `green` for efficiency / positive deltas
  - `orange` for cost trends
  - `red` for warning / over-budget
- Optional `PointMark` at each data point: 4pt radius, `color` solid, on top of the line.
- Axes: light `inkSoft` labels, no gridlines inside the chart, no chart title (use `SectionHeader` above the card instead).

### 7.2 Bar chart — `widgets.jsx:224`

Two variants:

**Single-series with accent (KPI / weekday compare):**
- All bars: `surfaceAlt`, radius 4.
- One `accentIdx` bar: `green` + an inline label above, mono 10pt / 700 / `green`.
- Labels strip below at `11pt / inkSoft / 500`.

**Stacked by category (expense breakdown):**
- Each segment colored by category: charging = `green`, maintenance = `orange`, repair = `red`, carwash = `blue`, other = `gray`.
- Bar radius 4 on the outermost ends only (or 0 for tight stacks).
- Legend below the chart in `Row`-style entries with a 10×10 radius-3 color dot — never inside the chart frame.

---

## 8. Motion

The prototype is static HTML; the target is **Apple default motion** everywhere:
- Sheet presentation: stock iOS sheet.
- Tab switches: no tab-bar reorder animation; icon color transitions are instant (or `.easeInOut(duration: 0.15)` at most).
- Large-title to compact-title collapse: stock `NavigationStack` behavior.
- Pull-to-refresh: stock.
- Button taps: stock UIKit / SwiftUI press feedback. No custom scale/spring.

Don't introduce custom animation curves or repeating animations unless a specific feature requires it (and document it here when added).

---

## 9. Light / Dark parity rules

1. Brand green hex values **never shift between modes**. Only the `Soft` variant changes from pastel tint to alpha.
2. Orange oklch values don't shift either; only `orangeSoft` swaps to the alpha form.
3. Canvas: `#F2F2F7` → `#000000`. Card: `#FFFFFF` → `#1C1C1E`. "Raised" card / sheet: `#FFFFFF` → `#2C2C2E`.
4. Every drop shadow used in light mode becomes a `1px inset white-alpha hairline` in dark mode. No shadows on dark cards.
5. Hairline inset on buttons (`surface` kind, `CircleBtn`): `hairline` token in both modes — the token itself handles the light/dark swap.
6. Colored icon tiles use the pastel hex in light and `rgba(tint, 0.18)` in dark. Never swap the tint hue.
7. Status-bar/nav text inherits `ink` — i.e., black on light, white on dark. Don't force white.
8. Charts: track / non-accent bars swap via `surfaceAlt` naturally; accent and category colors stay.

---

## 10. Open items / decisions deferred

- **Orange hue slider** — the prototype offers a runtime hue tweak (`TWEAK_DEFAULTS.orangeHue`). Decide whether to expose this as a user-facing setting (adds surface area) or bake a single accepted hue. Default: bake at `28°` / `#FF8A4D` for v1.
- **Forest / Voltage variations** — not captured here; if the design direction changes, this doc must be re-derived from the alternate variation files in the bundle.
- **Localized rendering across selectable display faces** — each `AppFontFamily` declares its own `supports(_:)` predicate and falls through to system when out of range. Verify per family before shipping: JetBrains Mono falls back today for several locales; Space Grotesk's coverage for `.kk` (Kazakh extended Cyrillic) and `.zhHans` (Simplified Chinese) is unverified and likely needs the same fallback. The system option always renders correctly via SF Pro / Dynamic Type.

---

## 11. Maintenance

This guideline is derived from a specific bundle state. If the source (prototype HTML/JSX) evolves:
1. Re-unpack the Claude Design handoff bundle.
2. Diff `tokens.jsx` and `widgets.jsx` against the values in sections 3–5 above.
3. Update this file first, then any code that has adopted the changed token.
4. If the design direction changes fundamentally (e.g. switch from "Circuit" to "Forest"), rewrite this file — don't layer a new variation on top.

If the **app's UI surface** changes (new component pattern shipped, old one removed), update §6 and §7 to match. The design doc must describe what the app actually uses — never a wish list.
