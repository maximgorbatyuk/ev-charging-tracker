# CLAUDE.md - EV Charging Tracker

## Project Overview

EV Charging Tracker helps electric vehicle owners track charging sessions, monitor expenses, manage maintenance schedules, and analyze costs over time.

- **Platform:** iOS 18.0+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM with `ObservableObject` + `@Published`
- **Database:** SQLite via SQLite.swift
- **Analytics:** Firebase Analytics (Release builds only)

## Build and Development Commands

```bash
# Build
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Run tests (Swift Testing framework)
./run_tests.sh

# Code quality (requires SwiftFormat, SwiftLint, Periphery — see setup.sh)
./scripts/setup.sh              # Initial setup
./scripts/run_format.sh         # Format code with SwiftFormat
./scripts/run_lint.sh           # Lint code with SwiftLint (strict mode)
./scripts/run_all_checks.sh     # Run format + lint + tests
./scripts/detect_unused_code.sh # Find unused code with Periphery
```

## Directory Structure

```
EVChargingTracker/
├── BusinessLogic/                          # Shared business logic layer
│   ├── Alerts/                             # ConfirmationData
│   ├── Database/
│   │   ├── Migrations/                     # Schema migrations (v3–v7)
│   │   ├── DatabaseManager.swift           # DatabaseManager + DatabaseManagerProtocol
│   │   ├── CarRepository.swift
│   │   ├── DelayedNotificationsRepository.swift
│   │   ├── DocumentsRepository.swift
│   │   ├── ExpensesRepository.swift
│   │   ├── IdeasRepository.swift
│   │   ├── MigrationsRepository.swift
│   │   ├── PlannedMaintenanceRepository.swift
│   │   └── UserSettingsRepository.swift
│   ├── Errors/                             # GlobalLogger, RuntimeError
│   ├── Extensions/                         # DateExtensions
│   ├── Models/                             # Car, CarDocument, Currency, Expense, Idea, PlannedMaintenance, etc.
│   ├── Services/                           # Analytics, Backup, DocumentService, Localization, etc.
│   └── ValueObjects/                       # CarDto, SharedStatsData
├── EVChargingTracker/                      # Main app target
│   ├── CarDetails/                         # Car tab: mileage/wheels info, maintenance/documents/ideas previews
│   ├── ChargingSessions/                   # Stats tab: session list, charts, CO2
│   ├── Config/                             # xcconfig files (Base, Debug, Release)
│   ├── Developer/                          # Developer mode: document storage browser
│   ├── Documents/                          # Car documents: add, list, detail, file viewer
│   ├── Expenses/                           # Expenses tab: paginated, filtered by type
│   ├── Ideas/                              # Car ideas/links: add, list, detail
│   ├── LaunchScreen/                       # Branded launch screen
│   ├── Onboarding/                         # First-launch onboarding flow
│   ├── PlanedMaintenance/                  # Planned maintenance: date/odometer triggers
│   ├── Shared/                             # Reusable UI components
│   ├── UserSettings/                       # Settings tab: car mgmt, backup, prefs
│   ├── EVChargingTrackerApp.swift          # App entry point
│   ├── MainTabView.swift                   # 4-tab layout
│   └── MainTabViewModel.swift
├── EVChargingTrackerTests/                 # Swift Testing framework tests
│   ├── Utils/                              # DatabaseManagerFake, Mock repositories
│   ├── PlanedMaintenanceViewModelTests.swift
│   └── PlannedMaintenanceItemTests.swift
├── appstore/                               # App Store metadata
│   └── releases.md                         # Release notes by version
├── ci_scripts/                             # Xcode Cloud hooks
│   └── ci_post_clone.sh                    # Generates GoogleService-Info.plist
├── docs/                                   # Landing page & privacy policy
└── scripts/                                # Dev & build scripts
```

## App Tabs (MainTabView)

