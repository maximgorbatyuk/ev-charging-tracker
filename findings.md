# Code Review Findings — EV Charging Tracker

## Critical

### [Bugs & Crashes] Force unwraps in DatabaseManager can crash if DB initialization fails

**File:** `BusinessLogic/Database/DatabaseManager.swift:109-154`

**Description:** `DatabaseManager.init()` can fail silently (catches error on line 76-78 and returns), leaving all repository properties as `nil`. Subsequently, `migrateIfNeeded()`, `deleteAllData()`, and `deleteAllExpenses()` force-unwrap these optionals, causing a crash.

```swift
// Line 109-110: If db init failed, these crash
migrationRepository!.createTableIfNotExists()
let currentVersion = migrationRepository!.getLatestMigrationVersion()

// Line 151-154:
expensesRepository!.truncateTable()
plannedMaintenanceRepository!.truncateTable()
```

**Affected locations (same pattern):**
- `ChargingViewModel.swift:47-48` — `db.expensesRepository!`, `db.plannedMaintenanceRepository!`
- `ExpensesViewModel.swift:49-50` — same
- `UserSettingsViewModel.swift:78` — `db.expensesRepository!`
- `BackupService.swift:77-81` — five force unwraps of repositories

**Suggestion:** Guard with `guard let` at the top of these methods and return early or log an error. Alternatively, make the repositories non-optional and make `DatabaseManager.init` failable, preventing the app from running with a broken DB.

---

## High

### [Bugs & Crashes] Double force unwrap on optional id

**File:** `EVChargingTracker/MainTabViewModel.swift:29`

**Description:** `selectedCarForExpenses!.id!` is a double force unwrap. The nil check on line 24 only guards `selectedCarForExpenses`, but `Car.id` is `Int64?` and can be nil for newly created cars.

```swift
let result = db.plannedMaintenanceRepository?.getPendingMaintenanceRecords(
    carId: selectedCarForExpenses!.id!,  // crash if id is nil
```

**Suggestion:** Use `guard let carId = selectedCarForExpenses.id else { return 0 }`.

---

