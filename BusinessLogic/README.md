# BusinessLogic (shared module)

Shared Swift code compiled into both the `EVChargingTracker` and `ShareExtension` targets. No external module — files are added to both targets' build phases (or excluded via the project's file-exception set when target-restricted).

For: developers adding services, repositories, or models. For DB mechanics, see `../docs/persistence.md`. For domain meaning, see `../docs/domain.md`. For extension target boundaries, see `../docs/integrations/share-extension.md`.

## In scope

- SQLite repositories and migrations (`Database/`)
- Domain models — `Car`, `Expense`, `PlannedMaintenance`, `CarDocument`, `Idea`, `UserSettings`, `MeasurementSystem`, `Currency` (`Models/`)
- Cross-cutting services — `AnalyticsService` (main-app only), `BackgroundTaskManager` (main-app only), `BackupService`, `DocumentService`, `EnvironmentService`, `LocalizationManager`, `NetworkMonitor`, `NotificationManager`, `AppearanceManager`, `AppFontFamilyManager`, `AppVersionChecker` (`Services/`)
- App Group path resolution (`Helpers/AppGroupContainer.swift`)
- Plain value types passed between layers (`ValueObjects/`)
- Lightweight error types (`Errors/`)
- Foundation-level extensions (`Extensions/`)
- Confirmation/alert payloads (`Alerts/`)

## Out of scope

- **No SwiftUI views.** UI lives in `EVChargingTracker/` and `ShareExtension/`. The one trace of UI here is `Services/IExpenseView.swift`, a tiny protocol used by view models — not a view itself.
- **No view models.** ViewModels live in their target directory next to the view they back.
- **No assets.** Images, fonts, colors, and `.xcassets` belong to the consuming target.
- **No localized string tables.** `Localizable.strings` files live under `EVChargingTracker/*.lproj/`. `LocalizationManager` reads them; it does not own them.
- **No CI / scripts.**
- **No app-target-only frameworks** if the file is also compiled into the extension. If a service must use `FirebaseAnalytics`, `BGTaskScheduler`, `UIApplication.shared`, `requestReview`, or any other extension-restricted API, exclude its file from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`. Currently excluded: `Services/AnalyticsService.swift`, `Services/BackgroundTaskManager.swift`.

## Public surface

### Database

`DatabaseManager.shared` is the entry point. It owns a single `Connection` and exposes one repository per table (or via the `*RepositoryProtocol` of `DatabaseManagerProtocol` if you need testability).

```swift
// Direct access (ViewModels)
DatabaseManager.shared.expensesRepository?.fetchPaged(...)

