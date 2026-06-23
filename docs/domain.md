# Domain — EV Charging Tracker

> **THIS DOCUMENT IS NOT FOR CODE GUIDELINES.** It describes what the entities mean in the real world and how they relate. For code rules, see `../AGENTS.md`. For DB mechanics (tables, repositories, migrations), see `persistence.md`.

For: anyone making product decisions or interpreting an unfamiliar entity. Read before you redesign a flow.

## Who this app is for

A single individual who owns one or more electric vehicles and wants a private, offline ledger of:

- How much each charging session cost and how much energy it delivered
- How that translates to cost-per-km and consumption (kWh/100km)
- How much CO₂ the EV is saving vs. an equivalent ICE vehicle
- Other car-related expenses (maintenance, repair, carwash, miscellaneous)
- A schedule of upcoming maintenance, with reminders
- Documents (registration, insurance) and ideas (links, notes) per car

There is no shared state, no multi-user, no server. Backups go to iCloud Drive (iCloud account on the device, *not* CloudKit) or to a JSON file the user shares anywhere.

## Entities

### **Car**

A vehicle the user owns. The user can have multiple; **one is "selected for tracking"** at a time, and that car is the implicit subject of the Stats and Expenses tabs.

Key fields:

- `name` — free text
- `selectedForTracking` — boolean; only one row should be `true` at a time
- `batteryCapacity` — kWh (optional)
- `expenseCurrency` — `Currency` enum
- `currentMileage`, `initialMileage` — km (numeric only; unit interpretation is per `measurementSystem`)
- `milleageSyncedAt` — when mileage was last updated
- `frontWheelSize`, `rearWheelSize` — free text (e.g., `"245/45 R19"`), optional
- `measurementSystem` — `metric` or `imperial`; **display-only conversion**, stored values are not converted

Key rules:

- Mileage is stored as an integer; the `measurementSystem` only affects display labels (`km`/`mi`) and CO₂ display (`kg`/`lb`). The stored stat math (`co2PerKm * totalDistance`) does not change. See `BusinessLogic/Models/MeasurementSystem.swift`.
- A car cannot be deleted while expenses exist for it without explicit user confirmation (see Settings → car management).
- The "active" car is part of user prefs; switching it re-scopes Stats / Expenses / Car tabs.

### **Expense**

A line item against the active car. Five kinds, distinguished by `expenseType`:

| `expenseType` | Meaning | Counts toward stats? |
|---|---|---|
| `charging` | A charging session (energy + cost) | Yes — cost-per-km, kWh/100km, CO₂ |
| `maintenance` | Scheduled service | Total cost only |
| `repair` | Unscheduled repair | Total cost only |
| `carwash` | Wash | Total cost only |
| `other` | Anything else | Total cost only |

Key fields (`BusinessLogic/Models/ExpenseModels.swift:98-194`):

- `date`
- `energyCharged` (kWh) — meaningful only for `charging`; 0 for others
- `chargerType` (`ChargerType` enum, e.g. `home7kW`, `superchargerV3`, `other`) — meaningful only for `charging`
- `odometer` (km, integer)
- `cost` — **`Double?`** (deliberate, not `Decimal`; see "Currency" below)
- `notes` (free text)
- `currency` — frozen at creation time, allowed to differ per row
- `carId` — foreign key to `Car`
- `isInitialRecord` — marks the seed row created when a car is first added (the row that establishes baseline mileage; should not be edited like a regular session)

Key rules:

- `cost` is optional — a user may log energy without a cost (e.g., free workplace charging).
- `getPricePerKWh()` returns `cost / energyCharged` only for `charging` expenses with non-zero energy and non-nil cost.
- The "initial record" exists per car and is created when the user adds the car. It carries the starting odometer reading; UI should not present it like a session.

### **Charging session vs. expense**

Functionally there is only an `Expense` table (`charging_sessions` in SQL — historical name). A "charging session" is just an expense with `expenseType == .charging`. The `charging_sessions` table name is a legacy artifact of the v1 schema; **do not rename it without a migration**.

### **PlannedMaintenance**

A future maintenance task tied to a car. Triggered by date, by odometer, or both.

Key fields (`BusinessLogic/Models/PlannedMaintenance.swift`):

- `title`, `notes`
- `triggerDate` (optional)
- `triggerOdometer` (optional km)
- Status flags: scheduled / due-soon / overdue (computed from current date + current car odometer)
- `carId`

Key rules:

- A planned-maintenance record is "due" when **either** trigger fires (date passed *or* current odometer ≥ trigger odometer).
- Marking an item "done" prefills an `Expense` form (`maintenance` type) and removes the planned record after the user confirms.
- The Car tab shows a numeric badge of pending records; the count comes from `MainTabViewModel.getPendingMaintenanceRecords()`.

### **CarDocument**

A user-uploaded file attached to a car (registration, insurance, manual…). Files live on disk in the App Group container at `AppGroupContainer.documentsStorageURL/{carId}/{fileName}`. Metadata lives in the `documents` table.

Key fields (`BusinessLogic/Models/Document.swift`):

- `customTitle` (optional, falls back to `fileName`)
- `fileName`, `filePath`, `fileType` (extension), `fileSize`
- `carId`, `createdAt`, `updatedAt`