### [Bugs & Crashes] Force unwrap in sheet presentation crashes if car is nil

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceView.swift:51`

**Description:** Inside `.sheet(isPresented:)`, `viewModel.selectedCarForExpenses!` is force unwrapped. The sheet can be presented (via the floating button) even when the car _becomes_ nil between the time the button was enabled and the sheet opens (e.g., car deleted on another screen).

```swift
.sheet(isPresented: $showingAddMaintenanceRecord) {
    let selectedCar = viewModel.selectedCarForExpenses!  // can crash
```

**Suggestion:** Use `if let` or `.sheet(item:)` pattern binding to the car, so the sheet only opens when a car exists.

---

### [Bugs & Crashes] Force unwraps after nil checks in ChargingViewModel and ExpensesViewModel

**File:** `EVChargingTracker/ChargingSessions/ChargingViewModel.swift:105,124-125,130,132,140-142`

**Description:** `saveChargingSession` has numerous force unwraps of optionals (`selectedCar!.id`, `chargingSessionResult.carName!`, `chargingSessionResult.initialExpenseForNewCar!.currency`, `carId!`, `selectedCarForExpense!.id`). While some are preceded by nil checks, the logic flow is convoluted and a missed path can crash.

The same pattern repeats in `ExpensesViewModel.saveNewExpense()` at lines 214, 233-235, 242, 250-252, 270.

**Suggestion:** Refactor using `guard let` bindings to eliminate force unwraps. For example:
```swift
guard let carName = chargingSessionResult.carName else {
    logger.error("First expense must have a car name")
    return
}
```

---

### [Bugs & Crashes] Force unwrap in deleteMaintenanceRelatedNotificationIfExists

**File:** `BusinessLogic/Database/DelayedNotificationsRepository.swift:172`

**Description:** Double force unwrap: `recordToDelete!.id!`. If `getRecordByMaintenanceId` returns a `DelayedNotification` with a nil `id` (which is possible since `id` is `Int64?`), this will crash.

```swift
_ = deleteRecord(id: recordToDelete!.id!)
```

**Suggestion:**
```swift
guard let record = getRecordByMaintenanceId(maintenanceRecordId),
      let recordId = record.id else { return }
_ = deleteRecord(id: recordId)
```

---

### [Concurrency Issues] PlanedMaintenanceViewModel lacks @MainActor but mutates @Published properties

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift:11`

**Description:** `PlanedMaintenanceViewModel` is an `ObservableObject` with `@Published` properties but is not annotated with `@MainActor`. The `loadData()` method dispatches updates to `DispatchQueue.main.async` (line 104), but other methods like `addNewMaintenanceRecord`, `deleteMaintenanceRecord`, `updateMaintenanceRecord`, `setFilter`, `goToNextPage`, `goToPreviousPage` directly modify `@Published` properties (`selectedFilter`, `currentPage`) without any main-actor guarantee. These are called from SwiftUI views (which are on `@MainActor`), so it currently works, but it's fragile and the Swift concurrency checker will flag it.

**Suggestion:** Add `@MainActor` to the class declaration, consistent with `ChargingViewModel` and `ExpensesViewModel` which already have it.

---

### DO NOT IMPLEMENT! [Logic & Correctness] Migration version recorded even if migration fails

**File:** `BusinessLogic/Database/DatabaseManager.swift:116-147`

**Description:** In the `migrateIfNeeded()` loop, after each migration `case`, `migrationRepository!.addMigrationVersion()` is called unconditionally on line 146. If a migration's `execute()` method fails internally (which it handles by logging and swallowing the error), the version is still incremented. On the next app launch, the failed migration will be skipped, leaving the database schema inconsistent.

**Suggestion:** Have `execute()` return a `Bool` indicating success, and only call `addMigrationVersion()` if the migration succeeded. Or throw from `execute()` and catch at the call site.

**Developer comment**: If we do this, then crashed app will never be opened again since the app will try to migrate again and again. The suggestion is correct in case of backend apps but not for mobile apps. In case of error, I suggest to upgrade database version and then send a report to developer.

---

### [Resource & Memory Issues] Retain cycle in ExpensesChartViewModel filter button closures

**File:** `EVChargingTracker/ChargingSessions/ExpensesChartViewModel.swift:43-124`

**Description:** The `init` creates `FilterButtonItem` closures that capture `self` strongly. These closures are stored in `self.filterButtons` (a `@Published` property), creating a retain cycle: `self` -> `filterButtons` -> closures -> `self`. The `ExpensesChartViewModel` instance will never be deallocated.

```swift
FilterButtonItem(
    title: L("Filter.All"),
    innerAction: {
        self.recreateExpensesToShow(nil)  // strong capture of self
        self.analytics.trackEvent(...)
    },
    isSelected: true),
```

**Suggestion:** Capture `self` weakly in each closure:
```swift
innerAction: { [weak self] in
    self?.recreateExpensesToShow(nil)
    self?.analytics.trackEvent(...)
}
```

---

## Medium

### [Bugs & Crashes] Force unwraps on record.id in PlanedMaintenanceViewModel

**File:** `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift:142,150,152,164,168`

**Description:** `delayedNotification.id!` on line 142, `record.id!` on lines 150, 152, 164, and 168. These are `Int64?` optionals that are force-unwrapped without guards. While database-sourced records typically have IDs, import/migration edge cases could produce nil IDs.

**Suggestion:** Guard all `.id!` accesses with `guard let`.

---

### [Concurrency Issues] ExpensesChartViewModel not MainActor-isolated

**File:** `EVChargingTracker/ChargingSessions/ExpensesChartViewModel.swift:11`

**Description:** `ExpensesChartViewModel` has `@Published` properties (`filterButtons`, `monthlyExpenseData`, `hasChartItemsToShow`) and is mutated from closures stored in `filterButtons`. These closures are invoked from SwiftUI button actions (main thread), but there's no compile-time guarantee.

**Suggestion:** Add `@MainActor` annotation.

---

### [Error Handling] Notification scheduled but completion not awaited

**File:** `BusinessLogic/Services/NotificationManager.swift:128-148`

**Description:** `sendNotification()` returns the notification identifier _synchronously_ before `UNUserNotificationCenter.add()` completes. If the notification fails to schedule (error in completion handler), the caller has already stored the identifier in the database (`DelayedNotification` table). The user will have a database record pointing to a notification that doesn't exist, and cancellation will silently fail.

**Suggestion:** Make the method async or accept a completion handler so callers can handle scheduling failures.

---

### [Error Handling] ConfirmationData uses hardcoded English strings

**File:** `BusinessLogic/Alerts/ConfirmationData.swift:25-26`

**Description:** Default parameter values `"Confirm"` and `"Cancel"` bypass the `L()` localization system, so these buttons will always display in English regardless of the user's language setting.

```swift
@Published var confirmButtonTitle: String = "Confirm"
@Published var cancelButtonTitle: String = "Cancel"
```

**Suggestion:** Use `L("Confirm")` and `L("Cancel")`.

---

### [Performance] ChargingViewModel fetches all expenses into memory

**File:** `EVChargingTracker/ChargingSessions/ChargingViewModel.swift:59`

**Description:** `loadSessions()` calls `expensesRepository.fetchAllSessions(carId)` which loads every expense for the car into memory. For users with hundreds or thousands of records, this is wasteful. The data is then iterated multiple times for calculations (`getTotalCost`, `getCo2Saved`, `getAvgConsumptionKWhPer100`, etc.) and passed to chart view models. `ExpensesViewModel` properly uses pagination.

**Suggestion:** Use aggregate SQL queries (`SUM`, `COUNT`) for statistics instead of fetching all rows. Only fetch the subset needed for charts (e.g., last 6 months).

---

### [Performance] Synchronous database I/O on the main thread

**File:** Multiple ViewModels

**Description:** All repository methods perform synchronous SQLite I/O. ViewModels annotated with `@MainActor` (`ChargingViewModel`, `ExpensesViewModel`, `UserSettingsViewModel`) call these directly from their methods, blocking the main thread during database reads/writes. For typical usage (small datasets) this is fine, but it becomes a problem as data grows.

**Affected locations:**
- `ChargingViewModel.loadSessions()` — fetches all sessions synchronously
- `ExpensesViewModel.loadSessionsForCurrentPage()` — multiple synchronous DB calls

**Suggestion:** For hot paths, consider wrapping DB calls in `Task.detached` or using a background `DispatchQueue` with `@MainActor`-dispatched results (as `PlanedMaintenanceViewModel` partially does).

**Developer comment:** 

The method `UserSettingsViewModel.addRandomExpenses()` (250 synchronous inserts in a loop) is required for development purposes, so it is ok to have it 'as is'. Do not change it.

---

### [Simplification] Duplicated expense-saving logic across ViewModels

**File:** `ChargingViewModel.swift:96-153`, `ExpensesViewModel.swift:204-280`, `PlanedMaintenanceViewModel.swift:181-216`

**Description:** Three separate ViewModels contain nearly identical logic for saving a new expense: creating a car if none exists, setting car IDs, updating mileage, inserting initial records. The code has TODO comments acknowledging this (`// TODO mgorbatyuk: avoid code duplication with saveChargingSession`). This creates a maintenance burden where a bug fix in one location is easily missed in others.

**Suggestion:** Extract expense-saving logic into a shared service class (e.g., `ExpenseSavingService`) that all three ViewModels use.

---

## Low

### [Logic & Correctness] setSortingOption branches are identical

**File:** `EVChargingTracker/Expenses/ExpensesViewModel.swift:88-93`

**Description:** Both the `if` and `else` branches do the exact same thing, making the conditional dead code:

```swift
if option != .creationDate {
    db.userSettingsRepository?.upsertExpensesSortingOption(option)
} else {
    // Remove the setting when returning to default
    db.userSettingsRepository?.upsertExpensesSortingOption(option)  // identical
}
```

**Suggestion:** Remove the `if-else` and just call `upsertExpensesSortingOption(option)`.

---

### [Security] User ID logged in production

**File:** `BusinessLogic/Database/UserSettingsRepository.swift:123`

**Description:** `fetchOrGenerateUserId()` logs the UUID with `logger.info("Generated new user_id: \(newUserId)")`. This runs in all build configurations, not just debug. While a UUID is not highly sensitive, logging user identifiers to the system log is unnecessary in production.

**Suggestion:** Gate behind a debug check.

---

### [Simplification] EnvironmentService manual caching pattern

**File:** `BusinessLogic/Services/EnvironmentService.swift:24-121`

**Description:** Every method follows the exact same pattern: check if cached value is nil, load from Bundle, cache, return. This is 8 repetitions of identical boilerplate that could be a single `lazy var`.

**Suggestion:** Use `lazy var` properties instead of manual caching:
```swift
lazy var appVisibleVersion: String = {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(version) (\(build))"
}()
```

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 1     |
| High     | 7     |
| Medium   | 6     |
| Low      | 3     |
| **Total**| **17**|

**Top priorities:**
1. Eliminate force unwraps of optional repository references throughout the codebase (Critical + multiple High)
2. Fix the retain cycle in `ExpensesChartViewModel` (High — memory leak)
3. Add `@MainActor` to `PlanedMaintenanceViewModel` (High — concurrency safety)

**Things to not do:**
1. Make migrations failure-aware to prevent schema corruption (High)