// Protocol-based (testable code paths)
class MyVM { init(db: DatabaseManagerProtocol = DatabaseManager.shared) { ... } }
```

Every repository has a `*Protocol` for testability. Mocks live in `EVChargingTrackerTests/Utils/Mock*Repository.swift`. The protocol is also what target-specific code should depend on.

Full list of repositories and tables: `../docs/persistence.md`.

### Services

`*.shared` singletons are the convention. They are `@MainActor` where they update `@Published` properties (e.g., `BackupService`, `BackgroundTaskManager`, `AppearanceManager`); otherwise plain `final class`.

Most-used services from app code:

| Service | What it provides |
|---|---|
| `AnalyticsService` | `trackEvent`, `trackScreen`, `trackButtonTap`, `identifyUser`. Release-only Firebase. |
| `BackupService` | Export, import, iCloud Drive backups, safety backups |
| `BackgroundTaskManager` | Daily backup `BGTaskScheduler` task |
| `EnvironmentService` | Info.plist token reader (xcconfig values, app version, OS version, language) |
| `LocalizationManager` | Runtime language switching, `L()` global |
| `NotificationManager` | Local notification scheduling/cancellation |
| `DocumentService` | File storage for `CarDocument` (App Group container) |
| `AppVersionChecker` | App Store iTunes lookup → newer-version detection |
| `AppearanceManager` | Light / dark / system mode |
| `AppFontFamilyManager` | System vs JetBrains Mono toggle |
| `NetworkMonitor` | Connectivity gate |

### Models

All `Codable` structs/classes. Currency-bearing fields use `Double?` (deliberate — see `../docs/domain.md`). Date fields use `Date` directly.

| Model | Owner table | Backing repository |
|---|---|---|
| `Car` | `cars` | `CarRepository` |
| `Expense` | `charging_sessions` | `ExpensesRepository` |
| `PlannedMaintenance` | `planned_maintenance` | `PlannedMaintenanceRepository` |
| `CarDocument` | `documents` | `DocumentsRepository` |
| `Idea` | `ideas` | `IdeasRepository` |
| `DelayedNotification` | `delayed_notifications` | `DelayedNotificationsRepository` |
| `UserSettings*` | `user_settings` | `UserSettingsRepository` |

`ExportModels.swift` mirrors these for the JSON backup format. **`ExportModels` is the source of truth for the on-disk backup schema** — changing a domain model without updating its `Export*` counterpart will break round-trip backup/restore.

### App Group container

`AppGroupContainer` (in `Helpers/`) is a static enum with three properties:

- `containerURL` — root of the App Group container (fatal if not configured)
- `databaseURL` — the SQLite file
- `documentsStorageURL` — `CarDocuments/` for car document files

Both targets must use these — never reach into `Documents/` or `URLs(for: .documentDirectory, in:)` for app-data storage.

## Transactional boundaries

Most repository methods are autocommit (single `INSERT` / `UPDATE` / `DELETE`). The few multi-statement operations (truncates, cascading deletes) are wrapped in repository methods that intentionally do not expose the connection. **Never pass `Connection` outside the repository layer.**

## Testing

- Test target: `EVChargingTrackerTests/` (Swift Testing).
- DI helper: `EVChargingTrackerTests/Utils/DatabaseManagerFake.swift` conforms to `DatabaseManagerProtocol`.
- Mocks: `EVChargingTrackerTests/Utils/Mock*Repository.swift` per repository protocol.
- Helper utilities: `EVChargingTrackerTests/Utils/TestHelpers.swift`.

To unit-test a view model that depends on a repository, take the protocol type and inject a `Mock*Repository`. Avoid touching `DatabaseManager.shared` from tests.

## Adding to this module

When adding a file under `BusinessLogic/`:

- [ ] Decide whether the ShareExtension target should compile it.
- [ ] If yes (most files): nothing extra to do — file synchronization adds it to both targets.
- [ ] If no (file uses extension-restricted APIs): add it to the file exception set in `EVChargingTracker.xcodeproj/project.pbxproj` under the ShareExtension target.
- [ ] Build the `ShareExtension` scheme on its own to verify.
- [ ] If you added a new repository: register it on `DatabaseManager`, expose it via `DatabaseManagerProtocol`, add a mock in `EVChargingTrackerTests/Utils/`.

## Key files

- `BusinessLogic/Database/DatabaseManager.swift` — singleton, schema version, repository wiring
- `BusinessLogic/Database/<Entity>Repository.swift` — per-table CRUD + protocol
- `BusinessLogic/Database/Migrations/Migration_*.swift` — append-only schema steps
- `BusinessLogic/Helpers/AppGroupContainer.swift` — canonical paths
- `BusinessLogic/Services/AnalyticsService.swift` — main-app-only (excluded from ShareExtension)
- `BusinessLogic/Services/BackgroundTaskManager.swift` — main-app-only (excluded from ShareExtension)
- `BusinessLogic/Services/EnvironmentService.swift` — Info.plist reader
- `BusinessLogic/Services/LocalizationManager.swift` — `L()` global, runtime language switching
- `BusinessLogic/Models/ExportModels.swift` — JSON backup schema
- `EVChargingTrackerTests/Utils/DatabaseManagerFake.swift` — DI for tests
