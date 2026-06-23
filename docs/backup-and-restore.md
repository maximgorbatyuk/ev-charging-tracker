# Backup & Restore

For: anyone editing export, import, iCloud Drive backups, or the safety-backup pipeline. For the per-feature spec with checklists, see `../features/export_and_import.md`. For diagnostics, see `diagnostics.md` (`[DIAG-004]`).

## Audience

Backups are entirely user-driven and offline-first. There is no server. Output is a single JSON file with the entire dataset.

## Two backup paths, one format

| Path | Trigger | Destination | Retention |
|---|---|---|---|
| Manual export | User taps "Export" in Settings | Share Sheet (Files, AirDrop, Mail, Messages, …) | Caller-controlled |
| iCloud Drive | User taps "Create iCloud backup" or daily background task | `iCloud.<bundleID>/Documents/ev_charging_tracker/backups/` | 5 rolling files |
| Safety backup (auto, pre-import) | Before any destructive import | `Documents/ev_charging_tracker/safety_backups/` | 3 files, max 30 days |

All three produce the same JSON shape (`BusinessLogic/Models/ExportModels.swift` → `ExportData`).

## Export format (versioned)

`ExportData`:

```
{
  "metadata": {
    "createdAt": ISO 8601,
    "appVersion": "<MARKETING_VERSION> (<BUILD>)",
    "deviceName": "iPhone 17 Pro Max",
    "databaseSchemaVersion": 8
  },
  "cars":              [ExportCar],
  "expenses":          [ExportExpense],
  "plannedMaintenance":[ExportPlannedMaintenance],
  "delayedNotifications":[ExportDelayedNotification],
  "userSettings":      ExportUserSettings,
  "documents":         [ExportDocument],
  "ideas":             [ExportIdea]
}
```

The `databaseSchemaVersion` is sourced from `DatabaseManager.getDatabaseSchemaVersion()` (currently `8`). Import compares against the running app's schema version and warns when the backup is *newer* than the app.

## Pre-import validation

`features/export_and_import.md` lists the full checklist. The critical guarantees, all in `BusinessLogic/Services/BackupService.swift`:

- JSON is parsed and structurally validated **before** any data is wiped.
- Schema version compared. Newer-than-current → warn user; allow proceed.
- A "safety backup" of the current data is written to `Documents/ev_charging_tracker/safety_backups/` before the wipe.
- If import fails partway through, restore from the safety backup.

## File naming

```
ev_charging_tracker_export_2026-05-01_05-16-09.json
```

UTC offset is the device local timezone (matching the user's expectation of "when I made it"). Temporary export files are flagged `URLResourceKey.isExcludedFromBackupKey = true` so iOS itself does not iCloud-back them up redundantly.

## Background backup job

Daily, at midnight, when the user has enabled "Automatic iCloud backups" (Settings → Backup).

- Implementation: `BusinessLogic/Services/BackgroundTaskManager.swift`.
- Task identifier: `com.evchargingtracker.daily-backup`. Must match `BGTaskSchedulerPermittedIdentifiers` in `EVChargingTracker/Info.plist`.
- Scheduling: `BGAppRefreshTaskRequest` submitted with `earliestBeginDate = next midnight`. iOS controls the actual fire time — "exactly midnight" is best-effort.
- On launch, `BackgroundTaskManager.retryIfNeeded()` runs from `applicationWillEnterForeground` to retry a failed automatic backup if a `pendingRetry` flag is set.

## iCloud directory

`BackupService.iCloudBackupDirectory` resolves the iCloud container:

1. Compute the container ID from the bundle identifier (stripping a `Debug` suffix if present).
2. `FileManager.url(forUbiquityContainerIdentifier: "iCloud.<bundleID>")` first; fall back to the default container.
3. Append `Documents/ev_charging_tracker/backups/`.

`BackupService.isiCloudAvailable()` checks the ubiquity identity token before any iCloud read/write.

## Failure modes

| Failure | Visible behavior | Where to look |
|---|---|---|
| iCloud not signed in / disabled | Empty backup list; toast/banner in Settings | `BackupService.isiCloudAvailable()` |
| Container entitlement is `CloudKit` not `CloudDocuments` | List always empty | `[DIAG-004]` |
| Disk full during export | Export throws; UI surfaces error | `BackupService.exportData()` |
| Schema mismatch (newer backup) | Warning sheet, user can proceed | `BackupService` import flow |
| Import partway crash | Restored from safety backup on next launch | `safety_backups/` dir |
| Background task expired | `pendingRetry` set; retried on next foreground | `BackgroundTaskManager.performSilentBackup()` |

## Entitlement requirement

`com.apple.developer.icloud-services` must contain `<string>CloudDocuments</string>` and **not** `CloudKit`. The latter makes iCloud Drive files invisible to `FileManager`. See `integrations/icloud-drive.md` and `[DIAG-004]`.

## Key files

- `BusinessLogic/Services/BackupService.swift` — export, import, iCloud read/write, safety backups
- `BusinessLogic/Services/BackgroundTaskManager.swift` — daily-backup `BGTaskScheduler`
- `BusinessLogic/Models/ExportModels.swift` — `ExportData` and per-entity export structs
- `EVChargingTracker/UserSettings/iCloudBackupListView.swift` — UI for backup list
- `EVChargingTracker/EVChargingTracker.entitlements` — iCloud + container ID
- `EVChargingTracker/Info.plist` — `BGTaskSchedulerPermittedIdentifiers`
- `features/export_and_import.md` — full per-feature spec with checklists
