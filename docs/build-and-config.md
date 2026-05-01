# Build & Configuration

For: anyone editing xcconfigs, entitlements, signing, or CI. For per-integration configuration (Firebase, iCloud, Share Extension), see `integrations/`. For workspace-wide preventive checklists, see `../../ios-guidelines/potential-issue-fixes.md`.

## Targets

| Target | Type | Bundle ID | Min iOS |
|---|---|---|---|
| `EVChargingTracker` | iOS app | `dev.mgorbatyuk.EvChargeTracker` | 18.0 |
| `ShareExtension` | App extension | `mgorbatyuk.dev.EVChargeTracker.ShareExtension` | 18.0 |

Bundle IDs are also surfaced in `EVChargingTracker/Config/Base.xcconfig` (`SHARE_EXTENSION_BUNDLE_ID`) and in `ci_scripts/ci_post_clone.sh` for Firebase plist generation.

## xcconfig

| File | Configuration |
|---|---|
| `EVChargingTracker/Config/Base.xcconfig` | Defaults shared by Debug + Release |
| `EVChargingTracker/Config/Debug.xcconfig` | Debug overrides (icon set, app name, build env) |
| `EVChargingTracker/Config/Release.xcconfig` | Release overrides (production icon, name) |

### Tokens defined in `Base.xcconfig`

| Variable | Value | Consumed by |
|---|---|---|
| `GITHUB_REPO_URL` | `github.com/maximgorbatyuk/ev-charging-tracker` | About screen |
| `DEVELOPER_TELEGRAM_LINK` | `t.me/maximgorbatyuk` | About screen |
| `APP_STORE_ID` | `6754165643` | App Store link, version checker |
| `DEVELOPER_NAME` | `Maxim Gorbatyuk` | About screen, Launch screen |
| `BUILD_ENVIRONMENT` | `release` (Base) / `dev` (Debug) | `EnvironmentService.isDevelopmentMode()`, dev-mode UI gates |
| `CO2_EUROPE_POLLUTION_PER_ONE_KILOMETER` | `0.17` | Stats math (kg CO₂ per km) |
| `APP_GROUP_IDENTIFIER` | `group.dev.mgorbatyuk.evchargetracker` | Entitlements (both targets), `AppGroupContainer` |
| `SHARE_EXTENSION_BUNDLE_ID` | `mgorbatyuk.dev.EVChargeTracker.ShareExtension` | Project settings |

### Token flow (xcconfig → app)

```
xcconfig
  └─ Info.plist (build-time substitution: `$(TOKEN)`)
       └─ EnvironmentService.swift (Bundle.main.object(forInfoDictionaryKey:))
            └─ Consumers (AppGroupContainer, AnalyticsService, About screen, etc.)
```

`EVChargingTracker/Info.plist` lists the keys: `AppStoreId`, `Co2EuropePollutionPerOneKilometer`, `DeveloperTelegramLink`, `BuildEnvironment`, `AppVisibleVersion`, `DeveloperName`, `GithubRepoUrl`, `AppGroupIdentifier`, `BGTaskSchedulerPermittedIdentifiers`.

## Entitlements

Three files:

| File | Used for |
|---|---|
| `EVChargingTracker/EVChargingTracker.entitlements` | Main app, Release |
| `EVChargingTracker/EVChargingTrackerDebug.entitlements` | Main app, Debug |
| `ShareExtension/ShareExtension.entitlements` | Share Extension (both configs) |

### Required entries (main app)

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
  <array><string>iCloud.com.evchargingtracker.EVChargingTracker</string></array>
<key>com.apple.developer.icloud-services</key>
  <array><string>CloudDocuments</string></array>   <!-- NOT CloudKit -->
<key>com.apple.developer.ubiquity-container-identifiers</key>
  <array><string>iCloud.com.evchargingtracker.EVChargingTracker</string></array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
  <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
<key>com.apple.security.application-groups</key>
  <array><string>$(APP_GROUP_IDENTIFIER)</string></array>
```

The `$(APP_GROUP_IDENTIFIER)` token is resolved from xcconfig at build time. **Never hardcode the literal `group.dev.mgorbatyuk.evchargetracker`** in any entitlement file.

### Required entries (Share Extension)

```xml
<key>com.apple.security.application-groups</key>
  <array><string>$(APP_GROUP_IDENTIFIER)</string></array>
