# Circuit Design System — EV Charging Tracker

Visual-language spec for the "Circuit" redesign of the EV Charging Tracker iOS app. Apple-native minimal with eco-green brand and an orange accent.

---

## 1. Source of truth

- **Handoff bundle:** generated via Claude Design (claude.ai/design), unpacked locally to `/tmp/design_bundle/app-onboarding/`. Primary file: `project/Circuit EV v4.html`.
- **Tokens reference:** `project/circuit/tokens.jsx` (colors, typography primitives, `Card` / `Chip` / `Btn` / `StatusBar`).
- **Widget reference:** `project/circuit/widgets.jsx` (`Phone`, `TabBar`, `NavBar`, `CircleBtn`, `Row`, `SectionHeader`, `BatteryRing`, `Sparkline`, `BarChart`, `MiniMap`, `CarSilhouette`, `Segmented`).
- **Screen reference:** `project/circuit/screen_home.jsx`, `screens_insights.jsx`, `screens_trips.jsx`, `screens_onb.jsx`, `screens_misc.jsx`.
- **Design intent:** the chat transcript at `chats/chat1.md` documents the user's direction — _"Clean & minimal (Apple-native feel) + eco-inspired … orange hue slider, light/dark toggle, Space Grotesk for display, Inter/JetBrains Mono for body"_. Three variations were explored (Forest / Circuit / Voltage); **Circuit** — the Apple-native clean/minimal one — is the approved direction captured here.

When this guideline conflicts with what you see in the prototype, the prototype source wins. When the prototype uses a value the guideline omits, use this guideline's closest token.

---

## 2. Design principles

- **Apple-native grammar.** iOS grouped backgrounds, sheet grab handles, large-title nav, glassy floating tab bar, haptic-ready buttons. Nothing that reads as "web" or "Material".
- **Green = energy.** Brand greens own all "energy / eco / healthy / reward" signals: charging state, positive deltas, savings, efficiency chips, CO₂ impact.
- **Orange = action/cost accent.** CTAs, "Planned"/scheduled badges, cost-priced signals, the DC-fast charging session. Orange is reserved — if everything is orange, nothing is.
- **Monospace for numbers.** JetBrains Mono on every numeric value (kWh, $, %, mi/km, duration, dates) — independent of the user's display-face choice. Titles and labels use the user's selected display face: **JetBrains Mono is the app default**; iOS system and (once bundled) Space Grotesk are alternatives — see §4.1.
- **Dark mode is a mirror, not a re-skin.** Canvas goes true black, surfaces climb to `#1C1C1E`/`#2C2C2E`. Drop shadows are replaced by inset 1px white-alpha hairlines. Brand greens stay the same values; their _soft_ variants switch to `rgba(brand, 0.16)`.
- **Charts are flat and quiet.** Thin strokes, gradient fills that fade to zero, one highlighted bar. No axis grids, no legends inside the chart — legends live in a card below.

---

## 3. Color tokens

All values are taken verbatim from `tokens.jsx` → `buildPalette(tweaks)`.

### 3.1 Brand

| Token | Light | Dark | Use |
|---|---|---|---|
| `green` | `#0FA968` | `#0FA968` | Primary brand, ring arcs, positive deltas, FAB `+` |
| `greenDeep` | `#0A7A4B` | `#0A7A4B` | Chip text on `greenSoft`, emphasized leaf/savings copy |
| `greenSoft` | `#E3F5EC` | `rgba(15,169,104,0.16)` | Chip background, row icon tile background |
| `greenLeaf` | `#4CC388` | `#4CC388` | Illustrations / decorative leaf motifs |
| `orange` | `oklch(0.72 0.18 28)` | same | Accent CTA, "Planned" chip, DC-fast markers |
| `orangeDeep` | `oklch(0.62 0.19 28)` | same | Chip text on `orangeSoft` |
| `orangeSoft` | `oklch(0.94 0.06 28)` | `oklch(0.32 0.09 28 / 0.35)` | Chip background, row icon tile background |

