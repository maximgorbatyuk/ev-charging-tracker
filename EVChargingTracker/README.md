# EVChargingTracker (app target)

The main iOS application target. Bundle ID: `dev.mgorbatyuk.EvChargeTracker`. Min iOS: 18.0.

For: developers picking up this target. For repo-level orientation, see `../SUMMARY.md`. For agent rules, see `../AGENTS.md`. For domain meaning of the entities used here, see `../docs/domain.md`.

## What's in this directory

```
EVChargingTracker/
├── EVChargingTrackerApp.swift          # @main entry, Firebase gate, BG-task registration
├── MainTabView.swift                   # 4-tab root
├── MainTabViewModel.swift
├── ChargingSessions/                   # Stats tab — sessions, charts, CO₂
├── Expenses/                           # Expenses tab — list, filters, sorting
├── CarDetails/                         # Car tab + CarDetailsFlowContainerView
├── PlanedMaintenance/                  # Sub-flow under Car tab
├── Documents/                          # Sub-flow under Car tab
├── Ideas/                              # Sub-flow under Car tab
├── UserSettings/                       # Settings tab
├── Onboarding/                         # First-launch flow
├── LaunchScreen/                       # Branded splash (SwiftUI)
├── Developer/                          # 15-tap-unlocked tools (storage browser, font preview)
├── Shared/                             # Reusable UI components (AppButton, AppCard, AppFont, …)
├── Config/{Base,Debug,Release}.xcconfig
├── Fonts/                              # JetBrains Mono TTFs
├── Assets.xcassets/                    # App icons, colors, images
├── *.lproj/Localizable.strings         # 7 language string tables
├── EVChargingTracker.entitlements      # Release entitlements
├── EVChargingTrackerDebug.entitlements # Debug entitlements
└── Info.plist
```

## Entry point

`EVChargingTrackerApp.swift` (`@main`):

1. `init()` warms `DatabaseManager.shared` (so migrations run before any DB-backed UI mounts) and starts `AppFontAppearance`.
2. `body` shows `LaunchScreenView` for ~0.8s, then transitions to `OnboardingView` (if onboarding incomplete) or `MainTabView`.
3. The injected `ForegroundNotificationDelegate` registers the `BGTaskScheduler` daily-backup task and conditionally calls `FirebaseApp.configure()` (Release only).

`MainTabView.swift` defines the four tabs (Stats / Expenses / Car / Settings) — see the table in `../SUMMARY.md`.

## Build, run, test

```bash
# From the repo root:
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

./run_tests.sh
```

The Xcode scheme is `EVChargingTracker`. Default simulator is iPhone 17 Pro Max. CI uses `Release` configuration.

## Configuration

All build-time configuration flows through xcconfig. See `../docs/build-and-config.md` for the full token table. The most important tokens:

| Token | What it controls |
|---|---|
| `APP_GROUP_IDENTIFIER` | Shared SQLite + document storage with the ShareExtension |
| `BUILD_ENVIRONMENT` | `dev` / `release` — drives `EnvironmentService.isDevelopmentMode()` and gating dev UI |
| `APP_STORE_ID` | App Store deep link, version checker |
| `CO2_EUROPE_POLLUTION_PER_ONE_KILOMETER` | CO₂ math constant (kg/km) |

## Environment variables and Info.plist keys

`EVChargingTracker/Info.plist` reads xcconfig tokens via `$(TOKEN)` substitution. `BusinessLogic/Services/EnvironmentService.swift` is the canonical reader; never read `Bundle.main.infoDictionary` directly from views or view models.

| Info.plist key | xcconfig source | Reader |
|---|---|---|
| `AppGroupIdentifier` | `APP_GROUP_IDENTIFIER` | `EnvironmentService.getAppGroupIdentifier()` |
| `AppStoreId` | `APP_STORE_ID` | `EnvironmentService.getAppStoreId()` |
| `BuildEnvironment` | `BUILD_ENVIRONMENT` | `EnvironmentService.getBuildEnvironment()` |
| `Co2EuropePollutionPerOneKilometer` | `CO2_EUROPE_POLLUTION_PER_ONE_KILOMETER` | `EnvironmentService.getCo2EuropePollutionPerOneKilometer()` |
| `DeveloperName` | `DEVELOPER_NAME` | `EnvironmentService.getDeveloperName()` |
| `DeveloperTelegramLink` | `DEVELOPER_TELEGRAM_LINK` | `EnvironmentService.getDeveloperTelegramLink()` |
| `GithubRepoUrl` | `GITHUB_REPO_URL` | `EnvironmentService.getGitHubRepositoryUrl()` |
| `BGTaskSchedulerPermittedIdentifiers` | (literal) | `BackgroundTaskManager.dailyBackupTaskIdentifier` must match |
| `UIAppFonts` | (literal) | `AppFont` / `AppFontAppearance` |
| `NSCameraUsageDescription` | (literal) | iOS permission prompt for document capture |

## Tabs at a glance

See `../SUMMARY.md` for the table. Sub-flow architecture for the Car tab:

```
CarDetailsView  (tab root)
  └─ CarDetailsFlowContainerView  (NavigationStack)
       └─ CarDetailsRootView
            ├─ Car info section
            ├─ Maintenance section  → CarFlowRoute.maintenance → PlanedMaintenanceView
            ├─ Documents section    → CarFlowRoute.documents   → DocumentsListView
            └─ Ideas section        → CarFlowRoute.ideas       → IdeasListView
```

Sub-flow lists open inside the same `NavigationStack` driven by `CarFlowRoute` enum.

## Where to look

| Question | File |
|---|---|
| Where does the app start? | `EVChargingTrackerApp.swift` |
| Tab layout | `MainTabView.swift` |
| Stats math | `ChargingSessions/ChargingViewModel.swift` and `ExpensesChartViewModel.swift` |
| Settings (cars, currency, language, font, backup, about) | `UserSettings/UserSettingsView.swift` |
| Onboarding | `Onboarding/OnboardingView.swift` |
| Developer mode tools | `Developer/`, gated by `ChargingSessions/DeveloperModeManager.swift` |
| Shared components | `Shared/` |
| DB / business logic | `../BusinessLogic/` |

## Key files

- `EVChargingTracker/EVChargingTrackerApp.swift` — entry point
- `EVChargingTracker/MainTabView.swift` — tab layout
- `EVChargingTracker/Info.plist` — token consumers
- `EVChargingTracker/Config/Base.xcconfig` — token definitions
- `EVChargingTracker/EVChargingTracker.entitlements` — iCloud, App Group
- `EVChargingTracker/ChargingSessions/DeveloperModeManager.swift` — 15-tap unlock
- `EVChargingTracker/Shared/AppFont.swift` and `AppFontAppearance.swift` — font system
