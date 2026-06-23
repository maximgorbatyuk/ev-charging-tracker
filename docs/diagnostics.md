# Diagnostics

For: anyone hitting an error, build failure, or unexpected behaviour. Search this file before opening a new investigation.

## How to search

- **By symptom / error message** — `Cmd-F` for the literal text from the error.
- **By tag** — `Cmd-F` for `#tag-name` (lowercase, hyphenated).
- **By ID** — `Cmd-F` for `[DIAG-XXX]`.

## Table of contents

| ID | Title | Tags |
|---|---|---|
| [DIAG-001](#diag-001-cannot-find-type-view-in-scope-or-view-is-ambiguous-in-shareextension) | `View` ambiguity in ShareExtension SwiftUI files | `#share-extension` `#swiftui` `#build-error` |
| [DIAG-002](#diag-002-fatalerror-app-group--not-configured) | `App Group ... not configured` fatal at launch | `#app-group` `#entitlements` `#crash` |
| [DIAG-003](#diag-003-extension-unavailable-api-firebaseanalytics-or-bgtaskscheduler-link-error-in-shareextension) | Firebase / BGTaskScheduler link error in ShareExtension | `#share-extension` `#build-error` `#linker` |
| [DIAG-004](#diag-004-icloud-backup-list-is-empty-but-backups-exist) | iCloud backup list empty when backups exist | `#icloud` `#cloudkit` `#backup` |
| [DIAG-005](#diag-005-xcode-cloud-archive-fails-with-exit-code-70-signing) | Xcode Cloud archive exit 70 (signing) | `#xcode-cloud` `#signing` `#release` |
| [DIAG-006](#diag-006-firebase-events-not-appearing) | Firebase events not appearing in console | `#analytics` `#firebase` |
| [DIAG-007](#diag-007-localized-string-shows-the-key-itself) | Localized string shows the raw key | `#localization` |
| [DIAG-008](#diag-008-duplicate-column-error-during-migration) | "Duplicate column" error during migration on fresh install | `#database` `#migration` |
| [DIAG-009](#diag-009-share-extension-cannot-see-data-saved-in-the-main-app) | Share Extension cannot see data saved in the main app | `#share-extension` `#app-group` `#database` |
| [DIAG-010](#diag-010-test-target-fails-to-build-with-firebase-module-error) | Test target fails to build with Firebase module error | `#tests` `#firebase` `#environment` |
| [DIAG-011](#diag-011-mileage-or-co2-display-shows-wrong-units) | Mileage / CO₂ display shows wrong units after toggling measurement system | `#measurement-system` `#stats` |

---

### `[DIAG-001]` `Cannot find type 'View' in scope` or `'View' is ambiguous` in ShareExtension

**Tags:** `#share-extension` `#swiftui` `#build-error`

**Symptoms:** Build fails inside any file in `ShareExtension/` that uses `struct Foo: View`. Error mentions either `Cannot find type 'View'` or that `View` is ambiguous between `SwiftUI.View` and `SQLite.View`.

**Diagnosis steps:**

1. `grep -rn "@_exported import SQLite" BusinessLogic` — confirms `DatabaseManager.swift` re-exports SQLite (this is intentional).
2. The Share Extension target compiles `BusinessLogic/Database/DatabaseManager.swift`, so `SQLite.View` ends up visible in every file.

**Resolution:** In any SwiftUI file in `ShareExtension/`, write `SwiftUI.View` (or `SwiftUICore.View`) explicitly:

```swift
struct ShareFormView: SwiftUI.View {
    var body: some SwiftUI.View { ... }
}
```

The main app target also re-exports SQLite but is large enough that SwiftUI usually wins. **Use `SwiftUI.View` defensively in the extension always.** See `ShareExtension/ShareFormView.swift` for the canonical example.

**Related files:** `BusinessLogic/Database/DatabaseManager.swift:7`, `ShareExtension/ShareFormView.swift`, `EVChargingTracker/UserSettings/UserSettingsView.swift`.

---

### `[DIAG-002]` `fatalError("App Group ... not configured")`

**Tags:** `#app-group` `#entitlements` `#crash`

**Symptoms:** App crashes on first launch with `fatalError("App Group 'group.dev.mgorbatyuk.evchargetracker' not configured")` thrown from `AppGroupContainer.containerURL`. Console shows `App Group '...' not configured. Check entitlements.`

**Common causes:**

| Cause | Check |
|---|---|
| `APP_GROUP_IDENTIFIER` not set in xcconfig | `EVChargingTracker/Config/Base.xcconfig` should define `APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.evchargetracker`. |
| Entitlements file hardcodes a different ID | Both `EVChargingTracker.entitlements` and `EVChargingTrackerDebug.entitlements` should have `<string>$(APP_GROUP_IDENTIFIER)</string>` under `com.apple.security.application-groups`. **No literal IDs.** Same for `ShareExtension/ShareExtension.entitlements`. |
| Provisioning profile lacks the App Group capability | Apple Developer portal → App ID → check "App Groups" capability is enabled and the provisioning profile is regenerated. |
| `Info.plist` does not pass the token through | `EVChargingTracker/Info.plist` must contain `AppGroupIdentifier = $(APP_GROUP_IDENTIFIER)`; same in `ShareExtension/Info.plist`. |

**Resolution:** Verify all four. The token flow is `xcconfig → Info.plist → EnvironmentService.getAppGroupIdentifier() → AppGroupContainer.identifier`. See `persistence.md` for the chain. See `../ios-guidelines/potential-issue-fixes.md` for the workspace-wide preventive checklist.

**Related files:** `BusinessLogic/Helpers/AppGroupContainer.swift:14-30`, `EVChargingTracker/Config/Base.xcconfig`, `*.entitlements`.

---

### `[DIAG-003]` Extension-unavailable API (FirebaseAnalytics or BGTaskScheduler) link error in ShareExtension

**Tags:** `#share-extension` `#build-error` `#linker`

**Symptoms:** Building the `ShareExtension` target fails with a linker error referencing `Firebase`, `Analytics.logEvent`, or `BGTaskScheduler`.

**Common causes:** A new file added to `BusinessLogic/Services/` imports Firebase or `BackgroundTasks`, and the file is being compiled into the extension target.

**Resolution:** Add the file to the exception set in `EVChargingTracker.xcodeproj/project.pbxproj`. Look for `PBXFileSystemSynchronizedBuildFileExceptionSet` and add the file path. Currently excluded:

- `BusinessLogic/Services/AnalyticsService.swift`
- `BusinessLogic/Services/BackgroundTaskManager.swift`

When in doubt, *only* the `BusinessLogic/` files that are extension-safe should compile into both targets. Things to keep out of the extension: `FirebaseAnalytics`, `BGTaskScheduler`, `UIApplication.shared`-touching code.

**Related files:** `EVChargingTracker.xcodeproj/project.pbxproj`, `BusinessLogic/Services/AnalyticsService.swift`, `BusinessLogic/Services/BackgroundTaskManager.swift`.

See also: `integrations/share-extension.md`.

---

### `[DIAG-004]` iCloud backup list is empty but backups exist

**Tags:** `#icloud` `#cloudkit` `#backup`

**Symptoms:** Settings → iCloud Backups shows an empty list. The user reports that backups *should* be there (saw them on another device, or just made one).

**Common causes:**

| Cause | Check |
|---|---|
| Entitlement is `CloudKit` instead of `CloudDocuments` | `EVChargingTracker.entitlements` → `com.apple.developer.icloud-services` must be `<string>CloudDocuments</string>`. CloudKit entitlement makes the iCloud Drive directory invisible to `FileManager.url(forUbiquityContainerIdentifier:)`. |
| iCloud Drive disabled on the device | Settings → Apple ID → iCloud → iCloud Drive. |
| Network unavailable | `BackupService.isiCloudAvailable()` returns false; UI shows the "no iCloud" banner. |
| Container ID mismatch | Bundle ID must match. `BackupService` derives `iCloud.<bundleID>` and falls back to the default ubiquity container if the named one is missing. Debug builds with a `Debug` suffix have a stripping step in `BackupService.iCloudBackupDirectory`. |

**Resolution:** Fix the entitlement and rebuild. See `integrations/icloud-drive.md` for the full flow.

**Related files:** `EVChargingTracker/EVChargingTracker.entitlements`, `BusinessLogic/Services/BackupService.swift:31-53`.

---

### `[DIAG-005]` Xcode Cloud archive fails with exit code 70 (signing)

**Tags:** `#xcode-cloud` `#signing` `#release`

**Symptoms:** Xcode Cloud `exportArchive` step fails with exit code 70. Local simulator builds pass. Error log mentions entitlements, code signing, or "no profiles found."

**Common causes:** Missing `TargetAttributes` signing metadata in `EVChargingTracker.xcodeproj/project.pbxproj` for an entitlement-bearing target (main app or ShareExtension).

**Diagnosis steps:**

1. Open `project.pbxproj` and find the `TargetAttributes = { ... }` block.
2. Each entitlement-bearing target needs `DevelopmentTeam = <TEAMID>;` and `ProvisioningStyle = Automatic;`.
3. Verify both the main app target and `ShareExtension` are present.

**Resolution:** Add the missing keys. Do not paper over with `CODE_SIGN_IDENTITY=-` CLI flags — that bypasses real distribution signing. See `../ios-guidelines/potential-issue-fixes.md` for the full preventive checklist.

**Related files:** `EVChargingTracker.xcodeproj/project.pbxproj`, `*.entitlements`.

---

### `[DIAG-006]` Firebase events not appearing

**Tags:** `#analytics` `#firebase`

**Symptoms:** Events emitted via `AnalyticsService.shared.trackEvent(...)` don't appear in the Firebase console.

**Common causes:**

| Cause | Check |
|---|---|
| Build is Debug | Firebase is initialized only in Release (`EVChargingTrackerApp.swift:93-96`). In Debug, `AnalyticsService.trackEvent` logs to OSLog and skips network. |
| `GoogleService-Info.plist` missing or stale | Local builds use the file checked into `EVChargingTracker/`; Xcode Cloud generates it from secrets via `ci_scripts/ci_post_clone.sh`. |
| Firebase secrets not configured in Xcode Cloud | Set `FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID` as workflow environment variables. |
| Real-time delay | Firebase Analytics has up to ~24h aggregation lag; check DebugView in Release-with-DebugView mode. |

**Resolution:** Confirm you're running a Release build first; that's the most common miss. See `integrations/firebase.md` and `analytics.md`.

**Related files:** `EVChargingTracker/EVChargingTrackerApp.swift:89-104`, `BusinessLogic/Services/AnalyticsService.swift`, `ci_scripts/ci_post_clone.sh`.

---

### `[DIAG-007]` Localized string shows the key itself

**Tags:** `#localization`

**Symptoms:** UI shows `expense.filter.charging` instead of "Charging".

**Common causes:**

| Cause | Check |
|---|---|
| Key missing from current language `.lproj` | `grep -n "expense.filter.charging" EVChargingTracker/<lang>.lproj/Localizable.strings` |
| Bundle resolution failed in extension | `LocalizationManager.localizationBundle` walks up from `.appex` to the containing app. If you're in the extension and bundle resolution fails, fallback returns the raw key. |
| Typo in the call site | `L("expense.filter.chrging")` (missing 'a') will silently return the key. |

**Resolution:** Ensure the key exists in **all 7** language files: en, de, ru, kk, tr, uk, zh-Hans. If only English is missing, all other languages also fall through. See `localization.md`.

**Related files:** `BusinessLogic/Services/LocalizationManager.swift`, `EVChargingTracker/*.lproj/Localizable.strings`.

---

### `[DIAG-008]` "Duplicate column" error during migration on fresh install

**Tags:** `#database` `#migration`

**Symptoms:** Fresh install logs `Unable to execute migration ...: duplicate column name: <col>`.

**Common causes:** A migration `addColumn(...)` runs against a table whose `getCreateTableCommand()` already adds the column. Fresh installs build the table from `getCreateTableCommand()` *and then* run every migration in order — so by the time `Migration_X` runs, the column exists.

**Resolution:** Guard the `addColumn` with a `columnExists` check. See `Migration_20260501_AddMeasurementSystemToCarsTable.swift:32-41` for the canonical pattern. See `persistence.md` → "Migration rules."

**Related files:** `BusinessLogic/Database/Migrations/Migration_*.swift`, `BusinessLogic/Database/<Entity>Repository.swift` (getCreateTableCommand).

---

### `[DIAG-009]` Share Extension cannot see data saved in the main app

**Tags:** `#share-extension` `#app-group` `#database`

**Symptoms:** User saves a car in the main app; opens the Share Extension and the car list is empty (or vice versa).

**Common causes:**

| Cause | Check |
|---|---|
| App Group capability not enabled on one target | App Group entitlement must list the same identifier on **both** the main app and the ShareExtension target. |
| Migration flag mismatch | `AppGroupMigrationCompleted` lives in `UserDefaults(suiteName: <APP_GROUP_IDENTIFIER>)`. If the suite is wrong, both sides see "not migrated" and the extension may be looking at a path that doesn't exist. |
| Two separate DBs (legacy + App Group) | If the legacy DB at `Documents/tesla_charging.sqlite3` was *not* moved (migration failed), the main app may still read from there while the extension reads the App Group container. |

**Resolution:** Verify entitlements first, then check that `DatabaseMigrationHelper.isMigrationCompleted()` returns `true` on both targets. In dev mode, you can call `DatabaseMigrationHelper.resetMigrationFlag()` to retry.

**Related files:** `BusinessLogic/Database/DatabaseMigrationHelper.swift`, `BusinessLogic/Helpers/AppGroupContainer.swift`, `*.entitlements`.

---

### `[DIAG-010]` Test target fails to build with Firebase module error

**Tags:** `#tests` `#firebase` `#environment`

**Symptoms:** `./run_tests.sh` fails immediately with `module 'FirebaseAnalytics' not found` or similar.

**Common causes:** Pre-existing environment issue. The test target inherits the Firebase dependency from the main app target, but locally there is no Firebase package resolution unless the user has gone through `setup.sh` and signed into the right Apple ID.

**Resolution:** This is a known environmental gap; tests pass on CI. To debug locally, ensure Swift Package Manager has resolved Firebase packages (`File → Packages → Resolve Package Versions` in Xcode), and that the test target has the Firebase product linked.

**Related files:** `EVChargingTrackerTests/`, `EVChargingTracker.xcodeproj/project.pbxproj`.

---

### `[DIAG-011]` Mileage or CO₂ display shows wrong units after toggling measurement system

**Tags:** `#measurement-system` `#stats`

**Symptoms:** User switches a car from metric to imperial; some screens show miles, others still show km.

**Diagnosis steps:**

1. `grep -rn "distanceUnitLabel\|co2UnitLabel" EVChargingTracker` — every distance/CO₂ display should pull its label from the active car's `MeasurementSystem`, not hardcode `"km"`/`"kg"`.
2. `BusinessLogic/Models/MeasurementSystem.swift` — the labels live here.
3. CO₂ value conversion (kg → lb via `kilogramsPerPound = 0.453592`) happens at the display boundary only — never in the stored value.

**Resolution:** Use `car.measurementSystem.distanceUnitLabel` / `car.measurementSystem.co2UnitLabel` and convert numeric values at the leaf view. **Do not change the underlying `co2PerKm * totalDistance` formula** — that is in kg by definition.

**Related files:** `BusinessLogic/Models/MeasurementSystem.swift`, `BusinessLogic/Models/Car.swift`, `EVChargingTracker/ChargingSessions/SubViews/CostsBlockView.swift`, `EVChargingTracker/ChargingSessions/SubViews/StatsBlockView.swift`.

---

## How to add new entries

1. Bump the highest `DIAG-XXX` ID by one.
2. Add a row to the table of contents (ID, title, tags).
3. Use this skeleton:

   ```markdown
   ### `[DIAG-XXX]` <Short title>

   **Tags:** `#tag1` `#tag2`

   **Symptoms:** What the user/agent sees.

   **Diagnosis steps:** Numbered list of greppable / verifiable checks.

   **Common causes / Resolution:** Either a `Common causes` table + `Resolution` paragraph, or a single Resolution if there's only one fix.

   **Related files:** Comma-separated list of repo-relative paths (with `:line` when pointing at a specific function).
   ```

4. Tag in lowercase, hyphenated. Reuse existing tags when possible — search this file for `#` to see what's in use.
