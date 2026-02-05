# Code Review: EV Charging Tracker

## Critical & High Severity

### 1. [Bugs & Crashes] Force unwraps on repositories will crash if database init fails

**File:** `BusinessLogic/Database/DatabaseManager.swift:83-101`
**Severity:** Critical
**Description:** All five `DatabaseManagerProtocol` methods force-unwrap optional repositories (`plannedMaintenanceRepository!`, `carRepository!`, etc.). If the database `Connection` init throws (line 53), the `catch` block on line 74 logs and returns — leaving all repositories as `nil`. Every subsequent access via these protocol methods will crash.

The same pattern propagates to all consumers that force-unwrap from the singleton:
- `BusinessLogic/Services/BackupService.swift:77-81` — `databaseManager.carRepository!` etc.
- `EVChargingTracker/ChargingSessions/ChargingViewModel.swift:46-47` — `db.expensesRepository!`
- `EVChargingTracker/Expenses/ExpensesViewModel.swift:48-49`

**Suggestion:** Make the protocol methods return optionals, or make `DatabaseManager.init` failable/throwing so callers know initialization failed. At minimum, guard and present an error state to the user instead of crashing.

**Solution:** Change the protocol to return optionals and update all five methods:

```swift
// DatabaseManager.swift — protocol change
protocol DatabaseManagerProtocol {
    func getPlannedMaintenanceRepository() -> PlannedMaintenanceRepositoryProtocol?
    func getDelayedNotificationsRepository() -> DelayedNotificationsRepositoryProtocol?
    func getCarRepository() -> CarRepositoryProtocol?
    func getExpensesRepository() -> ExpensesRepositoryProtocol?
    func getUserSettingsRepository() -> UserSettingsRepositoryProtocol?
}

// DatabaseManager.swift — method implementations
func getPlannedMaintenanceRepository() -> PlannedMaintenanceRepositoryProtocol? {
    return plannedMaintenanceRepository
}

func getDelayedNotificationsRepository() -> DelayedNotificationsRepositoryProtocol? {
    return delayedNotificationsRepository
}

func getCarRepository() -> CarRepositoryProtocol? {
    return carRepository
}

func getExpensesRepository() -> ExpensesRepositoryProtocol? {
    return expensesRepository
}

func getUserSettingsRepository() -> UserSettingsRepositoryProtocol? {
    return userSettingsRepository
}
```

All call sites that use these protocol methods (e.g. `PlanedMaintenanceViewModel.init`) will need to handle the optional — typically with a `guard let` at the top of the consuming method. This is a cascading change that touches multiple files, so it should be done as a dedicated PR.

---

### 2. [Bugs & Crashes] Force unwrap of `selectedCar!` in view body crashes if car is nil

