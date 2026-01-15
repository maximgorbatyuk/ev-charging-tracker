# Change logs

## 2026.1.4 (2026-01-16)

### What's New

🔹 **Data Export & Import**
Export all your charging data to a JSON file and import it anytime. Perfect for backing up data, moving to a new device, or sharing between devices. Exported files can be shared via AirDrop, Messages, Mail, or saved to Files.

🔹 **iCloud Backup**
Automatically back up your data to iCloud Drive. View all your backups in the Settings, restore from any device, and let the app manage multiple backups automatically.

🔹 **Enhanced Safety**
- Pre-import preview shows exactly what data will be restored
- Automatic safety backups created before any import
- Automatic rollback if import fails - your data is always safe

🔹 **Smart Backup Management**
- Keeps last 5 iCloud backups automatically
- Keeps last 3 safety backups locally
- View backup dates, sizes, and source devices
- Delete individual backups easily

### Development changes
- **Export/Import functionality**
  - Export all app data (cars, expenses, maintenance, notifications, settings) to JSON files
  - Import data from JSON files with comprehensive validation and safety mechanisms
  - Pre-import preview screen showing data summary before confirmation
  - Automatic safety backups created before import (keeps last 3 backups)
  - Share sheet integration for easy file sharing via AirDrop, Messages, Mail, etc.

- **iCloud Backup**
  - Automatic backups to iCloud Drive
  - iCloud backup management UI to view, delete, and restore backups
  - Network monitoring for connectivity-aware operations
  - Support for multiple device backups with automatic cleanup (keeps last 5 backups)

- **New Services**
  - `BackupService`: Comprehensive service for data export, import, and backup operations
  - `NetworkMonitor`: Monitors network connectivity for backup operations
  - `BackgroundTaskManager`: Handles background task scheduling for backups

- **New Models**
  - `ExportData` and related export models for serialization of all app data
  - `ExportMetadata` for tracking export version, device info, and schema compatibility

- **User Settings Enhancements**
  - New iCloud Backup section in User Settings
  - Backup list view with dates, sizes, and device information
  - Export/Import buttons with clear user guidance

- **Development Tools**
  - `setup.sh`: Automated project configuration and dependencies setup
  - `build_and_distribute.sh`: Build and distribute script for TestFlight/App Store
  - `detect_unused_code.sh`: Unused code detection utility
  - `run_lint.sh`, `run_format.sh`, `run_all_checks.sh`: Code quality automation scripts
  - Git hooks: pre-commit and pre-push for code quality enforcement
  - Comprehensive scripts documentation (`scripts/scripts.md`)

- **Changed**
  - Updated CI/CD pipeline to build-only (tests disabled for faster feedback)
  - Added SwiftLint step to GitHub workflow (optional, non-blocking)
  - Enhanced app entitlements with iCloud container access
  - Updated User Settings UI with new Export/Import and Backup sections

- **Security & Data Integrity**
  - Import validation before data deletion
  - Schema version compatibility checks
  - Automatic rollback on import failure
  - Safety backup system with automatic cleanup
  - Exclusion of temporary files from iTunes/iCloud backup


## 2026.1.3 (2026-01-10)

We have improved prices filling when adding new expense. Now, when you select a charging station, the app will suggest the last used price for that station. This should make adding expenses faster and more convenient, especially if you frequently use the same charging stations.

## 2026.1.2 (2026-01-06)

We added pagination output to Expenses screen so you will not have to scroll for ages if you have lot of records.
In addition, we changed the app version pattern, so you will know in what year and month the app was released.
We are not sure if you need this information, but we did it. Also, the previous 2026.1.1 release contained bug related to version checker, so it was fixed as well
