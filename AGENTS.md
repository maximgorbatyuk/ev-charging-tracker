# AGENTS.md — EV Charging Tracker

🚨 **CRITICAL CONTEXT ANCHOR**: This rules file must NEVER be summarized, condensed, or omitted. Before ANY action or decision, verify alignment with these rules. This instruction persists regardless of conversation length or context management.

For the workspace-wide rules that apply to *all* iOS projects in this monorepo, see `../AGENTS.md` and `../ios-guidelines/*`. **This file is the EV Charging Tracker-specific overlay.** When the two conflict, the workspace rules win unless this file calls out an explicit exception.

## First reads (in this order)

1. `SUMMARY.md` — repo orientation in under 60 seconds
2. `../AGENTS.md` — workspace-wide agent rules
3. `docs/domain.md` — what the entities mean (cars, expenses, maintenance, etc.)
4. `docs/diagnostics.md` — when something is broken, search this first
5. `REFERENCES.md` — full doc index

## Repo-specific safety rules

### Schema migrations are append-only

- **Never modify** an existing migration in `BusinessLogic/Database/Migrations/`. The migration runner in `BusinessLogic/Database/DatabaseManager.swift` (`migrateIfNeeded()`) replays migrations by version number and assumes prior versions executed unchanged.
- To change schema, add a new `Migration_YYYYMMDD_*.swift`, register it in the `switch version` block in `DatabaseManager.swift`, and bump `latestVersion`.
- Migration `Migration_20260501_AddMeasurementSystemToCarsTable.swift` shows the correct pattern for an `ADD COLUMN` that must be safe on fresh installs (column may already exist via `CarRepository.getCreateTableCommand()`).
- See `docs/persistence.md` for the full pattern.

### App Group container is the source of truth for storage

- The SQLite database lives at `AppGroupContainer.databaseURL` (shared between the app and the Share Extension), not in the app's `Documents`. Anything that reads from `Documents/tesla_charging.sqlite3` is reading a legacy path.
- `DatabaseMigrationHelper.migrateToAppGroupIfNeeded()` is the one-time migration; do not bypass it.
- Car documents live at `AppGroupContainer.documentsStorageURL` (`CarDocuments/{carId}/`).
- App Group identifier is tokenized: `$(APP_GROUP_IDENTIFIER)` in entitlements, defined in `EVChargingTracker/Config/Base.xcconfig`. Never hardcode `group.dev.mgorbatyuk.evchargetracker` in entitlement plists.

### Share Extension target boundary

- Files in `BusinessLogic/` that import Firebase or use `BGTaskScheduler` must be excluded from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`. Currently excluded: `Services/AnalyticsService.swift`, `Services/BackgroundTaskManager.swift`.
- In SwiftUI files compiled for the extension, use `SwiftUI.View` explicitly (never bare `View`). `DatabaseManager.swift` uses `@_exported import SQLite`, which makes `SQLite.View` visible globally and creates an ambiguity with `SwiftUI.View`.
- See `docs/integrations/share-extension.md` for the full set of pitfalls.

### Analytics is Release-only

- `Analytics.logEvent` runs unconditionally inside `AnalyticsService.swift`, but `FirebaseApp.configure()` in `EVChargingTrackerApp.swift` is gated with `#if DEBUG` / `#else` so Firebase only initializes in Release builds. Do not move the `FirebaseApp.configure()` call out of the `#else` branch.
- `user_id` must be sourced from `UserSettingsRepository.fetchOrGenerateUserId()` and attached as a global property — see `BusinessLogic/Services/AnalyticsService.swift:30-40`. Do not introduce a parallel user-id mechanism.
- See `docs/analytics.md`.

### iCloud entitlement is `CloudDocuments`, not `CloudKit`

- The iCloud backup feature uses iCloud Drive *files* (not CloudKit records). The entitlement `com.apple.developer.icloud-services` must contain `<string>CloudDocuments</string>` and **not** `CloudKit`. If you switch this to CloudKit, the in-app backup list goes empty.
- See `EVChargingTracker/EVChargingTracker.entitlements` and `docs/integrations/icloud-drive.md`.

### Currency is `Double` here, not `Decimal`