```

Same token, same resolution. Without this, the extension can't open the shared SQLite DB.

## Debug vs Release branding

Debug builds use a distinct icon set and display name to make them visible on the home screen alongside the production install. Configured via xcconfig:

| Variable | Debug | Release |
|---|---|---|
| `ASSETCATALOG_COMPILER_APPICON_NAME` | `AppIconDebug` (or similar) | `AppIcon` |
| `INFOPLIST_KEY_CFBundleDisplayName` | `Dev | EV Charge` (or similar) | `EV Charge` |

This is enforced by build settings, not by code.

## Launch screen

`INFOPLIST_KEY_UILaunchScreen_Generation = YES` is on; iOS shows a system launch screen, then `EVChargingTrackerApp` switches to a SwiftUI `LaunchScreenView` for ~0.8s before mounting the main hierarchy. See `EVChargingTracker/EVChargingTrackerApp.swift:65-80` and `EVChargingTracker/LaunchScreen/LaunchScreenView.swift`. `LaunchScreenView` must be lightweight: branded background, `AppIconImage`, app name, version, dev name. **No DB or network calls.**

## Signing

For local debug builds, automatic signing on the developer's personal team works. For release / Xcode Cloud:

- `EVChargingTracker.xcodeproj/project.pbxproj` → `TargetAttributes` block must set `DevelopmentTeam = <TEAMID>;` and `ProvisioningStyle = Automatic;` for **both** the main app and `ShareExtension` targets.
- Missing this → Xcode Cloud `exportArchive` exits with code 70. See `[DIAG-005]` in `diagnostics.md`.
- Don't use `CODE_SIGN_IDENTITY=-` CLI overrides for archive flows — that bypasses real distribution signing.

## CI

### GitHub Actions (PR validation)

Triggered on PRs targeting `develop`.

| Workflow | File | Runner | What it does |
|---|---|---|---|
| Swift Build | `.github/workflows/build.yml` | `macos-latest` | `xcodebuild -configuration Release clean build` against iPhone 17 Pro Max simulator. SwiftLint runs as `continue-on-error`. |
| SwiftLint | `.github/workflows/swiftlint.yml` | `ubuntu-latest` | Runs `norio-nomura/action-swiftlint@3.2.1` against `**/*.swift`. |

Cancel-in-progress concurrency keys mean force-pushing a PR cancels the prior run.

### Xcode Cloud (release builds + TestFlight)

`ci_scripts/ci_post_clone.sh` is invoked after a fresh clone. It:

1. Reads `FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID` from environment.
2. Writes `EVChargingTracker/GoogleService-Info.plist` with those values plus hardcoded project metadata (`BUNDLE_ID`, `PROJECT_ID`, `STORAGE_BUCKET`).
3. Verifies the file was created.

`GoogleService-Info.plist` is **not** checked into the repo (deliberate). Local Release builds will fail Firebase init unless you have a personal copy. Debug builds skip Firebase entirely (`#if DEBUG` gate).

## Branches → environments

| Branch | Maps to | Distribution |
|---|---|---|
| `main` | Production | App Store |
| `develop` | Pre-release / integration | TestFlight (manual or Xcode Cloud) |
| feature branches | n/a | Local builds only |

## Local commands

```bash
# Build (matches GitHub Actions)
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Tests with coverage
./run_tests.sh

# Format
./scripts/run_format.sh

# Lint (strict)
./scripts/run_lint.sh

# Format + lint + tests
./scripts/run_all_checks.sh
```

`scripts/scripts.md` documents each script in detail.

## Things that historically break

See `diagnostics.md`:

- `[DIAG-002]` — App Group not configured (most common: hardcoded ID in entitlements)
- `[DIAG-003]` — Firebase / BGTaskScheduler linking into ShareExtension
- `[DIAG-005]` — Xcode Cloud archive exit 70 (missing `TargetAttributes` signing keys)

## Key files

- `EVChargingTracker/Config/{Base,Debug,Release}.xcconfig`
- `EVChargingTracker/Info.plist`
- `EVChargingTracker/EVChargingTracker.entitlements`
- `EVChargingTracker/EVChargingTrackerDebug.entitlements`
- `ShareExtension/ShareExtension.entitlements`
- `EVChargingTracker.xcodeproj/project.pbxproj` — `TargetAttributes`, file exception sets
- `BusinessLogic/Services/EnvironmentService.swift` — Info.plist consumer
- `.github/workflows/build.yml`, `.github/workflows/swiftlint.yml`
- `ci_scripts/ci_post_clone.sh` — Firebase plist generation
- `scripts/scripts.md` — local scripts reference