| Tab | View | Icon | Description |
|-----|------|------|-------------|
| Stats | `ChargingSessionsView` | `bolt.car.fill` | Charging sessions, cost/consumption charts, CO2 savings |
| Expenses | `ExpensesView` | `dollarsign.circle` | All expenses (paginated, filtered by type, sortable) |
| Car | `CarDetailsView` | `car.fill` | Car info, maintenance preview, documents, ideas (badge for pending maintenance) |
| Settings | `UserSettingsView` | `gear` | Car management, currency, language, backup, about |

The Car tab uses `CarDetailsFlowContainerView` with `NavigationStack` and `CarFlowRoute` enum for sub-navigation to `.maintenance`, `.documents`, and `.ideas` full-list views.

## Database

SQLite file: `tesla_charging.sqlite3` (in Documents directory).

### Repositories

All in `BusinessLogic/Database/`. Each has a protocol (e.g., `CarRepositoryProtocol`).

| Repository | Purpose |
|------------|---------|
| `ExpensesRepository` | CRUD for charging sessions and expenses, filtering, pagination |
| `CarRepository` | CRUD for vehicles (name, battery, mileage, wheel sizes) |
| `PlannedMaintenanceRepository` | CRUD for maintenance schedules |
| `DocumentsRepository` | CRUD for car documents (file metadata, per-car storage) |
| `IdeasRepository` | CRUD for car ideas/links (title, URL, notes, per-car) |
| `DelayedNotificationsRepository` | CRUD for notification queue |
| `UserSettingsRepository` | User prefs (language, currency, user ID) |
| `MigrationsRepository` | Schema version tracking |

### Access Pattern

```swift
// ViewModels — direct access via default parameter
@MainActor
class ChargingViewModel: ObservableObject {
    init(db: DatabaseManager = .shared) {
        self.expensesRepository = db.expensesRepository
    }
}

// PlanedMaintenanceViewModel — uses protocol for testability
init(db: DatabaseManagerProtocol = DatabaseManager.shared) { ... }
```

### Migrations

| Version | Migration | Description |
|---------|-----------|-------------|
| 1 | (inline) | Create `charging_sessions` table |
| 2 | (inline) | Create `user_settings` table |
| 3 | `Migration_20251021_CreateCarsTable` | Create `cars` table, add `car_id` to expenses |
| 4 | `Migration_20251104_CreatePlannedMaintenanceTable` | Create `planned_maintenance` table |
| 5 | `Migration_20251114_CreateDelayedNotificationTable` | Create `delayed_notifications` table |
| 6 | `Migration_20250131_AddWheelDetailsToCarsTable` | Add wheel size columns to `cars` |
| 7 | `Migration_20260301_CreateDocumentsAndIdeasTables` | Create `documents` and `ideas` tables |

## Models

### Expense (class, Codable)

```swift
class Expense: Codable, Identifiable {
    var id: Int64?
    var date: Date
    var energyCharged: Double   // kWh
    var chargerType: ChargerType
    var odometer: Int           // km
    var cost: Double?           // NOTE: uses Double (not Decimal)
    var notes: String
    var isInitialRecord: Bool
    var expenseType: ExpenseType // .charging, .maintenance, .repair, .carwash, .other
    var currency: Currency
    var carId: Int64?
}
```

### Car (class, Codable)

```swift
class Car: Codable, Identifiable {
    var id: Int64?
    var name: String
    var selectedForTracking: Bool
    var batteryCapacity: Double?  // kWh
    var expenseCurrency: Currency
    var currentMileage: Int       // km
    var initialMileage: Int       // km
    var milleageSyncedAt: Date
    var createdAt: Date
    var frontWheelSize: String?
    var rearWheelSize: String?
}
```

### CarDocument (class, Codable)

```swift
class CarDocument: Identifiable, Codable {
    var id: Int64?
    var carId: Int64
    var customTitle: String?
    var fileName: String
    var filePath: String?
    var fileType: String       // file extension (pdf, jpg, etc.)
    var fileSize: Int64
    var createdAt: Date
    var updatedAt: Date
}
```