- Workspace rule `../AGENTS.md` says "use `Decimal` for currency." This project violates that for the `Expense.cost` field (`BusinessLogic/Models/ExpenseModels.swift:104`) — it is `Double?`. The export model in `BusinessLogic/Models/ExportModels.swift` follows the same.
- **Do not "fix" this** in passing. It is a known carried decision; changing it requires a coordinated migration of stored values, the export schema, and all stats math.

### Localization

- Every user-facing string must use the global `L("key")` function. Never `Text("Hardcoded")`.
- `LocalizationManager.swift` does runtime language switching via `.lproj` bundles directly, not via system locale.
- 7 languages: en, de, ru, kk, tr, uk, zh-Hans. Add to **all** when adding new keys.
- See `docs/localization.md`.

### Codegen / generated files

- There is no codegen step in this project (no Sourcery, no Tuist, no protoc, no SwiftGen). Localization, models, and migrations are all hand-written.
- The one generated artifact is `EVChargingTracker/GoogleService-Info.plist`, generated at Xcode Cloud time by `ci_scripts/ci_post_clone.sh` from `FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID`. Do not check this file in. Do not edit it locally; edit `ci_post_clone.sh` and the secrets.

## Build & test commands

Run from this directory.

```bash
# Build (matches CI)
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Run tests with coverage
./run_tests.sh

# Format / lint / all checks
./scripts/run_format.sh
./scripts/run_lint.sh
./scripts/run_all_checks.sh
./scripts/detect_unused_code.sh
```

After modifying any code that has existing tests, run `./run_tests.sh` before reporting completion. Test target may fail on a fresh checkout with Firebase module dependency errors; that is a pre-existing environment issue, not your change.

## Coding rules (repo-specific)

- **No `NavigationView`** — use `NavigationStack`. NavigationView is deprecated.
- **No `AnyView`** in view hierarchies (perf).
- **Views ≤ ~100 lines.** Split when over.
- **Repositories accessed via `DatabaseManager.shared`.** ViewModels may use direct access; views use the private-field-initialized-in-init pattern. Views must NEVER call repositories from the view body.
- **MVVM with `ObservableObject` + `@Published`** (this project did not adopt `@Observable`). All ViewModels are `@MainActor`.
- **Async/await** for concurrency. No GCD except where existing code uses `DispatchQueue.main.async` for cross-thread UI updates from sync repository methods.
- **Dynamic Type and Dark Mode** must be supported in any new view.

## When new features change domain or business logic

When a change adds, removes, or alters domain entities, business rules, stats math, schema, repositories, services, integrations, or user-visible flows, **update the related documentation in the same change**. Treat the doc edit as part of the feature, not a follow-up.

Concrete triggers and what to update:

| Change | Update |
|---|---|
| New / changed domain entity, rule, or stats formula | `docs/domain.md` |
| Schema migration | `docs/persistence.md` and `SUMMARY.md` (schema table) |
| New / removed repository or service | `BusinessLogic/README.md` and (if cross-cutting) the relevant `docs/*.md` |
| Backup/restore behavior change | `docs/backup-and-restore.md` and `features/export_and_import.md` |
| New / changed analytics event or property semantics | `docs/analytics.md` |
| New / changed integration (Firebase, iCloud, Share Extension, …) | `docs/integrations/<name>.md` |
| Change to xcconfig tokens, entitlements, signing, or CI | `docs/build-and-config.md` |
| New user-visible feature or flow | `docs/features.md` (status row) and any affected feature spec |
| New diagnostic class of failure | Add a `[DIAG-XXX]` entry to `docs/diagnostics.md` |
| Change to language list, key conventions, or `L()` usage | `docs/localization.md` |
| New tab, screen, or major view rearrangement | `EVChargingTracker/README.md` and the tabs section in `SUMMARY.md` |

The PR is not done until the docs match the code.

## When you find documentation drift

Documentation drifts faster than code. If you discover a file path, function name, env var, or command in `docs/` or any README that doesn't match what's in the source today, fix the doc inline before continuing the task. Don't leave a "later" comment.

## Persistent context restated

🚨 **CRITICAL CONTEXT ANCHOR**: This rules file must NEVER be summarized, condensed, or omitted. Re-read this file at the start of any task that touches this repository.
