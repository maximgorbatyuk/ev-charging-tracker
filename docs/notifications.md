# Notifications

For: developers touching local notifications, the planned-maintenance reminder flow, or the foreground-notification delegate. For background-task scheduling (separate concern), see `backup-and-restore.md`.

## Scope

Local notifications only — `UserNotifications` framework. **No remote / push notifications.** No APNs registration, no FCM token fetch.

There are two notification surfaces:

1. **Planned-maintenance reminders** — scheduled when a `PlannedMaintenance` record's trigger date arrives.
2. **Backup task** — a `BGTaskScheduler` task, technically not a user-facing notification but uses the same iOS background plumbing. See `backup-and-restore.md`.

## Permission

Requested when the user first creates a planned-maintenance record (lazy ask, not on launch). The Developer Mode panel exposes "Request Permission" and "Send Notification Now" actions for QA.

## Foreground delegate

`ForegroundNotificationDelegate` (`EVChargingTracker/EVChargingTrackerApp.swift:86-127`) implements `UNUserNotificationCenterDelegate` and is wired via `@UIApplicationDelegateAdaptor`. It does two things:

1. While the app is in the foreground, display incoming notifications as banners with sound (`completion([.banner, .list, .sound])`).
2. On `applicationWillEnterForeground`, kick off `BackgroundTaskManager.retryIfNeeded()` to retry a failed automatic backup.

The `didReceive response:` handler is currently a no-op — it does not deep-link from a notification tap to a specific maintenance record. Add deep-linking here if/when needed.

## Scheduling and cancellation

`NotificationManager` (`BusinessLogic/Services/NotificationManager.swift`) is the single point that calls into `UNUserNotificationCenter`. It is consumed by:

- `PlanedMaintenanceViewModel` — schedules a notification for the trigger date when a record is created or edited.
- `DelayedNotificationsRepository` — persists the notification metadata (id, fire date, related record) so we can reliably cancel/recreate when the user edits or marks the maintenance done.

The `delayed_notifications` table acts as a queue mirror — if iOS drops a scheduled notification (rare) we still know what should have fired.

## Maintenance reminder flow

```
User creates PlannedMaintenance with triggerDate = D
  ↓
PlanedMaintenanceViewModel.save(...)
  ↓
PlannedMaintenanceRepository.upsert(...)
  ↓
NotificationManager.schedule(date: D, …)
  ↓
DelayedNotificationsRepository.upsert(record)
```

```
User edits or marks done
  ↓
NotificationManager.cancel(by id)
  ↓
DelayedNotificationsRepository.delete(record)
  ↓
(if edit) reschedule with new date
```

If `triggerDate` is `nil` and `triggerOdometer` is set, **no** notification is scheduled — odometer-based triggers are evaluated at app open by reading the current car's mileage and showing a "due soon" / "overdue" badge instead.

## Failure modes

| Failure | Visible behaviour |
|---|---|
| User denied notification permission | Badge / in-app banner still works; OS notification just doesn't fire. |
| iOS silently drops a scheduled notification | The `delayed_notifications` row stays; on next launch, code can compare against expected. (Currently we don't auto-recover; a record older than its `triggerDate` and still queued is a sign of this.) |
| App killed by system before fire | Local notifications fire whether the app is running or not. No recovery needed. |

## Background work

`BackgroundTaskManager.scheduleNextBackup()` submits a `BGAppRefreshTaskRequest` for "next midnight." iOS controls actual fire time; "exactly midnight" is best-effort. The task identifier `com.evchargingtracker.daily-backup` must match `BGTaskSchedulerPermittedIdentifiers` in `EVChargingTracker/Info.plist`. Registration must be **synchronous and complete before `application(_:didFinishLaunchingWithOptions:)` returns** — see `EVChargingTrackerApp.swift:99-101`.

## Key files

- `BusinessLogic/Services/NotificationManager.swift` — scheduling, cancellation, permission
- `BusinessLogic/Services/BackgroundTaskManager.swift` — `BGTaskScheduler` daily backup
- `BusinessLogic/Database/DelayedNotificationsRepository.swift` — persisted queue mirror
- `EVChargingTracker/EVChargingTrackerApp.swift:86-127` — foreground delegate
- `EVChargingTracker/Info.plist` — `BGTaskSchedulerPermittedIdentifiers`
- `EVChargingTracker/PlanedMaintenance/PlanedMaintenanceViewModel.swift` — caller
