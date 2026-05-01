# Localization

For: anyone adding or changing user-facing strings, or debugging "key shows instead of text." For diagnostics, see `[DIAG-007]` in `diagnostics.md`. For workspace-wide standards, see `../../ios-guidelines/font-guideline.md` (font fallbacks) and `../../ios-guidelines/onboarding-guideline.md` (language picker UX).

## Supported languages

Seven languages, all hand-translated:

| Code | Language | Translator |
|---|---|---|
| `en` | English | (project owner) |
| `de` | Deutsch | @aamiirkaa |
| `ru` | Русский | (project owner) |
| `kk` | Қазақша | @shyngysn |
| `tr` | Türkçe | @tolgasanci |
| `uk` | Українська | (project owner) |
| `zh-Hans` | 简体中文 | (project owner) |

Source-of-truth list: `enum AppLanguage` in `BusinessLogic/Models/UserSettings.swift:15-35`.

## How it works

This project uses **runtime language switching**, not iOS's per-app locale override. The user picks a language inside the app (Settings → Language, or Onboarding step 1) and `LocalizationManager` writes it to the `user_settings` SQLite table. The next `L("key")` call reads from the matching `.lproj` bundle directly via `Bundle.path(forResource:ofType:)`.

```swift
// LocalizationManager.swift
let path = base.path(forResource: language.rawValue, ofType: "lproj")
let bundle = Bundle(path: path)
return bundle.localizedString(forKey: key, value: key, table: nil)
```

If the language bundle can't be found, fall back to the base bundle, which falls back to returning the key string itself.

## The `L()` global

```swift
// BusinessLogic/Services/LocalizationManager.swift:68-74
func L(_ key: String) -> String { ... }
func L(_ key: String, language: AppLanguage) -> String { ... }
```

**Always** use `L()` for user-facing strings. **Never** `Text("Hardcoded")`.

```swift
// Right
Text(L("expenses.title"))

// Wrong — bypasses i18n
Text("Expenses")
```

## Where strings live

```
EVChargingTracker/
├── en.lproj/Localizable.strings
├── de.lproj/Localizable.strings
├── ru.lproj/Localizable.strings
├── kk.lproj/Localizable.strings
├── tr.lproj/Localizable.strings
├── uk.lproj/Localizable.strings
└── zh-Hans.lproj/Localizable.strings
```

The Share Extension does **not** ship its own `.lproj` files. `LocalizationManager` detects when running inside a `.appex` and walks up to the containing app bundle to find `.lproj` resources (`LocalizationManager.swift:14-24`). This means: keys must live in the main app's `.lproj` files, even when consumed by extension UI.

## Adding a new key — checklist

- [ ] Add the key to `EVChargingTracker/en.lproj/Localizable.strings` first (always).
- [ ] Add translations to `de.lproj`, `ru.lproj`, `kk.lproj`, `tr.lproj`, `uk.lproj`, `zh-Hans.lproj`.
- [ ] Use it: `Text(L("your.key"))` in views, `let title = L("your.key")` in view models.
- [ ] Verify by switching language in Settings during a debug run.

If a key is missing from a non-English file, that single language falls through to the raw key (not English) — there is no "fall through to English" behavior. Keep all seven files in sync.

## Reactivity

Views that need to re-render on language change should observe `LocalizationManager.shared`:

```swift
@ObservedObject private var loc = LocalizationManager.shared

var body: some SwiftUI.View {
    TabView { ... }
        .id(loc.currentLanguage.rawValue)   // force-rebuild on language change
}
```

The `.id(loc.currentLanguage.rawValue)` trick on `MainTabView` (`MainTabView.swift:64`) forces the entire tab hierarchy to rebuild when the user switches language, picking up new strings even in deep child views that didn't observe the manager.

## Persistence

Selected language is stored in `user_settings.value` under key `language` (raw value of `AppLanguage`, e.g. `"en"`, `"zh-Hans"`).

`UserSettingsRepository.upsertLanguage()` / `fetchLanguage()` are the only writers/readers. Default on a fresh install (or unreadable value) is `.en`.

## Special: Bundle.main in extensions

`Bundle.main` inside an app extension points to `*.appex`, **not** the containing app. If you read other resources via `Bundle.main` in code shared with the extension, account for this. `EnvironmentService.getAppGroupIdentifier()` works because `AppGroupIdentifier` is duplicated in both `EVChargingTracker/Info.plist` and `ShareExtension/Info.plist`. `LocalizationManager` works because it walks up from `.appex`. Anything else that wants to read app-target Info.plist values from the extension needs the same upward walk.

## Key files

- `BusinessLogic/Models/UserSettings.swift:15-35` — `AppLanguage` enum
- `BusinessLogic/Services/LocalizationManager.swift` — runtime switcher and `L()` global
- `BusinessLogic/Database/UserSettingsRepository.swift:104-113` — language persistence
- `EVChargingTracker/*.lproj/Localizable.strings` — string tables (one per language)
- `EVChargingTracker/Onboarding/OnboardingLanguageSelectionView.swift` — first-launch picker
- `EVChargingTracker/UserSettings/UserSettingsView.swift` — in-app language picker