**On orange & oklch:** the tweakable hue knob defaults to `28°`. In sRGB this approximates `#FF8A4D` (`orange`) / `#E5641F` (`orangeDeep`) / `#FCE5D4` (`orangeSoft` light). SwiftUI can render oklch via `Color(.displayP3, red:green:blue:opacity:)` with the converted coordinates; for back-compat, use the sRGB approximations above. If you add an "orange hue" tweak to the app later, re-derive via oklch → sRGB at runtime rather than shipping fixed hex.

### 3.2 Surfaces — iOS grouped vocabulary

| Token | Light | Dark | Notes |
|---|---|---|---|
| `bg` | `#F2F2F7` | `#000000` | Canvas / grouped table background |
| `surface` | `#FFFFFF` | `#1C1C1E` | Card / cell background |
| `surfaceAlt` | `#ECEAEF` | `#2C2C2E` | Tinted button, segmented track, icon tile without color, info callout |
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

### 3.5 System pops (for icon badges / category tags only)

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

Icon-tile backgrounds for colored system pops follow the pattern `tint @ 0.14–0.20` in light mode (e.g. `#E0EBFF` for blue), `rgba(tint, 0.18)` in dark mode. See `screen_home.jsx:172` for the exact pattern.

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

    // Semantic — light/dark via dynamic Color asset OR `Color(UIColor { trait in … })`
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

The display face (titles, greetings, large numbers, nav titles) is **user-selectable** via the existing `FontSelectionView` (Settings → Base settings → Font). Numeric values always render in JetBrains Mono regardless of the choice.

| Role | Face | Status in codebase |
|---|---|---|
| Display / titles / hero copy | **User-selected** — defaults to JetBrains Mono. Options: JetBrains Mono · iOS system · Space Grotesk (pending bundling). | Picker ships today with 2 options (`AppFontFamily.jetBrainsMono` default, `.system`); Space Grotesk is the third option pending bundling. |
| Data / numeric values (kWh, $, %, mi/km, durations, dates) | **JetBrains Mono** (fixed — not user-selectable) | Shipping. Apply unconditionally; ignore the user's display-face choice for numeric content. |
| UI labels, captions, body text next to numbers | Inherits the user's selected display face | Already wired via `AppFontModifier`. |

**Selectable display faces — character & role:**

| Family | Role | Character | Bundling status |
|---|---|---|---|
| JetBrains Mono | **App default** for all installs | Monospaced display + body — coherent, technical, the EV-Tracker house look | ✅ Shipping. Set as `AppFontFamilyManager` fallback. |
| iOS system | Alternative for users who want native OS feel | SF Pro / Dynamic Type defaults — maximum platform parity | ✅ Always available (no asset). |
| Space Grotesk | Alternative for users who prefer the Circuit-prototype look | Geometric, slightly idiosyncratic — the Circuit signature look | 🛑 Not bundled. Add TTFs per `ios-guidelines/font-guideline.md`. |

**Adoption requirement (one-time work to land Circuit titles):**
- Bundle Space Grotesk TTFs in `EVChargingTracker/Fonts/` (main app target only, **not** ShareExtension).
- Register in `Info.plist` `UIAppFonts` array.
- Extend `AppFontFamily` from 2 cases to 3: add `case spaceGrotesk = "space_grotesk"`. Update `displayName` (e.g. `L("font.family.space_grotesk")`), localized strings in all 7 `.lproj` files, and the `MockUserSettingsRepository` default if needed.
- Update `AppFont.resolve` / `resolveUIFont` so the new family resolves to Space Grotesk for title-role styles and falls through to JetBrains Mono / system for body and numeric paths (numerics stay JetBrains Mono regardless).
- `FontSelectionView` already iterates `AppFontFamily.allCases` and renders each row in its own family — no view changes required beyond the enum extension.
- Verify Space Grotesk glyph coverage for `.kk` (Kazakh extended Cyrillic) and `.zhHans` (Simplified Chinese) in `supports(_:)`. If a script is uncovered, fall back to system for that language while keeping Space Grotesk for covered locales.

