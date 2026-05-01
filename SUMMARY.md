# SUMMARY — EV Charging Tracker

Agent-focused orientation. Scan in 60 seconds.

For: agents and developers picking up the repo cold. Pointers, not prose. For onboarding humans, see `DEVELOPMENT.md`.

## Stack

| Concern | Choice |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Architecture | MVVM with `ObservableObject` + `@Published` (NOT `@Observable`) |
| DB | SQLite via SQLite.swift (`@_exported import SQLite` in `BusinessLogic/Database/DatabaseManager.swift`) |
| Min iOS | 18.0 |
| Analytics | Firebase Analytics, Release builds only |
| Local notifications | `UserNotifications` |
| Background work | `BGTaskScheduler` (daily backup task) |
| Localization | Custom `LocalizationManager`, runtime `.lproj` switching, 7 langs |
| Targets | App (`EVChargingTracker/`) + Share Extension (`ShareExtension/`) |
| Tests | Swift Testing |

## Project map

```
EVChargingTracker/
├── EVChargingTracker/          # App target
│   ├── EVChargingTrackerApp.swift   # @main entry point
│   ├── MainTabView.swift             # 4-tab root
│   ├── ChargingSessions/             # Stats tab
│   ├── Expenses/                     # Expenses tab
│   ├── CarDetails/                   # Car tab + flow container
│   ├── UserSettings/                 # Settings tab
│   ├── Documents/  Ideas/  PlanedMaintenance/  # Sub-flows under Car tab
│   ├── Onboarding/  LaunchScreen/    # First-launch + splash
│   ├── Developer/                    # Hidden dev tools (15-tap unlock)
│   ├── Shared/                       # Reusable UI components
│   ├── Config/{Base,Debug,Release}.xcconfig
│   ├── Fonts/                        # JetBrains Mono TTFs
│   ├── *.lproj/Localizable.strings   # en, de, ru, kk, tr, uk, zh-Hans
│   └── *.entitlements                # main + Debug variant
├── ShareExtension/             # Share Extension target
│   ├── ShareViewController.swift
│   ├── ShareFormView{,Model}.swift
│   ├── InputParser.swift             # File/URL/text priority parser
│   └── Models/SharedInput.swift
├── BusinessLogic/              # Shared between both targets
│   ├── Database/                     # Repos + migrations + DatabaseManager
│   ├── Models/                       # Domain types
│   ├── Services/                     # Backup, Analytics, Localization, etc.
│   ├── Helpers/AppGroupContainer.swift  # Shared paths
│   └── ValueObjects/  Errors/  Extensions/  Alerts/
├── EVChargingTrackerTests/     # Swift Testing
│   └── Utils/                        # DatabaseManagerFake, Mock*Repository
├── ci_scripts/ci_post_clone.sh # Xcode Cloud — generates GoogleService-Info.plist
├── .github/workflows/          # build.yml + swiftlint.yml
├── scripts/                    # setup, format, lint, run_all_checks, detect_unused_code
├── run_tests.sh                # Local test runner
└── docs/                       # All non-trivial docs (this layer)
```

## Source-of-truth files

| Topic | File |
|---|---|
| Schema migrations | `BusinessLogic/Database/Migrations/Migration_*.swift` |
| Latest schema version | `BusinessLogic/Database/DatabaseManager.swift:45` (`latestVersion`) |
| App Group identifier (token) | `EVChargingTracker/Config/Base.xcconfig` (`APP_GROUP_IDENTIFIER`) |
| App Group container paths | `BusinessLogic/Helpers/AppGroupContainer.swift` |
| Build env tokens (Info.plist consumers) | `BusinessLogic/Services/EnvironmentService.swift` |
| Entitlements | `EVChargingTracker/EVChargingTracker{,Debug}.entitlements`, `ShareExtension/ShareExtension.entitlements` |
| App entry | `EVChargingTracker/EVChargingTrackerApp.swift` |
| Tab routing | `EVChargingTracker/MainTabView.swift` |
| CI build | `.github/workflows/build.yml` |
| Xcode Cloud secrets injection | `ci_scripts/ci_post_clone.sh` |
| Firebase init guard | `EVChargingTrackerApp.swift:93-96` (`#if DEBUG` / `#else`) |

## Quick commands

```bash
# Build
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Test (with coverage to ./build/TestResults.xcresult)
./run_tests.sh

# Format + lint + tests
./scripts/run_all_checks.sh
```

