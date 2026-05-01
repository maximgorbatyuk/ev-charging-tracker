# Integration — Share Extension

For: anyone touching the `ShareExtension/` target or `BusinessLogic/` files that the extension consumes. For end-user flow / UI, see `../../ShareExtension/README.md`. For workspace-wide guideline, see `../../../ios-guidelines/share-extension-guideline.md`. Diagnostics: `[DIAG-001]`, `[DIAG-003]`, `[DIAG-009]` in `../diagnostics.md`.

## What it does

Lets the user share content from any other iOS app into EV Charge Tracker:

| Input kind | Saved as |
|---|---|
| Image | Document attached to active car |
| File (PDF, etc.) | Document attached to active car |
| URL (http/https) | Idea (link) attached to active car |
| Plain text | Idea (note) attached to active car |

The extension reuses `BusinessLogic/` (DB, repositories, models) so saved data appears immediately in the main app on next launch.

## Architecture

```
ShareExtension/
├── ShareViewController.swift    # NSExtensionPrincipalClass; UIKit shell
├── ShareFormView.swift          # SwiftUI form (uses SwiftUI.View explicitly)
├── ShareFormViewModel.swift     # @MainActor MVVM
├── InputParser.swift            # NSExtensionItem → SharedInput
├── Models/SharedInput.swift     # discriminated union of input kinds
├── Info.plist
└── ShareExtension.entitlements  # App Group only
```

Flow:

```
Host app
  → iOS dispatches NSExtensionItem(s) → ShareViewController
  → ShareFormViewModel calls InputParser.parse(inputItems:)
  → Parser produces SharedInput { kind, url|text|file, … }
  → User edits title/notes in ShareFormView
  → User taps Save → ViewModel writes via DocumentService / IdeasRepository
  → Extension dismisses
```

## Parser priority

`InputParser.parse(inputItems:)` (`ShareExtension/InputParser.swift:21-86`) walks attachments **in priority order**:

1. `UTType.image` → file (saved as document)
2. `UTType.fileURL` → file (saved as document)
3. `UTType.data` → file (saved as document, raw data written to a temp file with extension inferred from UTType)
4. `UTType.url` → link (saved as idea, unless the URL is `file://` in which case it's a file)
5. `UTType.plainText` → text (idea), or link if the text parses as `http(s)://...`

The first match wins. This matters when a host app dispatches *both* an image and a URL — the image takes priority.

## File-size cap

Share Extensions on iOS run with a hard memory limit of ~120 MB (varies by device). To stay well below it:

```swift
// InputParser.swift:17
private static let maxFileSizeBytes = 50 * 1024 * 1024 // 50 MB
```

Files above 50 MB are rejected with a warning log and treated as "no input." **Do not raise this without testing on the lowest-RAM supported device** — going over the OS limit kills the extension mid-flight with no user feedback.

## Temp files, not in-memory data

When the parser handles a file, it copies the source into `FileManager.default.temporaryDirectory` (`InputParser.copyToTempFile` / `writeTempFile`). The `SharedInput` carries a `tempFileURL` pointer; the actual save happens against that path. This avoids holding the entire file as a `Data` blob in memory.

## App Group container

The extension's `.entitlements` file lists the same App Group identifier as the main app (`$(APP_GROUP_IDENTIFIER)`). At runtime:

- `DatabaseManager.shared` opens `AppGroupContainer.databaseURL` — the same SQLite file the main app uses.
- `DocumentService` writes to `AppGroupContainer.documentsStorageURL/{carId}/`.

If the App Group capability is missing on either target, the extension and app see different DBs (`[DIAG-009]`).

## Compile-time pitfalls

### Pitfall 1: `View` ambiguity

`BusinessLogic/Database/DatabaseManager.swift:7` does `@_exported import SQLite`, which makes `SQLite.View` visible in every file that transitively imports it. In SwiftUI files compiled for the extension, bare `View` becomes ambiguous between `SwiftUI.View` and `SQLite.View`.

**Always write `SwiftUI.View` explicitly in `ShareExtension/`:**

```swift
struct ShareFormView: SwiftUI.View {
    var body: some SwiftUI.View { ... }
}
```

`MainTabView.swift` and `UserSettingsView.swift` in the main app also follow this defensively. See `[DIAG-001]`.

### Pitfall 2: Extension-unavailable APIs

Some `BusinessLogic/` files are excluded from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`:

| File | Why excluded |
|---|---|
| `BusinessLogic/Services/AnalyticsService.swift` | Imports `FirebaseAnalytics`, which the extension doesn't link |
| `BusinessLogic/Services/BackgroundTaskManager.swift` | Uses `BGTaskScheduler`, unavailable in app extensions |

When adding a new service to `BusinessLogic/Services/` that uses an extension-restricted API (`BGTaskScheduler`, `FirebaseAnalytics`, `UIApplication.shared`, `requestReview`, …), add it to the exception set. Test by building the `ShareExtension` scheme on its own. See `[DIAG-003]`.

### Pitfall 3: `Bundle.main` in extensions

`Bundle.main` inside an extension points to `*.appex`, not the containing app. Code in `BusinessLogic/` that reads `Info.plist` keys via `Bundle.main` works in the extension only when the same key is duplicated in `ShareExtension/Info.plist` — that is currently the case for `AppGroupIdentifier`.

`LocalizationManager` uses a different strategy: it detects `.appex` and walks up to the containing app bundle for `.lproj` resources (`LocalizationManager.swift:14-24`). Use that pattern if you need extension code to read app-target resources.

## Adding a new input kind — checklist

- [ ] Add a case to `SharedInput.kind` (`ShareExtension/Models/SharedInput.swift`).
- [ ] Add a parsing branch in `InputParser.parse(inputItems:)` at the appropriate priority position.
- [ ] Add a save path in `ShareFormViewModel`.
- [ ] Add UI state for the new kind in `ShareFormView`.
- [ ] Test with file > 50 MB (must reject) and exactly at the limit.
- [ ] Test from at least three host apps (Safari, Photos, Files) — input shapes vary.

## Failure modes

| Failure | Visible behavior | Where to look |
|---|---|---|
| File > 50 MB | Logged warning; parser returns nil; UI shows "no content found" | `InputParser.swift:97-100, 167-170` |
| App Group missing on extension | `AppGroupContainer.containerURL` fatal | `[DIAG-002]` |
| New `BusinessLogic/` file pulls in Firebase | Linker error in ShareExtension target | `[DIAG-003]` |
| Localization keys return raw key | Bundle resolution failed | `[DIAG-007]`, `localization.md` |

## Key files

- `ShareExtension/InputParser.swift` — parsing + size cap + temp-file plumbing
- `ShareExtension/ShareFormView.swift` — `SwiftUI.View` example
- `ShareExtension/ShareFormViewModel.swift` — save flow
- `ShareExtension/ShareViewController.swift` — UIKit entry, `NSExtensionPrincipalClass`
- `ShareExtension/Models/SharedInput.swift` — input data model
- `ShareExtension/ShareExtension.entitlements`
- `EVChargingTracker.xcodeproj/project.pbxproj` — target file exception set
- `BusinessLogic/Database/DatabaseManager.swift:7` — the source of `View` ambiguity
- `BusinessLogic/Services/LocalizationManager.swift:14-24` — `.appex` upward walk