Key rules:

- File on disk and DB row are separate. `DocumentService` (`BusinessLogic/Services/DocumentService.swift`) is the single point that keeps them in sync.
- Documents can be sourced from the camera, the photo picker, or the Files app. See `EVChargingTracker/Documents/DocumentSourcePickerView.swift`.

### **Idea**

A car-scoped note, optionally with a URL.

Key fields (`BusinessLogic/Models/Idea.swift`):

- `title` (required)
- `url` (optional; **must be `http`/`https` if present** — validated)
- `descriptionText` (optional free text)

Key rules:

- The URL field is validated at the model boundary; non-HTTP schemes are rejected.
- Ideas are *not* linked to expenses or maintenance. They're a parking lot.

### **DelayedNotification**

A scheduled local-notification record. Persisted so we can cancel/recreate notifications when a maintenance record is edited or marked done. See `notifications.md`.

### **UserSettings**

Key-value store in the `user_settings` table. Holds:

- `currency` (default `Currency.kzt`)
- `language` (one of `en`, `de`, `ru`, `kk`, `tr`, `uk`, `zh-Hans`)
- `user_id` (UUID; generated on first launch; consumed by analytics)
- `font_family` (`system` or `jetbrains_mono`; default `jetbrains_mono`)
- `ExpensesDefaultSortingValue` (sort key for the Expenses tab — `creation_date` or `odometer`)

Other prefs not in this table (intentional):

- `automaticBackupEnabled`, `lastAutomaticBackupDate`, `pendingBackupRetry` — `UserDefaults` (per-device, not synced via backup file). See `BackgroundTaskManager.swift`.
- `appearanceMode` (`system`/`light`/`dark`) — `UserDefaults`. See `AppearanceManager.swift`.
- `onboardingCompleted` — `UserDefaults` (`UserSettingsViewModel.onboardingCompletedKey`).

## Stats math

All in `EVChargingTracker/ChargingSessions/*ViewModel.swift`.

- **Cost-per-km (charging only)** = `sum(charging.cost) / (currentMileage − initialMileage)`
- **Cost-per-km (all)** = `sum(all.cost) / distance`
- **Energy efficiency (kWh/100km)** = `sum(charging.energyCharged) / distance × 100`
- **CO₂ saved** = `distance × CO2_EUROPE_POLLUTION_PER_ONE_KILOMETER`. Constant comes from `EnvironmentService.getCo2EuropePollutionPerOneKilometer()` (xcconfig: `0.17` kg/km). When the active car's `measurementSystem` is `imperial`, the displayed unit is `lb` and the value is converted at the display boundary (`kg × 1/0.453592`). The stored value is always conceptually kg.

## Currency

`Currency` enum: `usd`, `kzt`, `eur`, `byn`, `uah`, `rub`, `trl`, `aed`, `sar`, `gbp`, `jpy`, `inr`, `cny`. Stored as raw string in DB. The currency is per-expense — switching the user's default does not retroactively re-stamp old rows.

**`Expense.cost` is `Double?`, not `Decimal`** — this violates the workspace rule but is intentional in this project; changing it requires a coordinated schema + export-format + stats migration. Do not "fix" it as a side effect of another task.

## Onboarding

First-launch flow (`EVChargingTracker/Onboarding/`):

1. Language selection (one of the seven supported languages)
2. Intro pages (3 cards)
3. Skip or Finish — both write `onboardingCompletedKey = true` to `UserDefaults` and emit an analytics event

Onboarding does not create a car; the user adds one from the Settings tab afterwards.

## Backups

Two paths, both produce the same JSON shape (`BusinessLogic/Models/ExportModels.swift`):

1. **Manual export** — Share Sheet → user picks destination (Files, AirDrop, Mail, …). File name pattern: `ev_charging_tracker_export_YYYY-MM-DD_HH-mm-ss.json`.
2. **iCloud Drive backup** — written to the iCloud container under `Documents/ev_charging_tracker/backups/`. Up to **5** rolling files retained.

A pre-import "safety backup" is written to `Documents/ev_charging_tracker/safety_backups/` before any destructive import; up to 3 retained, max 30 days old.

Full mechanics: `backup-and-restore.md`.

## Hidden developer mode

Tap the App Version row in Settings → About 15 times to enable. Adds destructive testing actions (wipe data, send test notifications, populate fake expenses, font preview, document storage browser). State is in-memory only — clears on app restart. Full doc: `../features/DEVELOPER_MODE_README.md`.

## Key files

- `BusinessLogic/Models/Car.swift`
- `BusinessLogic/Models/ExpenseModels.swift`
- `BusinessLogic/Models/PlannedMaintenance.swift`
- `BusinessLogic/Models/Document.swift`
- `BusinessLogic/Models/Idea.swift`
- `BusinessLogic/Models/UserSettings.swift`
- `BusinessLogic/Models/MeasurementSystem.swift`
- `BusinessLogic/Models/Currency.swift`
- `BusinessLogic/Services/EnvironmentService.swift` (CO₂ coefficient)
- `EVChargingTracker/ChargingSessions/ChargingViewModel.swift` (stats math)
- `EVChargingTracker/ChargingSessions/ExpensesChartViewModel.swift`