Files stored on disk via `DocumentService` at `AppGroup/documents/{carId}/{fileName}`.

### Idea (class, Codable)

```swift
class Idea: Identifiable, Codable {
    var id: Int64?
    var carId: Int64
    var title: String
    var url: String?           // http/https only (validated)
    var descriptionText: String?
    var createdAt: Date
    var updatedAt: Date
}
```

### Key Enums

- `ChargerType`: home3kW, home7kW, home11kW, destination22kW, publicFast50kW, publicRapid100kW, superchargerV2/V3/V4, other
- `ExpenseType`: charging, maintenance, repair, carwash, other
- `Currency`: usd, kzt, eur, byn, uah, rub, trl, aed, sar, gbp, jpy, inr, cny
- `AppLanguage`: en, de, ru, kk, tr, uk, zh-Hans

## Services

All in `BusinessLogic/Services/`:

| Service | Description |
|---------|-------------|
| `AnalyticsService` | Firebase Analytics (Release only). Persistent `user_id` via `UserSettingsRepository.fetchOrGenerateUserId()`. |
| `AppearanceManager` | Light/Dark/System mode, persisted to UserDefaults |
| `AppVersionChecker` | App Store version check via iTunes lookup API |
| `BackgroundTaskManager` | BGTaskScheduler for daily automatic iCloud backups |
| `BackupService` | JSON export/import, iCloud Drive backups, safety backups |
| `DocumentService` | File storage for car documents (save/delete/list in App Group container) |
| `EnvironmentService` | Info.plist values (app store ID, dev name, build env, CO2 factor) |
| `LocalizationManager` | Runtime language switching via `.lproj` bundles; defines global `L()` function |
| `NetworkMonitor` | Connectivity checking |
| `NotificationManager` | Local notification scheduling and cancellation |

`DeveloperModeManager` is in `EVChargingTracker/ChargingSessions/DeveloperModeManager.swift`.

## Localization

Languages: English (en), German (de), Russian (ru), Turkish (tr), Kazakh (kk), Ukrainian (uk), Simplified Chinese (zh-Hans)

Localization files: `EVChargingTracker/{lang}.lproj/Localizable.strings`

All user-facing strings use the global `L()` function:
```swift
Text(L("sessions.title"))  // Never: Text("Hardcoded string")
```

`LocalizationManager` does runtime language switching by loading `.lproj` bundles directly (not via system locale). Language is persisted in SQLite `user_settings`.

## Config (xcconfig)

Variables in `EVChargingTracker/Config/Base.xcconfig`:

| Variable | Value |
|----------|-------|
| `GITHUB_REPO_URL` | `github.com/maximgorbatyuk/ev-charging-tracker` |
| `DEVELOPER_TELEGRAM_LINK` | `t.me/maximgorbatyuk` |
| `APP_STORE_ID` | `6754165643` |
| `DEVELOPER_NAME` | `Maxim Gorbatyuk` |
| `CO2_EUROPE_POLLUTION_PER_ONE_KILOMETER` | `0.17` |
| `BUILD_ENVIRONMENT` | `dev` (Debug) / `release` (Release) |

## Entitlements

Single file: `EVChargingTracker/EVChargingTracker.entitlements`

iCloud container: `iCloud.com.evchargingtracker.EVChargingTracker`
iCloud services: `CloudDocuments` (not CloudKit)

## Key Patterns