**Until Space Grotesk is bundled,** the picker exposes only `jetBrainsMono` (default) and `system`. Both are valid Circuit display faces — neither breaks the visual system. When Space Grotesk lands it joins as a third opt-in choice; **JetBrains Mono remains the app default** and existing users keep their selected family.

**Do not substitute one display face for another in code.** Always read from the user's selected `AppFontFamily` via `AppFont.resolve(...)`. Hard-coding `.system(.title, .rounded)` or `Font.custom("JetBrainsMono-Bold", size: 34)` for a title bypasses the picker.

### 4.2 Scale

Values lifted from the prototype. All weights / sizes are in points. **Face column key:**
- **Display** → the user's selected `AppFontFamily` (Space Grotesk / JetBrains Mono / system).
- **Mono** → JetBrains Mono, fixed regardless of selection.
- **UI** → the user's selected `AppFontFamily`, same as Display but at smaller sizes.

| Role | Size | Weight | Letter-spacing | Face | Example |
|---|---|---|---|---|---|
| Hero title (screen large-title) | 34 | 800 | -1 | Display | "Insights" nav large-title |
| Greeting | 28 | 800 | -0.8 | Display | "Good morning, Maya" |
| Big numeric (hero stat) | 38 | 700 | -1.4 | Mono | "$47.32" total spend |
| Card stat | 22–32 | 700 | -0.5 to -1 | Mono | KPI card values |
| Nav title (compact bar) | 17 | 600 | -0.3 | Display | "New expense" |
| List row title | 15 | 500 | -0.2 | UI | Session label |
| List row right-value | 15 | 700 | 0 | Mono | "$3.56" |
| Chip / button body | 13 | 600 | -0.1 to -0.2 | UI | "See all", chip text |
| Label (eyebrow over value) | 11 | 600 | 0.3, UPPERCASE | UI | "TOTAL SPEND" |
| Caption | 11–13 | 500–600 | 0.2 | UI | Row sub-label, legend text |
| Tab bar label | 10.5 | 600 | -0.1 | UI | "Home", "Insights" |

**Per-family weight notes:**
- Space Grotesk: ships 300/400/500/600/700. Map weight 800 → 700 (the heaviest cut available); the visual weight already reads strong at this size.
- JetBrains Mono: ships 100–800. Use the requested weight directly.
- iOS system: use `.bold` / `.heavy` / `.black` SF Pro weights to approximate 700/800.

**Mapping to existing `AppFont`:**
- `largeTitle` (34, `.largeTitle`) → Circuit Hero. Resolves to selected family at the heaviest available weight.
- `title` (28) → Greeting.
- `title2` (22) / `title3` (20) → KPI mono values when no bigger hero is present (these stay JetBrains Mono — they are numerics).
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
| `cardRadius` | **20** | Default card corner (tweakable in prototype slider) |
| Live-charging hero | 28 | Oversized hero card with green gradient |
| Button lg | 14 | 52pt-tall primary CTAs |
| Button md | 12 | 44pt-tall |
| Button sm | 10 | 34pt-tall chip-button |
| Chip | 999 | Pill |
| Row icon tile | 9 | 34×34 or 32×32 square |
| Circle button | 50% | 34×34 `CircleBtn` for back / close / more |
| Tab bar container | 24 | Glassy floating pill |
| Phone frame | 54 | Device bezel (reference only — real iOS chrome handles this) |
| Progress bar / breakdown stripe | 2–5 | Hairline progress indicator |

### 5.2 Spacing rhythm