`scripts/scripts.md` documents every script in `scripts/` in detail.

## Tabs (`MainTabView.swift`)

| # | Tab | Root view | Icon | Notes |
|---|---|---|---|---|
| 0 | Stats | `ChargingSessionsView` | `bolt.car.fill` | Charging sessions, charts, CO₂ |
| 1 | Expenses | `ExpensesView` | `dollarsign.circle` | Paginated, type-filtered, sortable |
| 2 | Car | `CarDetailsView` | `car.fill` | Maintenance/documents/ideas previews; badge for pending maintenance |
| 3 | Settings | `UserSettingsView` | `gear` | Cars, currency, language, font, backup; `New!` badge when app update available |

## Repositories (all in `BusinessLogic/Database/`)

| Repository | Table | Key API |
|---|---|---|
| `ExpensesRepository` | `charging_sessions` | CRUD, paged + filtered queries |
| `CarRepository` | `cars` | Active-car selection, mileage, wheels, measurement system |
| `PlannedMaintenanceRepository` | `planned_maintenance` | Date/odometer triggers |
| `DocumentsRepository` | `documents` | Per-car file metadata |
| `IdeasRepository` | `ideas` | Per-car URL/title/notes |
| `DelayedNotificationsRepository` | `delayed_notifications` | Local notification queue |
| `UserSettingsRepository` | `user_settings` | KV: language, currency, user_id, font, sort, etc. |
| `MigrationsRepository` | `migrations` | Schema version tracking |

Each has a `*RepositoryProtocol` for testability. Mocks live in `EVChargingTrackerTests/Utils/Mock*Repository.swift`.

## Schema version table

Latest: **v8** (`DatabaseManager.swift:45`).

| v | Migration | Purpose |
|---|---|---|
| 1 | inline | `charging_sessions` table |
| 2 | inline | `user_settings` table |
| 3 | `Migration_20251021_CreateCarsTable` | `cars` + `car_id` FK on expenses |
| 4 | `Migration_20251104_CreatePlannedMaintenanceTable` | `planned_maintenance` |
| 5 | `Migration_20251114_CreateDelayedNotificationTable` | `delayed_notifications` |
| 6 | `Migration_20250131_AddWheelDetailsToCarsTable` | wheel size cols on `cars` |
| 7 | `Migration_20260301_CreateDocumentsAndIdeasTables` | `documents` + `ideas` |
| 8 | `Migration_20260501_AddMeasurementSystemToCarsTable` | `measurement_system` on `cars` |

Full pattern: `docs/persistence.md`.

## Where to dive deeper

| Question | File |
|---|---|
| What does this app actually do? | `docs/domain.md` |
| Build / config / signing | `docs/build-and-config.md` |
| Something is broken | `docs/diagnostics.md` |
| DB / repos / migrations | `docs/persistence.md` |
| Backup / restore / iCloud | `docs/backup-and-restore.md` |
| Telemetry rules | `docs/analytics.md` |
| Local notification flow | `docs/notifications.md` |
| Localization rules | `docs/localization.md` |
| Share Extension boundary | `docs/integrations/share-extension.md` |
| iCloud Drive backups | `docs/integrations/icloud-drive.md` |
| Firebase setup | `docs/integrations/firebase.md` |
| Feature matrix (impl/partial/planned) | `docs/features.md` |
| Roadmap | `docs/roadmap.md` |
| Design system | `docs/guidelines/design.md` |
| Developer mode UX | `features/DEVELOPER_MODE_README.md` |
| Backup spec (per-feature checklist) | `features/export_and_import.md` |
| Scripts in `scripts/` | `scripts/scripts.md` |
| Workspace-wide rules | `../AGENTS.md` and `../ios-guidelines/*.md` |

## Top gotchas (full list in `docs/diagnostics.md`)

- `View` is ambiguous in extension SwiftUI files — write `SwiftUI.View` explicitly.
- iCloud entitlement must be `CloudDocuments`, not `CloudKit`.
- App Group identifier is xcconfig-tokenized — never hardcode it in `.entitlements`.
- Schema migrations are append-only; never edit a past `Migration_*.swift`.
- `Expense.cost` is `Double?`, not `Decimal`. Don't "fix" it.
- `FirebaseApp.configure()` is gated on Release; Firebase modules are only linked into the main app target, not the extension.