- **MVVM**: ViewModels use `ObservableObject` + `@Published` (not `@Observable`). All ViewModels are `@MainActor`.
- **Database**: SQLite.swift via Documents directory. Repositories have protocols for testability.
- **Analytics**: Firebase in Release only (`#if DEBUG` guard). Persistent `user_id` UUID via `UserSettingsRepository`.
- **Launch screen**: `LaunchScreenView` shown for 0.8s before main content.
- **Developer mode**: 15-tap unlock on app version row via `DeveloperModeManager`.
- **App update check**: `AppVersionChecker` compares installed vs App Store version; result shown in Settings.
- **Car Details flow**: `CarDetailsRootView` → sections (car info, maintenance, documents, ideas) → `CarDetailsFlowContainerView` handles sub-navigation via `CarFlowRoute`.
- **Share Extension**: Accepts URLs, text, images, and files from other apps. Saves as expenses, ideas, or documents. Uses temp files (not in-memory data) with 50MB size limit. Shared DB via App Group.

## Share Extension Gotchas

The ShareExtension lives in `ShareExtension/` with `InputParser.swift`, `ShareFormView.swift`, `ShareFormViewModel.swift`, `ShareViewController.swift`, and `Models/SharedInput.swift`. It shares `BusinessLogic/` with the main app.

Known pitfalls:

### `View` type ambiguity
`DatabaseManager.swift` uses `@_exported import SQLite`, which makes `SQLite.View` visible globally. In any SwiftUI file compiled for the extension, bare `View` is ambiguous. Always use `SwiftUI.View` (or `SwiftUICore.View`) explicitly — see `ShareFormView.swift` and `UserSettingsView.swift`.

### Extension-unavailable APIs
Files in `BusinessLogic/` that use APIs unavailable in app extensions must be excluded from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `project.pbxproj`. Currently excluded:
- `Services/AnalyticsService.swift` — imports Firebase, which the extension doesn't link
- `Services/BackgroundTaskManager.swift` — uses `BGTaskScheduler`, unavailable in extensions

When adding new services to `BusinessLogic/` that use extension-restricted APIs (`BGTaskScheduler`, `FirebaseAnalytics`, etc.), add them to the exception set.

### `Bundle.main` in extensions
`Bundle.main` in an app extension points to the extension's `.appex` bundle, not the containing app. `LocalizationManager` handles this by detecting `.appex` and navigating to the containing app bundle for `.lproj` resources. If you add other code that reads from `Bundle.main` (e.g., `Info.plist` keys), be aware it may return different values in the extension context. `EnvironmentService.getAppGroupIdentifier()` works because `AppGroupIdentifier` is duplicated in both the main app and extension `Info.plist` files.

### Database path
The SQLite database lives in the shared App Group container (not Documents). `DatabaseManager` calls `DatabaseMigrationHelper.migrateToAppGroupIfNeeded()` on first access to move existing databases. The migration flag is stored in shared `UserDefaults(suiteName:)` so both the app and extension can read it.

## CI/CD

- **Xcode Cloud**: `ci_scripts/ci_post_clone.sh` generates `GoogleService-Info.plist` from secrets (`FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID`)
- **GitHub Actions**: `.github/workflows/build.yml` (build), `.github/workflows/swiftlint.yml` (lint)

## App Store Release Notes Style Guide

### Tone & Voice
- **Conversational and warm**, like a small team talking to a friend — not corporate
- Use "we" (Мы/We) addressing "you" (вы/you) directly
- No hype, no exclamation marks, no marketing buzzwords

### Structure
- **One flowing paragraph**, not bullet points
- Connect ideas naturally with commas, "а также", "чтобы", dashes, "and"
- One sentence can carry 2-3 ideas linked together, like spoken language
- Keep it short — 2-3 sentences max

### Content Selection
- Pick only **1-2 user-visible features** + a general stability/fix mention
- Focus on **user benefit**, not technical detail
- Downplay internal/technical work vaguely: "improved app stability"
- Mention bug fixes casually without drama

### What to NEVER include
- Technical jargon (no "database-level pagination", "SQL filtering", "@MainActor")
- Bullet points or structured lists
- Feature counts ("5 new features!")
- Developer-facing changes (refactoring, code quality, architecture)

### Example (good)
```
We added the ability to store your wheel sizes so you never forget them when buying new tires. We also improved app stability and fixed incorrect chart calculations on the main screen.
```
