# Integration — iCloud Drive

For: anyone touching iCloud-related code or entitlements. For the broader backup feature (export format, safety backup, daily task), see `../backup-and-restore.md`. For diagnostics, see `[DIAG-004]` in `../diagnostics.md`.

## What we use

iCloud Drive **file storage** via the `Documents` ubiquity container — *not* CloudKit. Backup JSON files are written to the iCloud container's `Documents/ev_charging_tracker/backups/` and read back from the same path on any signed-in device.

## Required entitlement

```xml
<!-- EVChargingTracker.entitlements -->
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

**Must be `CloudDocuments`. Must NOT be `CloudKit`.**

If the entitlement is `CloudKit`, the iCloud Drive folder for this container becomes invisible to `FileManager.url(forUbiquityContainerIdentifier:)` — the in-app backup list will be permanently empty. This is `[DIAG-004]`.

Other required keys:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.com.evchargingtracker.EVChargingTracker</string></array>

<key>com.apple.developer.ubiquity-container-identifiers</key>
<array><string>iCloud.com.evchargingtracker.EVChargingTracker</string></array>

<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

The container identifier `iCloud.com.evchargingtracker.EVChargingTracker` is **legacy and intentional** — it does not match the bundle ID exactly. `BackupService.iCloudBackupDirectory` derives `iCloud.<bundleID>` and falls back to the default ubiquity container if the named one is missing, so this works in practice. Do not rename without a coordinated migration of every existing user's iCloud Drive contents.

## Container resolution

`BusinessLogic/Services/BackupService.swift:31-53`:

1. Strip `Debug` suffix from the bundle ID if present (Debug builds use a distinct bundle ID; backups should still land in the production iCloud container so the user sees the same files in either build).
2. Build `containerIdentifier = "iCloud.\(bundleID)"`.
3. `FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)` — first try the named container.
4. Fall back to `forUbiquityContainerIdentifier: nil` — the default container — if the named lookup returns nil.
5. Append `Documents/ev_charging_tracker/backups/`.

The `Documents/` subdirectory inside the ubiquity container is the standard exposed-to-user folder; the iOS Files app shows it as the app's iCloud Drive folder.

## Availability check

`BackupService.isiCloudAvailable()` checks `FileManager.default.ubiquityIdentityToken`. This is the canonical "is the user signed into iCloud and is iCloud Drive enabled" check. It is fast (no network) and cached by iOS.

Anywhere that does an iCloud read/write, gate it on `isiCloudAvailable()` first and surface the failure to the UI rather than throwing.

## File layout (in iCloud Drive)

```
iCloud.com.evchargingtracker.EVChargingTracker/
└── Documents/                                    ← visible in Files app as "EV Charge Tracker"
    └── ev_charging_tracker/
        └── backups/
            ├── ev_charging_tracker_backup_2026-05-01_05-16-09.json
            ├── ev_charging_tracker_backup_2026-04-30_05-16-09.json
            └── ev_charging_tracker_backup_2026-04-29_05-16-09.json
```

Up to **5** backups are retained (`maxiCloudBackups = 5` in `BackupService`). Older files are pruned after each successful create.

## Operations

| Operation | Method | Notes |
|---|---|---|
| Create | `BackupService.createiCloudBackup()` | Writes the export JSON; prunes oldest if > 5 |
| List | `BackupService.fetchiCloudBackups()` | Sorted by `createdAt`, newest first |
| Restore | `BackupService.restoreFromiCloudBackup(...)` | Triggers safety backup → import flow |
| Delete one | `BackupService.deleteiCloudBackup(...)` | Removes a single file |
| Delete all | `BackupService.deleteAlliCloudBackups()` | Bulk delete |

## Background creation

The daily backup task uses the same `createiCloudBackup` path. See `../backup-and-restore.md` and `BusinessLogic/Services/BackgroundTaskManager.swift`.

## Failure modes

| Symptom | Cause | Resolution |
|---|---|---|
| Empty list, even after creating a backup | `CloudKit` entitlement instead of `CloudDocuments` | Fix entitlement, rebuild |
| `isiCloudAvailable()` returns false | iCloud Drive disabled, no Apple ID | UI banner; nothing to fix in code |
| Container URL nil | Provisioning profile missing iCloud capability | Regenerate profile |
| File appears in Files but not in app list | Wrong directory; file is at `Documents/<other>/...` | Check path used during create |

See `[DIAG-004]` for the full triage.

## Key files

- `BusinessLogic/Services/BackupService.swift:24-53` — directory resolution
- `BusinessLogic/Services/BackupService.swift` — operations (create/list/restore/delete)
- `EVChargingTracker/EVChargingTracker.entitlements` — entitlement (Release)
- `EVChargingTracker/EVChargingTrackerDebug.entitlements` — entitlement (Debug)
- `EVChargingTracker/UserSettings/iCloudBackupListView.swift` — list/restore/delete UI