Containers use **16pt** horizontal gutter, cards use **16pt** inner padding (14pt for KPI strip cards). Section headers sit **18pt above / 6pt below** their content block. Stack gaps (`VS gap={...}`) are usually **10–14pt** between rows inside a card, **8pt** between inline chips/buttons.

Top-of-screen padding for `NavBar` large: **64pt top**, compact: **52pt** (accommodates Dynamic Island + status bar). Bottom padding for scrollable screens: **120pt** (clears the floating tab bar).

### 5.3 Elevation

| Surface | Light | Dark |
|---|---|---|
| Card (default) | `boxShadow: 0 0.5px 0 rgba(0,0,0,0.04)` | `boxShadow: none` |
| Card (dark, inset) | — | `inset 0 0 0 1px rgba(255,255,255,0.08)` — NOT a drop shadow |
| Tab bar (glass) | `0 10px 30px -10px rgba(0,0,0,0.2), inset 0 0 0 1px rgba(0,0,0,0.04)` | `0 10px 30px -10px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.08)` |
| CircleBtn | `0 1px 2px rgba(0,0,0,0.06)` | `inset 0 0 0 1px rgba(255,255,255,0.08)` |
| FAB (green plus) | `0 10px 22px -6px rgba(15,169,104,0.45)` | `0 10px 22px -6px rgba(15,169,104,0.50)` |
| Hero live-charging card | `0 20px 40px -20px rgba(15,169,104,0.55)` | same |

**Dark-mode rule:** every place that has a drop shadow in light mode gets an inset 1px white-alpha hairline in dark mode instead. Don't try to keep the shadow — it looks dirty on true black.

**Tab bar glass:** `backdrop-filter: blur(30px) saturate(180%)` + surface at **0.78 opacity** (light: white, dark: `#1C1C1E`). In SwiftUI: `.background(.ultraThinMaterial)` is the closest stock equivalent; to fine-tune, overlay a `Color.white.opacity(dark ? 0.0 : 0.06)` or use `Material.bar` and adjust.

---

## 6. Component recipes

These are structural specs — what to build, what values to use. Each references the prototype line that defines it. Build in whatever SwiftUI shape fits the call site; don't create a monolithic component library up-front.

### 6.1 `Card` — `tokens.jsx:65`

- Background `surface`, radius `cardRadius` (20 default), padding 16.
- Light mode: subtle `0 0.5px 0 rgba(0,0,0,0.04)` shadow.
- Dark mode: no shadow (SwiftUI equivalent: no modifier needed; the `surface` color against `bg` provides the separation).
- `pad={0}` variant (see `screen_home.jsx:119` for mini-map-topped cards): radius still 20, padding 0, content is responsible for its own insets so `MiniMap` can bleed edge-to-edge.

### 6.2 `Chip` — `tokens.jsx:93`

Pill, radius 999, height 26 (md) or 20 (sm), padding `0 10px` / `0 8px`, font mono 12/11 weight 600.

Tint pairs (bg / fg):
| Tint | Light bg | Light fg | Dark bg | Dark fg |
|---|---|---|---|---|
| `green` | `greenSoft` | `greenDeep` | `rgba(15,169,104,0.16)` | `greenDeep` |
| `orange` | `orangeSoft` | `orangeDeep` | `rgba(orange, 0.35)` | `orangeDeep` |
| `blue` | `#E0EBFF` | `#0A84FF` | `rgba(10,132,255,0.18)` | `#0A84FF` |
| `red` | `#FFE1DF` | `#FF453A` | `rgba(255,69,58,0.18)` | `#FF453A` |
| `gray` | `surfaceAlt` | `inkSoft` | `surfaceAlt` | `inkSoft` |
| `ink` | `#000` | `#FFF` (light) · `#FFF` bg / `#000` fg (dark) | — | — |

Chips may lead with an 11pt colored icon (e.g. `Icon.calendar` inside "Planned").

### 6.3 `Btn` — `tokens.jsx:113`

