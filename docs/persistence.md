# Persistence

For: developers touching the database, repositories, or migrations. For domain meaning of each entity, see `domain.md`. For backup/restore, see `backup-and-restore.md`. For Share Extension boundary issues, see `integrations/share-extension.md`.

## Stack

- **SQLite.swift** — type-safe Swift wrapper around SQLite3.
- A single `Connection` is held by `DatabaseManager` (singleton). All repositories share it.
- Database file: `tesla_charging.sqlite3` in the **App Group container** (so the Share Extension and the main app see the same data).

## Where the database lives

| Path | Used for |
|---|---|
| `AppGroupContainer.databaseURL` (= `containerURL/tesla_charging.sqlite3`) | The live DB |
| `AppGroupContainer.documentsStorageURL` (= `containerURL/CarDocuments/`) | Per-car document files |
| `Documents/tesla_charging.sqlite3` | Legacy path (pre-Share-Extension); migrated atomically once |

App Group identifier resolution (token chain):

```
EVChargingTracker/Config/Base.xcconfig:
  APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.evchargetracker

EVChargingTracker/Info.plist (build-time substituted):
  AppGroupIdentifier → $(APP_GROUP_IDENTIFIER)

BusinessLogic/Services/EnvironmentService.swift:
  getAppGroupIdentifier() reads "AppGroupIdentifier" from Info.plist

BusinessLogic/Helpers/AppGroupContainer.swift:
  identifier → EnvironmentService.shared.getAppGroupIdentifier()
  containerURL → FileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier)
```

If any link in this chain fails, `AppGroupContainer` calls `fatalError("App Group ... not configured")` (see `AppGroupContainer.swift:18-30`). Diagnostic: `diagnostics.md` → `[DIAG-002]`.

## One-time legacy migration

Pre-Share-Extension installs put the DB in the app's `Documents`. `DatabaseMigrationHelper.migrateToAppGroupIfNeeded()` (called from `DatabaseManager.init()`) atomically copies it to the App Group container.

Strategy (stricter than a plain copy):

1. Copy legacy DB (+ `.wal`, `.shm`) to a temp file inside the App Group container.
2. Open the temp file read-only and assert that the `migrations` table exists.
3. `moveItem` temp → final destination (atomic).
4. Delete legacy files only after step 3 succeeds.

Marker: `AppGroupMigrationCompleted` boolean in `UserDefaults(suiteName: <APP_GROUP_IDENTIFIER>)` (shared so the extension can also see "done"). Reset in dev mode via `DatabaseMigrationHelper.resetMigrationFlag()`.

## Connection lifecycle

`DatabaseManager.init()` (`BusinessLogic/Database/DatabaseManager.swift:48-87`):

1. Run `DatabaseMigrationHelper.migrateToAppGroupIfNeeded()` (legacy → App Group).
2. Open `Connection(AppGroupContainer.databaseURL.path)`.
3. Construct every repository against that connection.
4. `userSettingsRepository?.createTable()` (defensive — runs every launch).
5. `migrateIfNeeded()` (schema version walk).
6. `isInitialized = true`.

`DatabaseManager.shared` is warmed up early in `EVChargingTrackerApp.init()` so migration runs before any DB-backed UI mounts.

## Repository pattern

Every repository:

- Lives in `BusinessLogic/Database/`.
- Has a `*RepositoryProtocol` for testability.
- Receives `db: Connection` and a `tableName: String` in its initializer.
- Owns its `Table(tableName)` and column expressions.
- Returns domain models (`Car`, `Expense`, …), not raw rows.

Inventory:

| Repository | Table | Notes |
|---|---|---|
| `ExpensesRepository` | `charging_sessions` | Legacy table name from v1; the table is the home of all expense types, not just charging. Don't rename. Pagination via `.limit(pageSize, offset:)`; filter via the `buildFilteredQuery` helper that returns `Table`. |
| `CarRepository` | `cars` | Cross-references `charging_sessions` and `user_settings` to enforce active-car rules. |
| `PlannedMaintenanceRepository` | `planned_maintenance` | Filters by overdue/due-soon/scheduled at the SQL level. |
| `DocumentsRepository` | `documents` | Owns metadata only — files are on disk via `DocumentService`. |
| `IdeasRepository` | `ideas` | Per-car scoped. |
| `DelayedNotificationsRepository` | `delayed_notifications` | Notification queue. |
| `UserSettingsRepository` | `user_settings` | KV store: language, currency, user_id, font_family, sort. |
| `MigrationsRepository` | `migrations` | Schema version tracking; only used by the runner. |

### Access pattern

```swift
// ViewModels — direct via DatabaseManager.shared
@MainActor
class ChargingViewModel: ObservableObject {
    init(db: DatabaseManager = .shared) {
        self.expensesRepository = db.expensesRepository
    }
}

// PlanedMaintenanceViewModel — uses the protocol for testability
init(db: DatabaseManagerProtocol = DatabaseManager.shared) { ... }

// Views — capture the repository in init, never call from the body
struct MyView: View {
    private let repository: SomeRepository?
    init() { self.repository = DatabaseManager.shared.someRepository }
}
```

