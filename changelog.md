# Changelog

## 2026.1.7 (2026-01-31)

- **Expense Filtering**
  - Added filter chips to Expenses screen (All, Charging, Maintenance, Repair, Car Wash, Other)
  - Filter selection updates the expense list in real-time
  - Maintains pagination and sorting when filtering

- **Planned Maintenance Improvements**
  - New filter chips for maintenance records (All, Overdue, Due Soon, Scheduled, By Mileage, By Date)
  - New detailed view for maintenance records with status badges (Overdue, Due Soon, Scheduled)
  - Quick actions from details view: Mark as Done, Edit, Duplicate, Delete
  - Ability to edit existing maintenance records
  - Duplicate maintenance records for recurring tasks
  - Streamlined maintenance item display with cleaner layout

- **Editable Charging Sessions**
  - Energy, Price per kWh, and Odometer fields are now editable when editing a charging expense
  - Interconnected calculations: changing Cost recalculates Energy (Price stays static)
  - Car odometer automatically updates if the new expense odometer is higher than current

- **Car Wheel Details**
  - Added front and rear wheel size fields to car settings
  - Toggle for same wheel size front and rear
  - Info sheet explaining metric (225/45R18) and imperial (20x9.5) wheel size formats

- **Expense Creation from Maintenance**
  - When marking maintenance as done, expense notes are pre-filled with the maintenance title and notes
  - Simplifies tracking maintenance costs

- **Localization**
  - Added translations for all new features in all supported languages (EN, DE, RU, TR, KK, UK)

## 2026.1.6 (2026-01-27)

- **Appearance Mode**
  - Added appearance mode setting to User Settings (Light, Dark, System)
  - Preference is saved locally and applied instantly across the app
  - Respects system appearance when set to "System" mode

- **Launch Screen**
  - New branded launch screen with app logo, name, version, and developer info
  - Smooth fade transition to main content
  - Green-tinted background for brand consistency

- **Bug Fixes**
  - Fixed automatic iCloud backup not triggering in the background
  - Added missing `UIBackgroundModes` capability for background fetch
  - Fixed background task registration timing issue (now registers synchronously)
  - Improved MainActor isolation for background task callbacks

- **Localization**
  - Added translations for appearance mode (System, Light, Dark) in all supported languages
  - Added app name localization for launch screen

## 2026.1.5 (2026-01-21)

- **Expenses Sorting**
  - Added ability to sort expenses by creation date or odometer
  - Sorting preference is saved and persists across app sessions

- **UI/UX Improvements**
  - Reworked Expenses screen with floating action button (FAB) for adding new expenses
  - Reworked Planned Maintenance screen with floating action button design
  - Added helpful hints for swipe actions ("swipe left to edit/delete")
  - Improved spacing and layout consistency across screens

- **User Settings**
  - Added debug view for user settings table (developer feature)

- **Website & Documentation**
  - New brutalist-style website design
  - Updated privacy policy
  - Added documentation improvements

## 2026.1.4 (2026-01-16)

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