Heights/radii/font-sizes: `lg 52/14/17`, `md 44/12/15`, `sm 34/10/13`. Font UI, weight 600, letter-spacing -0.2.

Kinds:
- `primary`: bg `ink`, fg `#fff` (light) / `#000` (dark). Main screen CTA.
- `green`: bg `green`, fg `#fff`. "Save", "Continue charging", confirmatory flows.
- `accent`: bg `orange`, fg `#fff`. Reserved — onboarding "Get started", major upsells.
- `surface`: bg `surface`, fg `ink`, `inset 0 0 0 1px hairline`. Secondary on a colored card (e.g. pause/details on the green hero).
- `tinted`: bg `surfaceAlt`, fg `ink`. Subtle secondary on neutral cards.
- `ghost`: bg transparent, fg `blue`. Link-style inline actions ("See all", "Cancel").

### 6.4 `Row` (list cell) — `widgets.jsx:127`

- Padding `12 16`, gap 14, bottom border `1px solid divider` unless `last`.
- Optional icon tile: 34×34, radius 9, bg `surfaceAlt` (neutral) or a `Soft` brand/system color.
- Title: 15pt / weight 500 / `ink`.
- Sub: 13pt / `inkSoft` / 1pt top margin.
- Right side: either a mono value (15pt / 700) + tiny caption, or an `Icon.chevron` glyph, or nothing.

The right-side "two-line value" pattern (value on top, small green rate below) — see `screen_home.jsx:154-157` — is the default for money-priced rows.

### 6.5 `FormRow` (inline form cell) — `screens_insights.jsx:204`

Variant of `Row` for key/value editing:
- Icon tile 32×32, radius 9.
- Label 12pt / 500 / `inkSoft` on top.
- Value 15pt / 600 / `ink` below. If placeholder/hint, value fg = `blue`.
- Right: `Icon.chevron` 16pt in `inkSoft`, or custom action icon.

### 6.6 `SectionHeader` — `widgets.jsx:153`

- Padding `18 20 6`.
- Label: 13pt / weight 600 / `inkSoft` / letter-spacing 0.3 / **UPPERCASE**.
- Optional `action` slot on the right (e.g. "See all" as a blue ghost label at 13pt / 600).

### 6.7 `NavBar` — `widgets.jsx:87`

Two variants:
- **Large** (home-scale screens, Settings/Insights landing): padding `64 20 8`, title 34pt / 800 / -1 letter-spacing, optional subtitle 15pt / `inkSoft`. Leading and trailing `CircleBtn` slots above the title.
- **Compact** (modal sheets, detail pages): height 96, padding `52 12 0`, 3-column grid (leading / centered title / trailing). Title 17pt / 600 / -0.3.

### 6.8 `CircleBtn` — `widgets.jsx:115`

34×34, circular, bg `surface`, light drop shadow (light mode) or inset hairline (dark). Houses a 16–18pt glyph from the icon set. Used for back / close / calendar / more.

### 6.9 `TabBar` (floating glass) — `widgets.jsx:37`

- Absolute-positioned: `left: 12, right: 12, bottom: 22`. Height 70, radius 24.
- Background: 78%-opacity surface + `backdrop-filter: blur(30) saturate(180%)`.
- 5 slots, center slot is a **FAB**: 52×52, radius 18, bg `green`, glyph `plus` 24pt weight 2.6 in white, glow shadow `0 10px 22px -6px rgba(15,169,104,0.45)`.
- Side slots: icon 24pt + label 10.5pt/600. Active tab colors icon + label `green`; inactive uses `inkSoft`.

### 6.10 `Segmented` — `widgets.jsx:330`

- Track: `surfaceAlt` bg, radius 10, inner padding 2, gap 2.
- Item: padding `6 14`, radius 8, font UI 13/600.
- Active: bg `surface`, `0 1px 3px rgba(0,0,0,0.1)` (light) / `inset 0 0 0 0.5px rgba(255,255,255,0.1)` (dark).