Tests use `DatabaseManagerFake` (`EVChargingTrackerTests/Utils/DatabaseManagerFake.swift`) and per-repository `Mock*Repository` for DI.

### `DispatchQueue.main.async` pattern

Several view models call into synchronous repository methods and then update `@Published` properties. Where this happens, the update is wrapped in `DispatchQueue.main.async { … }`. This is intentional — keeps `@Published` writes on the main runloop without the ceremony of `Task { @MainActor }` for what is really a sync read.

## Migrations

`DatabaseManager.migrateIfNeeded()` is the runner. The latest schema version is hardcoded in `DatabaseManager.swift:45` (`latestVersion = 8`). The runner replays every missing version in order.

| v | Migration | Purpose |
|---|---|---|
| 1 | inline (in runner) | Create `charging_sessions` |
| 2 | inline (in runner) | Create `user_settings`; default currency = `kzt` |
| 3 | `Migration_20251021_CreateCarsTable.swift` | `cars` table; add `car_id` to `charging_sessions` |
| 4 | `Migration_20251104_CreatePlannedMaintenanceTable.swift` | `planned_maintenance` |
| 5 | `Migration_20251114_CreateDelayedNotificationTable.swift` | `delayed_notifications` |
| 6 | `Migration_20250131_AddWheelDetailsToCarsTable.swift` | `front_wheel_size`, `rear_wheel_size` on `cars` |
| 7 | `Migration_20260301_CreateDocumentsTable.swift` (`Migration_20260301_CreateDocumentsAndIdeasTables`) | `documents` + `ideas` |
| 8 | `Migration_20260501_AddMeasurementSystemToCarsTable.swift` | `measurement_system` on `cars` (default `metric`) |

### Migration rules (read before adding one)

- **Append-only.** Never edit an existing migration. Existing installs have already run it; mutating it changes nothing for them and breaks fresh installs.
- **Idempotent on fresh installs.** If the column or table is already created by a repository's `getCreateTableCommand()` (which fresh installs run as part of its first call), guard with a `columnExists` check. See `Migration_20260501_AddMeasurementSystemToCarsTable.swift:32-41` for the canonical pattern:

  ```swift
  if try columnExists(named: "measurement_system", in: DatabaseManager.CarsTableName) {
      logger.debug("Column already exists; skipping ADD COLUMN")
  } else {
      try db.run(carsTable.addColumn(Expression<String>("measurement_system"),
                                     defaultValue: MeasurementSystem.metric.rawValue))
  }
  ```

- **Default values for `NOT NULL` columns.** Existing rows must be backfilled. Either supply a `defaultValue:` or update rows in the migration before adding the constraint.
- **Bump `latestVersion` and add a `case`.** Both edits land in `BusinessLogic/Database/DatabaseManager.swift`.
- **Update docs.** Add a row to the table above and to `SUMMARY.md`.

### Adding a migration — checklist

- [ ] Create `BusinessLogic/Database/Migrations/Migration_YYYYMMDD_<Description>.swift` with an `execute()` method.
- [ ] In `DatabaseManager.swift`: bump `latestVersion`, add a `case <new>:` branch in `migrateIfNeeded()`.
- [ ] If you also touched the relevant `*Repository.getCreateTableCommand()` so fresh installs build the same shape, guard the migration with `columnExists`/`tableExists`.
- [ ] If a new repository is needed: register it on `DatabaseManager` and expose it via `DatabaseManagerProtocol`.
- [ ] Update `SUMMARY.md` schema table and this file's table.
- [ ] Add a Swift Testing test that constructs the new table on a fresh in-memory DB and asserts shape (see existing tests in `EVChargingTrackerTests/`).

## Backups consume the schema version

`BackupService.exportData()` stamps the export with `currentSchemaVersion = DatabaseManager.shared.getDatabaseSchemaVersion()`. Imports compare schema versions and warn on a newer-than-current backup. Full flow: `backup-and-restore.md`.

## Constants

`DatabaseManager` exposes the canonical table-name strings as `static let` (`ExpensesTableName`, `CarsTableName`, …). Repositories take a `tableName` arg from these — never hardcode the strings elsewhere.

## Key files

- `BusinessLogic/Database/DatabaseManager.swift` — runner, schema version, repository wiring
- `BusinessLogic/Database/DatabaseMigrationHelper.swift` — legacy → App Group atomic move
- `BusinessLogic/Helpers/AppGroupContainer.swift` — canonical paths
- `BusinessLogic/Database/Migrations/Migration_*.swift` — append-only schema steps
- `BusinessLogic/Database/<Entity>Repository.swift` — per-table CRUD + protocol
- `EVChargingTrackerTests/Utils/DatabaseManagerFake.swift` — DI for tests
- `EVChargingTrackerTests/Utils/Mock*Repository.swift` — repository test doubles
