# ShareExtension (extension target)

Bundle ID: `mgorbatyuk.dev.EVChargeTracker.ShareExtension`. Min iOS: 18.0.

For: developers picking up the share extension. For full architectural detail and pitfalls, see `../docs/integrations/share-extension.md`. For the workspace-wide guideline, see `../../ios-guidelines/share-extension-guideline.md`.

## What it does

Lets the user share content from any iOS app into EV Charge Tracker:

| Input | Saved as |
|---|---|
| Image | Document attached to active car |
| File (PDF, etc.) | Document attached to active car |
| URL | Idea (link) attached to active car |
| Text | Idea (note) attached to active car |

Backed by the same SQLite DB as the main app, via the App Group container.

## Files

```
ShareExtension/
├── ShareViewController.swift       # NSExtensionPrincipalClass; UIKit shell
├── ShareFormView.swift             # SwiftUI form (uses SwiftUI.View explicitly!)
├── ShareFormViewModel.swift        # @MainActor MVVM
├── InputParser.swift               # NSExtensionItem → SharedInput; size cap; temp files
├── Models/
│   └── SharedInput.swift           # Input data model (kind + payload)
├── Info.plist
└── ShareExtension.entitlements     # App Group only
```

The extension reuses everything in `../BusinessLogic/` except files explicitly excluded from the target (currently `Services/AnalyticsService.swift` and `Services/BackgroundTaskManager.swift` — see `../docs/integrations/share-extension.md`).

## Building / running

The extension is built as part of the main app scheme. You can also pick the `ShareExtension` scheme directly to verify it builds in isolation — useful for catching extension-target issues like extension-unavailable APIs or `View` ambiguity early.

To test on simulator:

1. Build & run the main app once (registers the extension).
2. Open a host app (Safari, Photos, Files).
3. Tap Share → "EV Charge Tracker" in the share sheet.

## Hard rules

These come up often enough to surface here; the longer rationale is in `../docs/integrations/share-extension.md`.

- **Always write `SwiftUI.View` explicitly** in any SwiftUI file in this target. Bare `View` is ambiguous because `BusinessLogic/Database/DatabaseManager.swift:7` does `@_exported import SQLite`, surfacing `SQLite.View` globally.
- **50 MB file-size cap** in `InputParser.swift:17`. Don't raise without testing the lowest-RAM supported device — the OS kills extensions over ~120 MB.
- **Temp files, not in-memory data.** Parser copies sources into `FileManager.default.temporaryDirectory`. The extension is memory-constrained.
- **Don't import `FirebaseAnalytics` or `BackgroundTasks`** in any file that compiles into this target. If `BusinessLogic/` adds a service that does, exclude it via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`.
- **`Bundle.main` points to `*.appex`, not the host app.** Use `LocalizationManager`'s upward-walk pattern if you need to read app-target resources from extension code.

## Parser priority

`InputParser.parse(inputItems:)` tries types in this order; first match wins:

1. `UTType.image` → file
2. `UTType.fileURL` → file
3. `UTType.data` → file
4. `UTType.url` → link (or file if `file://`)
5. `UTType.plainText` → text (or link if it parses as HTTP URL)

When a host dispatches both an image and a URL, the **image** wins. If you change priority, also update the test for that scenario.

## Failure modes

| Symptom | See |
|---|---|
| Build error: `View` ambiguous | `[DIAG-001]` in `../docs/diagnostics.md` |
| Linker error referencing Firebase / BGTaskScheduler | `[DIAG-003]` |
| Extension can't see main-app data | `[DIAG-009]` |
| File over 50 MB silently rejected | Expected. Logged via OSLog. |

## Key files

- `ShareExtension/InputParser.swift` — parsing, size cap, temp files
- `ShareExtension/ShareFormView.swift` — `SwiftUI.View` example
- `ShareExtension/ShareFormViewModel.swift` — save flow
- `ShareExtension/ShareViewController.swift` — UIKit entry
- `ShareExtension/Models/SharedInput.swift`
- `ShareExtension/ShareExtension.entitlements`
- `EVChargingTracker.xcodeproj/project.pbxproj` — target file exception set