### 6.11 Sheet header (modal) — `screens_insights.jsx:128-136`

- Grab handle: 36×5, radius 3, `inkGhost`, 12pt top padding, centered.
- Below handle: 3-column header row at 17pt — `Cancel` (blue ghost, weight 500) · centered title (weight 700, -0.3) · `Save` (blue ghost, weight 600).

---

## 7. Charts

### 7.1 `BatteryRing` — `widgets.jsx:170`

- SVG circle, stroke 14 (default) or 10 (hero), `strokeLinecap: round`.
- Track = `surfaceAlt`; arc = `green` (or brand pass-through).
- Rotated `-90deg` so the arc begins at 12 o'clock.
- Center: mono big number (34pt /700 / -1) + tiny % suffix + miles/km caption below.

### 7.2 `Sparkline` — `widgets.jsx:197`

- Stroke 2.2, `linecap: round`, `linejoin: round`.
- Filled gradient from `color @ 0.28` (top) to `color @ 0` (bottom).
- Color = `green` for efficiency, `orange` for cost trends.
- Width 326, height 70 for card-inline use. No axis, no dots — a weekday strip (W T F S S M T) sits 4pt below the svg at 10.5pt `inkSoft`.

### 7.3 `BarChart` — `widgets.jsx:224`

- All bars: `surfaceAlt`, radius 4.
- `accentIdx` bar: `green` + an inline label above, mono 10pt / 700 / `green`.
- Labels strip below at `11pt / inkSoft / 500`.

### 7.4 Stack breakdown — `screens_insights.jsx:37`

Horizontal 10pt-tall segmented bar (radius 5), green / orange / blue / etc. segments sized by `flex: pct`. Followed by a `LegendRow` list with a 10×10 radius-3 color dot.

### 7.5 `MiniMap` — `widgets.jsx:264`

- Stylized abstract — **not** an actual map tile source.
- Two land tones + one water blob + a faint 40pt grid (road pattern).
- Route stroke: 4pt, gradient `green → orange`, rounded caps.
- Start marker: 6.5pt `green` dot with 2.2pt white ring. End marker: same in `orange`.

If the target screen needs a real map (MapKit), keep the same visual treatment — overlay a thin green→orange gradient polyline on a muted `.mutedStandard` base map; hide POI labels.

---

## 8. Motion

The prototype is static HTML. Chat transcript confirms no custom animations were specified — the target is **Apple default motion** everywhere:
- Sheet presentation: stock iOS sheet.
- Tab switches: no tab-bar reorder animation; icon color transitions are instant (or `.easeInOut(duration: 0.15)` at most).
- Large-title to compact-title collapse: stock `NavigationStack` behavior.
- Pull-to-refresh: stock.
- Charging-state pulse dot (`screen_home.jsx:41-45`): **keep this one** — an 8pt green dot with a pulsing `0 0 0 4px rgba(142,245,195,0.25)` ring. Animate the ring opacity `0.25 → 0 → 0.25` over ~1.6s `.easeInOut` repeatForever. This is the only non-Apple-default animation in the system.

---

## 9. Light / Dark parity rules

1. Brand green hex values **never shift between modes**. Only the `Soft` variant changes from pastel tint to alpha.
2. Orange oklch values don't shift either; only `orangeSoft` swaps to the alpha form.
3. Canvas: `#F2F2F7` → `#000000`. Card: `#FFFFFF` → `#1C1C1E`. "Raised" card / sheet: `#FFFFFF` → `#2C2C2E`.
4. Every drop shadow used in light mode becomes a `1px inset white-alpha hairline` in dark mode. No shadows on dark cards.
5. Hairline inset on buttons (`surface` kind, `CircleBtn`): `hairline` token in both modes — the token itself handles the light/dark swap.
6. Colored icon tiles use the pastel hex in light and `rgba(tint, 0.18)` in dark. Never swap the tint hue.
7. Status-bar/nav text inherits `ink` — i.e., black on light, white on dark. Don't force white.
8. Charts: swap track `surfaceAlt` naturally; accent colors stay.