**File:** `EVChargingTracker/PlanedMaintenance/AddMaintenanceRecordView.swift:115`
**Severity:** Critical
**Description:** The view body contains `TextField(selectedCar!.currentMileage.formatted(), ...)` inside a `VStack` that is **always** rendered (it's not gated by a nil check on `selectedCar`). If `selectedCar` is nil, the app crashes on render. The guard on line 170 only protects the `save()` function, not the body.
**Suggestion:** Wrap this section with `if let selectedCar = selectedCar { ... }` or use optional chaining with a fallback value.

**Solution:** Replace the force-unwrap with optional chaining and a fallback placeholder. Change line 115 from:

```swift
// Before (line 115):
TextField(selectedCar!.currentMileage.formatted(), text: $odometer)

// After:
TextField(selectedCar?.currentMileage.formatted() ?? "0", text: $odometer)
```

Also fix the same pattern on line 99 inside the `if (selectedCar != nil)` block — replace `selectedCar!.name` with `selectedCar?.name ?? ""` (or keep the `if let` form):

```swift
// Before (lines 95-102):
if (selectedCar != nil) {
    HStack {
        Text(L("Car"))
        Spacer()
        Text(selectedCar!.name)
            .disabled(true)
    }
}

// After:
if let car = selectedCar {
    HStack {
        Text(L("Car"))
        Spacer()
        Text(car.name)
            .disabled(true)
    }
}
```

And fix line 196 in `save()`:

```swift
// Before (line 196):
carId: selectedCar!.id!,

// After:
carId: selectedCar!.id ?? 0,
// Note: selectedCar is already guarded non-nil at line 170, but id could be nil.
// Better yet:
guard let selectedCar = selectedCar, let carId = selectedCar.id else {
    alertMessage = L("Please select a car first.")
    return
}
// ... then use carId
```

---

### 3. [Bugs & Crashes] Force unwrap on `car.id!` in updateCar

**File:** `BusinessLogic/Database/CarRepository.swift:170`
**Severity:** High
**Description:** `let carToUpdate = table.filter(idColumn == car.id!)` will crash if `car.id` is nil. Other methods like `updateMilleage` (line 122) properly guard against this.
**Suggestion:** Add a guard.

**Solution:** Add a guard matching the pattern already used in `updateMilleage`:

```swift
// Before (line 169-170):
func updateCar(car: Car) -> Bool {
    let carToUpdate = table.filter(idColumn == car.id!)

// After:
func updateCar(car: Car) -> Bool {
    guard let carId = car.id else {
        logger.info("Update failed: Car id is nil")
        return false
    }
    let carToUpdate = table.filter(idColumn == carId)
```

---

### 4. [Bugs & Crashes] Force unwrap in EnvironmentService.getAppStoreAppLink

**File:** `BusinessLogic/Services/EnvironmentService.swift:95`
**Severity:** High
**Description:** `let appStoreId = self.getAppStoreId()!` — `getAppStoreId()` returns `String?`. If the `AppStoreId` key is missing from Info.plist, this crashes.
**Suggestion:** Guard the optional or provide a fallback.

**Solution:** Use a guard with a fallback empty string (matching the pattern of other methods in this class):

```swift
// Before (lines 90-98):
func getAppStoreAppLink() -> String {
    if _appStoreAppLink != nil {
        return _appStoreAppLink!
    }

    let appStoreId = self.getAppStoreId()!
    _appStoreAppLink = "https://apps.apple.com/app/id\(appStoreId)"
    return _appStoreAppLink!
}

// After:
func getAppStoreAppLink() -> String {
    if let cached = _appStoreAppLink {
        return cached
    }

    let appStoreId = self.getAppStoreId() ?? ""
    _appStoreAppLink = "https://apps.apple.com/app/id\(appStoreId)"
    return _appStoreAppLink!
}
```

---

### 5. [Bugs & Crashes] Double force-unwrap in PlanedMaintenanceViewModel.loadData

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift:55`
**Severity:** High
**Description:** `maintenanceRepository.getAllRecords(carId: selectedCar!.id!)` — after checking `selectedCar == nil`, this force-unwraps both `selectedCar` and its `id`. While `selectedCar` is known non-nil here, `id` could still be nil for a car that hasn't been persisted.
**Suggestion:** Use `guard let car = selectedCar, let carId = car.id else { return }`.

**Solution:** Replace the nil check and force-unwraps with a single guard:

```swift
// Before (lines 48-57):
func loadData() -> Void {
    let selectedCar = self.reloadSelectedCarForExpenses()
    if (selectedCar == nil) {
        return
    }

    let now = Date()
    var records = maintenanceRepository.getAllRecords(carId: selectedCar!.id!).map { dbRecord in
        PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
    }

// After:
func loadData() -> Void {
    guard let selectedCar = self.reloadSelectedCarForExpenses(),
          let carId = selectedCar.id else {
        return
    }

    let now = Date()
    var records = maintenanceRepository.getAllRecords(carId: carId).map { dbRecord in
        PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
    }
```

---

### 6. [Bugs & Crashes] Force-unwrap of maintenance.id in PlannedMaintenanceItem init

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift:290`
**Severity:** High
**Description:** `self.id = maintenance.id!` will crash if a `PlannedMaintenance` without a persisted ID is passed in.
**Suggestion:** Guard or make the init failable.

**Solution:** Make the init failable, so callers simply skip records without an id:

```swift
// Before (line 289-290):
init(maintenance: PlannedMaintenance, car: Car? = nil, now: Date = Date()) {
    self.id = maintenance.id!

// After:
init?(maintenance: PlannedMaintenance, car: Car? = nil, now: Date = Date()) {
    guard let maintenanceId = maintenance.id else { return nil }
    self.id = maintenanceId
```

Then update `loadData()` to use `compactMap`:

```swift
// Before:
var records = maintenanceRepository.getAllRecords(carId: carId).map { dbRecord in
    PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
}

// After:
var records = maintenanceRepository.getAllRecords(carId: carId).compactMap { dbRecord in
    PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
}
```

---

### 7. [Data Loss] ExportCar does not include wheel size fields

**File:** `BusinessLogic/Models/ExportModels.swift:42-79`
**Severity:** High
**Description:** `ExportCar` was not updated when `frontWheelSize` and `rearWheelSize` were added to the `Car` model (migration 6). The `init(from car: Car)` doesn't capture these fields, and `toCar()` doesn't restore them. Any export/import cycle **permanently loses** wheel size data.
**Suggestion:** Add `frontWheelSize: String?` and `rearWheelSize: String?` to `ExportCar`, populate them in both `init(from:)` and `toCar()`.

**Solution:** Add two optional fields to the struct and update both conversion methods:

```swift
// ExportModels.swift — ExportCar struct
struct ExportCar: Codable {
    let id: Int64?
    let name: String
    let selectedForTracking: Bool
    let batteryCapacity: Double?
    let expenseCurrency: String
    let currentMileage: Int
    let initialMileage: Int
    let milleageSyncedAt: Date
    let createdAt: Date
    let frontWheelSize: String?   // <-- ADD
    let rearWheelSize: String?    // <-- ADD

    init(from car: Car) {
        self.id = car.id
        self.name = car.name
        self.selectedForTracking = car.selectedForTracking
        self.batteryCapacity = car.batteryCapacity
        self.expenseCurrency = car.expenseCurrency.rawValue
        self.currentMileage = car.currentMileage
        self.initialMileage = car.initialMileage
        self.milleageSyncedAt = car.milleageSyncedAt
        self.createdAt = car.createdAt
        self.frontWheelSize = car.frontWheelSize   // <-- ADD
        self.rearWheelSize = car.rearWheelSize     // <-- ADD
    }

    func toCar() -> Car {
        let car = Car(
            name: name,
            selectedForTracking: selectedForTracking,
            batteryCapacity: batteryCapacity,
            expenseCurrency: Currency(rawValue: expenseCurrency) ?? .usd,
            currentMileage: currentMileage,
            initialMileage: initialMileage,
            milleageSyncedAt: milleageSyncedAt,
            createdAt: createdAt,
            frontWheelSize: frontWheelSize,   // <-- ADD
            rearWheelSize: rearWheelSize      // <-- ADD
        )
        car.id = id
        return car
    }
}
```

The new fields are optional and `Codable`, so existing backup files without these keys will decode them as `nil` — fully backward compatible.

---

### 8. [Logic & Correctness] Off-by-one: expenses on the last day of a month excluded from charts

**File:** `EVChargingTracker/ChargingSessions/ExpensesChartViewModel.swift:238`
**Severity:** High
**Description:** `monthEnd` is calculated as `calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)` which yields the last day at **00:00:00**. The filter `expense.date <= monthEnd` then excludes any expense after midnight on the last day of the month (e.g., an expense on Jan 31 at 14:00 is excluded from January's chart data).

Same bug exists in `EVChargingTracker/ChargingSessions/ChargingConsumptionChartViewModel.swift:34`.

**Suggestion:** Use `calendar.date(byAdding: .month, value: 1, to: monthStart)` as the exclusive upper bound and filter with `expense.date < nextMonthStart`.

**Solution:** In both files, replace `monthEnd` with `nextMonthStart` and use `<` instead of `<=`:

**ExpensesChartViewModel.swift (lines 236-243):**

```swift
// Before:
guard
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
    let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
    continue
}

let monthExpenses = expensesToShow.filter { expense in
    expense.date >= monthStart && expense.date <= monthEnd
}

// After:
guard
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
    let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
    continue
}

let monthExpenses = expensesToShow.filter { expense in
    expense.date >= monthStart && expense.date < nextMonthStart
}
```

**ChargingConsumptionChartViewModel.swift (lines 32-41):**

```swift
// Before:
guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today),
      let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
      let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
    continue
}

let monthExpenses = self.expenses.filter { expense in
    return expense.expenseType == .charging &&
            expense.date >= startOfMonth && expense.date <= endOfMonth
}

// After:
guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today),
      let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
      let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
    continue
}

let monthExpenses = self.expenses.filter { expense in
    return expense.expenseType == .charging &&
            expense.date >= startOfMonth && expense.date < nextMonthStart
}
```

---

## Medium Severity

### 9. [Concurrency] ChargingViewModel and ExpensesViewModel lack @MainActor

**File:** `EVChargingTracker/ChargingSessions/ChargingViewModel.swift:11`, `EVChargingTracker/Expenses/ExpensesViewModel.swift:11`
**Severity:** Medium
**Description:** Both are `ObservableObject` with `@Published` properties but are not annotated `@MainActor`. Their `@Published` properties are mutated in `loadSessions()` which is called from `init`. SwiftUI observes these properties on the main thread. If these ViewModels are ever initialized off the main thread, this is a data race.
**Suggestion:** Add `@MainActor` to both classes, consistent with how `UserSettingsViewModel` and `ChargingConsumptionChartViewModel` are already annotated.

**Solution:** Add `@MainActor` annotation to the class declarations:

```swift
// ChargingViewModel.swift, line 11:
// Before:
class ChargingViewModel: ObservableObject {

// After:
@MainActor
class ChargingViewModel: ObservableObject {
```

```swift
// ExpensesViewModel.swift, line 11:
// Before:
class ExpensesViewModel: ObservableObject {

// After:
@MainActor
class ExpensesViewModel: ObservableObject {
```

---

### 10. [Concurrency] BackupService does synchronous file I/O on MainActor

**File:** `BusinessLogic/Services/BackupService.swift:179`, `BusinessLogic/Services/BackupService.swift:843-853`
**Severity:** Medium
**Description:** `BackupService` is `@MainActor`. Methods like `parseExportFile` (line 179: `Data(contentsOf: fileURL)`) and `getBackupInfo` (line 850: `Data(contentsOf: fileURL)`) perform synchronous file reads and JSON decoding on the main thread. For large backup files, this blocks the UI.
**Suggestion:** Move file I/O and JSON decoding to a background task/actor, then hop back to main actor for state updates.

**Solution:** Extract the heavy work into a non-isolated helper and call it with `await`. Example for `parseExportFile`:

```swift
// Before (inside @MainActor class):
func parseExportFile(at fileURL: URL) throws -> ExportData {
    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(ExportData.self, from: data)
}

// After:
func parseExportFile(at fileURL: URL) async throws -> ExportData {
    return try await Task.detached {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }.value
}
```

Apply the same pattern to `getBackupInfo`. Call sites that currently call these synchronously will need to add `await`.

---

### 11. [Logic & Correctness] PlannedMaintenanceItem Equatable ignores identity

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift:311-313`
**Severity:** Medium
**Description:** The `==` operator only compares `when` and `mileageDifference`, ignoring `id`, `name`, `notes`, `odometer`, `carId`, and `createdAt`. Two completely different maintenance items can be considered equal, which breaks SwiftUI diffing (since it also conforms to `Identifiable` with a different `id` field).
**Suggestion:** At minimum include `id` in the equality check, or remove the custom `Equatable` and let the struct synthesize it.

**Solution:** Since the struct only has stored properties of types that already conform to `Equatable`, remove the custom implementations and let Swift synthesize them. Delete lines 311-341 entirely:

```swift
// DELETE these two custom operator overloads:

static func == (first: PlannedMaintenanceItem, second: PlannedMaintenanceItem) -> Bool {
    return first.when == second.when && first.mileageDifference == second.mileageDifference
}

static func < (first: PlannedMaintenanceItem, second: PlannedMaintenanceItem) -> Bool {
    // ... entire implementation
}
```

Keep only the `<` operator for `Comparable` (sorting), and let Swift auto-synthesize `==` based on all stored properties:

```swift
struct PlannedMaintenanceItem: Identifiable, Comparable, Equatable {
    // ... all stored properties ...

    // Keep the custom < for sorting logic (it's correct for ordering)
    static func < (first: PlannedMaintenanceItem, second: PlannedMaintenanceItem) -> Bool {
        if (first.mileageDifference != nil && second.mileageDifference != nil) {
            return first.mileageDifference! > second.mileageDifference!
        }
        if (first.when != nil && second.when != nil) {
            return first.when! < second.when!
        }
        if (first.mileageDifference != nil) { return true }
        if (second.mileageDifference != nil) { return false }
        if (first.when != nil) { return true }
        if (second.when != nil) { return false }
        return first.createdAt < second.createdAt
    }
}
```

Note: Remove the explicit `== ` function. Swift will auto-generate `Equatable` by comparing all stored properties including `id`.

---

### 12. [Error Handling] Update methods silently update row 0 when id is nil

**File:** `BusinessLogic/Database/ExpensesRepository.swift:374`, `BusinessLogic/Database/PlannedMaintenanceRepository.swift:126`, `BusinessLogic/Database/DelayedNotificationsRepository.swift:124`
**Severity:** Medium
**Description:** `let sessionId = session.id ?? 0` — if the entity hasn't been persisted, `id` is nil and the code attempts to update the row with id=0. This silently does nothing (no rows matched) but returns `true`, misleading callers into thinking the update succeeded.
**Suggestion:** Guard that `id` is non-nil at the start and return `false` or throw if it is.

**Solution:** Replace the `?? 0` fallback with a guard in all three files:

**ExpensesRepository.swift (line 373-374):**

```swift
// Before:
func updateSession(_ session: Expense) -> Bool {
    let sessionId = session.id ?? 0

// After:
func updateSession(_ session: Expense) -> Bool {
    guard let sessionId = session.id else {
        logger.error("Update failed: session id is nil")
        return false
    }
```

**PlannedMaintenanceRepository.swift (line 125-126):**

```swift
// Before:
func updateRecord(_ record: PlannedMaintenance) -> Bool {
    let recordId = record.id ?? 0

// After:
func updateRecord(_ record: PlannedMaintenance) -> Bool {
    guard let recordId = record.id else {
        logger.error("Update failed: record id is nil")
        return false
    }
```

**DelayedNotificationsRepository.swift (line 123-124):**

```swift
// Before:
func updateRecord(_ record: DelayedNotification) -> Bool {
    let recordId = record.id ?? 0

// After:
func updateRecord(_ record: DelayedNotification) -> Bool {
    guard let recordId = record.id else {
        logger.error("Update failed: record id is nil")
        return false
    }
```

---

### 13. [Logic & Correctness] Duplicate method: updateSession(_ car:) and updateCarExpensesCurrency

**File:** `BusinessLogic/Database/ExpensesRepository.swift:449-469`
**Severity:** Medium
**Description:** `updateSession(_ car: Car)` and `updateCarExpensesCurrency(_ car: Car)` are **identical** methods — same implementation, same SQL. The protocol only declares `updateCarExpensesCurrency`, making `updateSession(_ car:)` dead code that creates confusion.
**Suggestion:** Remove `updateSession(_ car: Car)`.

**Solution:** Delete the `updateSession(_ car: Car)` method entirely (lines 449-458). The protocol-conforming `updateCarExpensesCurrency` remains as the single implementation:

```swift
// DELETE this method (lines 449-458):
func updateSession(_ car: Car) -> Bool {
    let recordToUpdateQuery = chargingSessionsTable.filter(carIdColumn == car.id)
    do {
        try db.run(recordToUpdateQuery.update(currency <- car.expenseCurrency.rawValue))
        return true
    } catch {
        logger.error("Update failed: \(error)")
        return false
    }
}
```

Then search for any callers of `updateSession(_ car:)` and redirect them to `updateCarExpensesCurrency(_:)`. A grep shows no callers — it's pure dead code.

---

### 14. [Logic & Correctness] deleteCar deletes expenses twice

**File:** `EVChargingTracker/UserSettings/UserSettingsViewModel.swift:228-231`
**Severity:** Medium
**Description:** `deleteCar` calls `db.expensesRepository?.deleteRecordsForCar(carId)` and then `db.carRepository?.delete(id: carId)`. But `CarRepository.delete(id:)` at `BusinessLogic/Database/CarRepository.swift:229-250` also deletes the car's expenses internally. The expenses deletion runs twice.
**Suggestion:** Pick one ownership point for cascade-deleting related records. Either let `CarRepository.delete` handle it, or remove the cascade from `CarRepository.delete` and keep it in the ViewModel.

**Solution:** Remove the redundant call from `UserSettingsViewModel.deleteCar`. The `CarRepository.delete(id:)` already handles cascade deletion of expenses, so let it be the single owner of that logic:

```swift
// Before (UserSettingsViewModel.swift lines 228-231):
func deleteCar(_ carId: Int64, selectedForTracking: Bool) -> Void {
    db.expensesRepository?.deleteRecordsForCar(carId)        // <-- REMOVE this line
    db.plannedMaintenanceRepository?.deleteRecordsForCar(carId)
    _ = db.carRepository?.delete(id: carId)

// After:
func deleteCar(_ carId: Int64, selectedForTracking: Bool) -> Void {
    db.plannedMaintenanceRepository?.deleteRecordsForCar(carId)
    _ = db.carRepository?.delete(id: carId)  // This already deletes expenses internally
```

Note: `CarRepository.delete` does NOT cascade-delete planned maintenance records, so that call must stay.

---

### 15. [Performance] MigrationsRepository loads all rows to find latest version

**File:** `BusinessLogic/Database/MigrationsRepository.swift:40-62`
**Severity:** Medium
**Description:** `getLatestMigrationVersion()` loads **all** migration records into an array, then returns the first element's id. With SQLite, this should be a single query.
**Suggestion:** Use `pluck` with a `limit(1)` query.

**Solution:** Replace the full-table scan with a single-row query:

```swift
// Before (lines 40-62):
func getLatestMigrationVersion() -> Int64 {
    var migrationsList: [SqlMigration] = []

    do {
        for record in try db.prepare(table.order(id.desc)) {
            let migration = SqlMigration(
                id: record[id],
                date: record[date],
            )
            migrationsList.append(migration)
        }
    } catch {
        logger.error("Fetch failed: \(error)")
    }

    if (migrationsList.count > 0) {
        return migrationsList[0].id ?? 0
    }

    return 0
}

// After:
func getLatestMigrationVersion() -> Int64 {
    do {
        if let row = try db.pluck(table.select(id).order(id.desc)) {
            return row[id]
        }
    } catch {
        logger.error("Fetch failed: \(error)")
    }
    return 0
}
```

---

### 16. [Error Handling] DatabaseManager.init silently swallows database setup failure

**File:** `BusinessLogic/Database/DatabaseManager.swift:45-76`
**Severity:** Medium
**Description:** If `Connection(dbPath)` throws, the error is logged but execution continues with all repositories as `nil`. There is no way for callers to know the database is unavailable. Every force-unwrap downstream becomes a ticking crash.
**Suggestion:** Consider a static factory method that returns `Result<DatabaseManager, Error>`, or store an `isInitialized` flag that consumers check before accessing repositories.

**Solution:** Add an `isInitialized` flag and expose it. This is the minimal change — a full factory refactor would be better but much larger:

```swift
// DatabaseManager.swift — add property
class DatabaseManager: DatabaseManagerProtocol {
    // ... existing properties ...

    private(set) var isInitialized: Bool = false  // <-- ADD

    private init() {
        self.logger = Logger(subsystem: "com.evchargingtracker.database", category: "DatabaseManager")

        do {
            // ... existing setup code ...
            migrateIfNeeded()
            self.isInitialized = true  // <-- ADD at end of do block
        } catch {
            logger.error("Unable to setup database: \(error)")
        }
    }
}
```

Key consumers (ViewModels, BackupService) can then check `DatabaseManager.shared.isInitialized` before proceeding. This works well in combination with finding #1 (making protocol return optionals).

---

## Low Severity

### 17. [Security] User ID logged in production

**File:** `BusinessLogic/Services/AnalyticsService.swift:36`
**Severity:** Low
**Description:** `logger.info("Initialized user_id: \(self._userId ?? "nil")")` logs the generated UUID to system logs in all builds (not just development). While it's a UUID and not PII, the development-only check is missing here while being consistently used for other analytics logging.
**Suggestion:** Gate behind `environment.isDevelopmentMode()`.

**Solution:** Wrap the log statement in a dev-mode check:

```swift
// Before (lines 33-37):
private func initializeUserId() {
    if let userSettingsRepo = db.userSettingsRepository {
        self._userId = userSettingsRepo.fetchOrGenerateUserId()
        logger.info("Initialized user_id: \(self._userId ?? "nil")")
    }
}

// After:
private func initializeUserId() {
    if let userSettingsRepo = db.userSettingsRepository {
        self._userId = userSettingsRepo.fetchOrGenerateUserId()
        if environment.isDevelopmentMode() {
            logger.info("Initialized user_id: \(self._userId ?? "nil")")
        }
    }
}
```

---

### 18. [Logic & Correctness] `deleteAlliCloudBackups` declares unused variable

**File:** `BusinessLogic/Services/BackupService.swift:772`
**Severity:** Low
**Description:** `guard let backupDirectory = iCloudBackupDirectory` — `backupDirectory` is bound but never used in the method body.
**Suggestion:** Replace with `guard iCloudBackupDirectory != nil`.

**Solution:** Replace the unused binding with a wildcard:

```swift
// Before (line 772):
guard let backupDirectory = iCloudBackupDirectory else {

// After:
guard iCloudBackupDirectory != nil else {
```

---

### 19. [Concurrency] Redundant DispatchQueue.main.async in @MainActor class

**File:** `EVChargingTracker/UserSettings/UserSettingsViewModel.swift:128-129` (also lines 141, 157, 202, 220, 244)
**Severity:** Low
**Description:** `UserSettingsViewModel` is `@MainActor`, so all methods already run on the main thread. Wrapping property updates in `DispatchQueue.main.async` is unnecessary and introduces a one-runloop-cycle delay.
**Suggestion:** Remove the `DispatchQueue.main.async` wrappers.

**Solution:** Unwrap all `DispatchQueue.main.async` calls and assign directly. Example for `saveDefaultCurrency`:

```swift
// Before (lines 126-131):
func saveDefaultCurrency(_ currency: Currency) -> Void {
    DispatchQueue.main.async {
        self.defaultCurrency = currency
    }
    // ...
}

// After:
func saveDefaultCurrency(_ currency: Currency) -> Void {
    self.defaultCurrency = currency
    // ...
}
```

Apply the same unwrapping to all occurrences in this file:
- `saveDefaultCurrency` (line 128)
- `saveLanguage` (line 141)
- `saveAppearanceMode` (line 157)
- `insertCar` (line 202)
- `updateCar` (line 220)
- `refetchCars` (line 244)

---

### 20. [Simplification] MonthlyConsumption has duplicate computed properties

**File:** `EVChargingTracker/ChargingSessions/ChargingConsumptionChartViewModel.swift:98-108`
**Severity:** Low
**Description:** `monthName` and `shortMonthName` have identical implementations — both use `"MMM"` format. One of them appears to be dead or misconfigured code.
**Suggestion:** Remove one, or differentiate them (e.g., `"MMMM"` for the full month name).

**Solution:** Check usage — if `shortMonthName` is used in the chart axis and `monthName` elsewhere, keep both but differentiate. If only one is used, delete the other. Based on the code, `monthName` is the one used in the chart view. Remove `shortMonthName`:

```swift
// DELETE lines 104-108:
var shortMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: month)
}
```

If `shortMonthName` is referenced elsewhere, replace those references with `monthName`.

---

### 21. [Error Handling] NotificationManager.init ignores injected logger

**File:** `BusinessLogic/Services/NotificationManager.swift:22-24`
**Severity:** Low
**Description:** The `init` accepts `logger: Logger? = nil` but ignores it, always creating a new Logger instance. The parameter has no effect.
**Suggestion:** Use the provided logger: `self.logger = logger ?? Logger(...)`.

**Solution:** Use the injected logger when provided:

```swift
// Before (lines 22-24):
init(logger: Logger? = nil) {
    self.logger = Logger(subsystem: "NotificationManager", category: "Notifications")
}

// After:
init(logger: Logger? = nil) {
    self.logger = logger ?? Logger(subsystem: "NotificationManager", category: "Notifications")
}
```

---

### 22. [Logic & Correctness] Expense uses Double for cost instead of Decimal

**File:** `BusinessLogic/Models/ExpenseModels.swift:94`
**Severity:** Low
**Description:** The `cost` property is `Double?`. The project's own coding standards explicitly require `Decimal` for monetary values to avoid floating-point precision errors. All downstream calculations (total costs, per-km costs, chart aggregations) operate on `Double`.
**Suggestion:** This is a larger refactor — flagging it as a known deviation from the project's stated guidelines. Precision errors can accumulate over many expense records.

**Solution:** This requires a coordinated migration across the entire codebase (model, repository layer including SQLite column type, all ViewModels that aggregate costs, export models). Not recommended as a quick fix — it should be planned as a dedicated refactoring ticket. The practical impact is low for individual user expense tracking (floating-point errors at typical EV charging amounts are sub-cent), but it diverges from the project's own stated standards.
