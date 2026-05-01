# Integration — Firebase Analytics

For: anyone configuring Firebase, debugging missing events, or onboarding a new build environment. For event/property semantics, see `../analytics.md`. For workspace-wide telemetry rules, see `../../../ios-guidelines/analytics-guideline.md`. Diagnostics: `[DIAG-006]`, `[DIAG-010]`.

## Scope

Firebase Analytics only. **No Crashlytics, no Remote Config, no Cloud Messaging, no Auth.** Adding any of those means a new dependency, an entitlement review, and a privacy-policy update.

## Release-only initialization

`EVChargingTrackerApp.swift:93-96`:

```swift
#if DEBUG
#else
FirebaseApp.configure()
#endif
```

Debug builds **never** configure Firebase. `AnalyticsService.trackEvent(...)` still calls `Analytics.logEvent`, but the underlying SDK is unconfigured and the calls are no-ops. The Debug build also logs every event to OSLog so you can verify your tracking locally.

**Do not move `FirebaseApp.configure()` outside the `#else` branch.** Doing so would emit dev-build events into production analytics.

## `GoogleService-Info.plist`

The Firebase SDK reads its config from `EVChargingTracker/GoogleService-Info.plist`. The file is **not committed**.

| Build path | How the file gets there |
|---|---|
| Local Debug | Not needed (Firebase isn't configured) |
| Local Release | Manually copied into `EVChargingTracker/` by the developer |
| Xcode Cloud | Generated at clone time by `ci_scripts/ci_post_clone.sh` from secrets |

### `ci_post_clone.sh` (Xcode Cloud)

`ci_scripts/ci_post_clone.sh` reads the following environment variables (set on the Xcode Cloud workflow):

| Variable | Source |
|---|---|
| `FIREBASE_API_KEY` | Firebase console → Project settings → General → Web API Key |
| `FIREBASE_GCM_SENDER_ID` | Firebase console → Project settings → Cloud Messaging → Sender ID |
| `FIREBASE_APP_ID` | Firebase console → Project settings → General → iOS app → App ID |

Hardcoded in the script (intentional, low-secrecy):

| Field | Value |
|---|---|
| `BUNDLE_ID` | `dev.mgorbatyuk.EvChargeTracker` |
| `PROJECT_ID` | `ev-charge-tracker-851bf` |
| `STORAGE_BUCKET` | `ev-charge-tracker-851bf.firebasestorage.app` |

Other booleans (`IS_ADS_ENABLED=false`, `IS_ANALYTICS_ENABLED=false`, …) are written as-is. Note that `IS_ANALYTICS_ENABLED=false` does **not** prevent Analytics; it only affects Firebase's auto-collected events. Custom `Analytics.logEvent` calls go through regardless.

## Source-of-truth for events / properties

`BusinessLogic/Services/AnalyticsService.swift`:

- `trackEvent(name, properties:)` — generic event logger
- `trackScreen(screenName, properties:)` — screen view (sets `AnalyticsParameterScreenName` and `AnalyticsParameterScreenClass`)
- `trackButtonTap(buttonName, screen:, additionalParams:)` — emits `button_tapped`
- `identifyUser(userId, properties:)` — pass-through to `Analytics.setUserID` and `setUserProperty`

Global properties merged into every event: `session_id`, `app_version`, `environment`, `platform`, `os_version`, `app_language`, `user_id`. See `../analytics.md`.

## ShareExtension boundary

`AnalyticsService.swift` imports `FirebaseAnalytics`. The extension target does not link Firebase. The file is excluded from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`. **Do not call `AnalyticsService` from `ShareExtension/`** code or from any `BusinessLogic/` file that the extension also compiles. See `[DIAG-003]`.

## Privacy

- The Firebase user_id is a random UUID generated locally on first launch (`UserSettingsRepository.fetchOrGenerateUserId()`) — not derived from any personally identifying data.
- No expense values, car data, or document contents are sent. Events are interaction signals (`expense_added`, `tab_switched`, `button_tapped`).
- `IS_ADS_ENABLED=false` in the generated plist disables the ad-tracking pieces of Firebase.

## Verifying events

| Goal | How |
|---|---|
| Verify events fire in Debug | Console.app or Xcode console; search `Analytics Event:`. Network is not used. |
| Verify events reach Firebase | Run a Release build; enable Firebase DebugView (`adb shell setprop debug.firebase.analytics.app dev.mgorbatyuk.EvChargeTracker` for Android — for iOS, use `-FIRDebugEnabled` launch arg). |
| Verify event in production | Firebase console → Analytics → Events. Up to ~24h aggregation lag. |

## Failure modes

See `[DIAG-006]`. Most-frequent cause of "events not appearing" is **running a Debug build**.

## Key files

- `EVChargingTracker/EVChargingTrackerApp.swift:93-96` — Release-only init
- `BusinessLogic/Services/AnalyticsService.swift` — service + global props
- `BusinessLogic/Database/UserSettingsRepository.swift:117-135` — persistent user_id
- `ci_scripts/ci_post_clone.sh` — `GoogleService-Info.plist` generation
- `EVChargingTracker.xcodeproj/project.pbxproj` — extension exclusion
- `EVChargingTracker/.gitignore` (or root `.gitignore`) — confirms `GoogleService-Info.plist` is ignored