---

## 10. Gap analysis — current app vs Circuit target

What ships today, what needs work before adopting a screen:

| Area | Today | Circuit target | Action |
|---|---|---|---|
| Monospace data font (numerics) | JetBrains Mono via `AppFont`, applied unconditionally | JetBrains Mono, unconditional | ✅ none |
| Title/display font | User-selectable: `jetBrainsMono` (default) / `system` | User-selectable: `jetBrainsMono` (default) / `system` / `spaceGrotesk` (opt-in once bundled) | ℹ️ Bundle Space Grotesk TTFs and add `case spaceGrotesk` to `AppFontFamily` — see §4.1. JetBrains Mono stays the default before and after. |
| Font family selector UI | `FontSelectionView` with 2 options (`user_settings.font_family`) | Same view, 3 options | ℹ️ Adding the third case auto-extends the picker (it iterates `AppFontFamily.allCases`). Add `font.family.space_grotesk` localization key to all 7 `.lproj` files. |
| Brand green | Likely system green | `#0FA968` | 🛑 Add `CircuitColor.green` before adopting |
| Brand orange | Likely system orange | `oklch(0.72 0.18 28)` / `#FF8A4D` sRGB | 🛑 Add `CircuitColor.orange`; decide on hue-slider feature |
| Card radius | Verify per screen | 20 (default) / 28 (hero) | ℹ️ Audit `UserSettingsView`, `ExpensesView`, `ChargingSessionsView` card radii |
| Tab bar | SwiftUI default `TabView` | Floating glassy pill with FAB `+` | 🛑 Custom tab bar component required (non-trivial — current `MainTabView` uses stock `TabView`) |
| Dark mode | `AppearanceManager` supports light/dark/system | Canvas `#000`, inset hairlines | ℹ️ Token-level; land colors first, then verify card/shadow treatment on a per-screen basis |
| Large-title nav | Stock `.navigationTitle(...)` + `.navigationBarTitleDisplayMode(.automatic)` | Same iOS API; Circuit customizes weight to 800 (Space Grotesk) | ℹ️ `AppFontAppearance.swift` already sets `largeTitleTextAttributes` font — swap the family once Space Grotesk lands |
| `Section` headers | `Section(header: Text(...))` stock | Uppercase 13pt 600 `inkSoft` | ℹ️ Match via `appFont(.caption)` + `.textCase(.uppercase)` + `.foregroundColor(CircuitColor.inkSoft)` on the header label |
| Charts | SwiftUI `Chart` (if present) | Flat, gradient-filled sparklines + one-accent bar charts | ℹ️ Reskin existing charts; no architectural change |
| FAB `+` | No FAB | Green 52×52 FAB in tab bar center | 🛑 New component — ties to whichever `+` action each tab should surface |
| Map | No map UI shipping | Stylized mini-map with green→orange route | ℹ️ Defer until a trip/session-location feature needs it |

---

## 11. Adoption order (recommended)

Do not big-bang this. Roll out in this order so each step lands value independently:

1. **Color tokens first.** Add `CircuitColor` extension. Don't change any screen.
2. **Semantic `Card` view.** One SwiftUI view that wraps `.padding(16).background(CircuitColor.surface).cornerRadius(20)` + dark-mode shadow rule. Don't wrap everything at once.
3. **Section headers + eyebrow labels.** Low-risk typography refactor. Big perceived "iOS polish" gain.
4. **Chip component** — tiny, composable, 6 tints.
5. **Row / FormRow with icon tile.** Migrate one list at a time, starting with recently-edited screens.
6. **Bundle Space Grotesk + extend `AppFontFamily` to 3 cases.** Add TTFs per `ios-guidelines/font-guideline.md`, add `case spaceGrotesk`, update `AppFont.resolve` / `resolveUIFont`, add `font.family.space_grotesk` localization to all 7 `.lproj` files, update `MockUserSettingsRepository`. `FontSelectionView` picks up the new option automatically (it already iterates `allCases`). Numeric values stay on JetBrains Mono regardless of selection.
7. **Charts reskin.** Sparkline first (efficiency), then bar chart (monthly spend), then battery ring (car detail).
8. **Glassy floating tab bar + FAB.** This is the biggest deviation from stock — do last, behind a feature flag if possible, and verify dark-mode glass + safe-area inset handling on every device class before ship.
9. **Orange accent system.** Audit every place that currently uses a "system orange" or cost-related color, decide which get `CircuitColor.orange` and which get `.red` (warnings) or `.inkSoft` (neutral numbers).

Each step should land in isolation, pass tests, and be reviewable without the next. If you find yourself touching more than 2 of the above in one PR, stop and split.

---

## 12. Per-screen mapping (EV Charge Tracker tabs)

Reference translation from the current `MainTabView` tabs to Circuit screens found in the bundle.

| Current tab | View file | Closest Circuit screen | Notes |
|---|---|---|---|
| Stats | `ChargingSessionsView` | `ScreenHome` (dashboard half) + `ScreenInsights` | Hero live-charging card only applies if we add a real-time charging feature. For now, adopt the 3-up KPI strip, efficiency sparkline, and "Recent" session list. |
| Expenses | `ExpensesView` | `ScreenInsights` (breakdown + legend rows) + `ScreenAddExpense` (sheet) | Circuit's Add-Expense sheet is a full redesign of our current add flow — adopt after list adopts the `Row` pattern. |
| Car | `CarDetailsView` | No direct Circuit screen; assemble from `Card` + `BatteryRing` + `MiniMap` + `Row` | Use battery ring for state-of-charge if we add it; otherwise the car-info section is a `NavBar(large)` + `Card` stack with `FormRow`. |
| Settings | `UserSettingsView` | `ScreenSettings` in `screens_misc.jsx` | Keep existing `Form` → grouped-table structure. Replace custom rows with `Row`/icon-tile pattern. |

No screen in Circuit corresponds one-to-one with our `Developer` section or the new `FontSelectionView` / `FontPreviewView` — those stay on the current plain `Form` pattern until the broader redesign lands.

---

## 13. Open items / decisions deferred

- **Orange hue slider** — the prototype offers a runtime hue tweak (`TWEAK_DEFAULTS.orangeHue`). Decide whether to expose this as a user-facing setting (adds surface area) or bake a single accepted hue. Default: bake at `28°` / `#FF8A4D` for v1.
- **Forest / Voltage variations** — not captured here; if the design direction changes, this doc must be re-derived from the alternate variation files in the bundle.
- **Localized rendering across selectable display faces** — each `AppFontFamily` declares its own `supports(_:)` predicate and falls through to system when out of range. Verify per family before shipping: JetBrains Mono falls back today for several locales; Space Grotesk's coverage for `.kk` (Kazakh extended Cyrillic) and `.zhHans` (Simplified Chinese) is unverified and likely needs the same fallback. The system option always renders correctly via SF Pro / Dynamic Type.
- **Real MapKit adoption** — design shows a stylized map; if we ever render real tiles, decide on light/dark tile styles and whether to keep the green→orange route treatment.

---

## 14. Maintenance

This guideline is derived from a specific bundle state. If the source (prototype HTML/JSX) evolves:
1. Re-unpack the Claude Design handoff bundle.
2. Diff `tokens.jsx` and `widgets.jsx` against the values in sections 3–5 above.
3. Update this file first, then any code that has adopted the changed token.
4. If the design direction changes fundamentally (e.g. switch from "Circuit" to "Forest"), rewrite this file — don't layer a new variation on top.
