# Analytics

For: anyone adding tracking calls or debugging telemetry. For Firebase/Xcode-Cloud setup, see `integrations/firebase.md`. For the workspace-wide telemetry rules (event naming, GA4 limits, privacy), see `../../ios-guidelines/analytics-guideline.md`.

## Provider

Firebase Analytics. **Release builds only.** Debug builds log to OSLog and skip the network entirely.

The gate is in `EVChargingTrackerApp.swift:93-96`:

```swift
#if DEBUG
#else
FirebaseApp.configure()
#endif
```

`AnalyticsService.trackEvent` always calls `Analytics.logEvent(...)`, but without `FirebaseApp.configure()` the calls are no-ops. Do not move `FirebaseApp.configure()` outside the `#else` branch.

## Persistent user_id

Every install gets a UUID generated on first launch and stored in the `user_settings` table. It is attached to every event as a global property.

Flow (`BusinessLogic/Services/AnalyticsService.swift:24-40`):

1. `AnalyticsService.init()` calls `initializeUserId()`.
2. `initializeUserId()` reads from `userSettingsRepository.fetchOrGenerateUserId()`.
3. `fetchOrGenerateUserId()` returns an existing UUID, or generates a new one and persists it.
4. Subsequent `trackEvent` calls merge the user_id into `getGlobalProperties()`.

The user_id rides on every event. Do not introduce a parallel user-id mechanism (`UserDefaults`, in-memory only, etc.) — they will diverge.

## Global properties (sent with every event)

| Property | Source |
|---|---|
| `session_id` | UUID generated at `AnalyticsService.init()`, lifetime = process lifetime |
| `app_version` | `EnvironmentService.getAppVisibleVersion()` (e.g., `"2026.5.1 (123)"`) |
| `environment` | `EnvironmentService.getBuildEnvironment()` — `"dev"` or `"release"` |
| `platform` | `"iOS"` |
| `os_version` | `UIDevice.current.systemVersion` |
| `app_language` | `Locale.current.language.languageCode?.identifier` |
| `user_id` | UUID from `user_settings.user_id` (persistent across launches) |

These are computed once and cached in `AnalyticsService._globalProps`.

## Public API

```swift
AnalyticsService.shared.trackEvent("expense_added", properties: ["type": "charging"])
AnalyticsService.shared.trackScreen("Stats")
AnalyticsService.shared.trackButtonTap("save", screen: "AddExpense")
AnalyticsService.shared.identifyUser(userId, properties: [...])  // rarely used; user_id is auto-attached
```

In Debug, every call also logs the merged event to OSLog (`subsystem: "AnalyticsService", category: "Analytics"`), which is useful for verifying tracking during development without firing real events.

## GA4 naming limits (cross-cutting reminder)

GA4 enforces:

- Event name ≤ 40 chars, lowercase, no spaces
- Parameter name ≤ 40 chars
- Parameter value ≤ 100 chars
- Up to 25 parameters per event

See `../../ios-guidelines/analytics-guideline.md` for the full list.

## ShareExtension boundary

`AnalyticsService.swift` imports `FirebaseAnalytics`, which the extension does not link. The file is excluded from the ShareExtension target via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `EVChargingTracker.xcodeproj/project.pbxproj`. **Do not call `AnalyticsService` from extension code.** If you need extension-side telemetry later, move it behind a protocol and provide a no-op implementation for the extension.

## Privacy

- The user_id is a random UUID — not derived from anything personally identifying.
- No expense data, car data, or PII is sent to Firebase. Events are interaction signals only ("expense_added"), never the values themselves.
- The user can delete their data via Settings → "Delete all data" (developer mode) or by uninstalling. The Firebase user_id will then regenerate on the next install.

## Debugging

| Question | Where to look |
|---|---|
| Is my event being sent? | Run a Release build; check Firebase DebugView. |
| Is it firing in Debug? | Look at Console.app or Xcode console — search for `Analytics Event:`. |
| Why is `environment` `"dev"` in my Release build? | `BUILD_ENVIRONMENT` xcconfig is wrong; should be `release` in `Release.xcconfig`. |
| Can I add a custom property? | Yes, pass it in `properties:`. Mind GA4 limits. |

See `[DIAG-006]` in `diagnostics.md` for "events not appearing."

## Key files

- `BusinessLogic/Services/AnalyticsService.swift` — service + global props + user_id init
- `BusinessLogic/Services/EnvironmentService.swift` — environment, version, language helpers
- `BusinessLogic/Database/UserSettingsRepository.swift:117-135` — `fetchOrGenerateUserId`
- `EVChargingTracker/EVChargingTrackerApp.swift:93-96` — Firebase Release-only init
- `ci_scripts/ci_post_clone.sh` — `GoogleService-Info.plist` generation in Xcode Cloud
- `EVChargingTracker.xcodeproj/project.pbxproj` — extension target exclusion of `AnalyticsService.swift`
