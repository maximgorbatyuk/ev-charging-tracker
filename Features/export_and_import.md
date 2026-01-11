# Export/Import and Backup Features

Date: 2026-01-11

Overview: The app should have the following features:

- Export data to a file
- Import data from a file
- Backup data to iCloud
- Restore data from iCloud

## 1. Export Data to a File

The app should allow the user to export data to a file. The file should be a JSON file containing all following data:

### Export File Structure
- [ ] Creation datetime (ISO 8601 format)
- [ ] Current version of the app (e.g., "2026.1.1")
- [ ] Device name (e.g., "iPhone 15 Pro")
- [ ] Database schema version (integer)
- [ ] Cars array
- [ ] Expenses array
- [ ] Planned Maintenance records array
- [ ] Delayed Notifications array
- [ ] User Settings object

### Export Features
- [ ] Export should use Share Sheet to allow sharing via AirDrop, Messages, Mail, Files app, etc.
- [ ] Exported file should be named: `ev_charging_tracker_export_YYYY-MM-DD_HH-mm-ss.json`
- [ ] Temporary export files should be excluded from iTunes/iCloud backup using `URLResourceKey.isExcludedFromBackupKey`
- [ ] Export should show progress indicator for large datasets
- [ ] Export should handle errors gracefully (disk full, permission denied, etc.)

## 2. Import Data from a File

### Pre-Import Validation (Critical - Before Wiping Data)
- [ ] Validate JSON structure and syntax (catch malformed JSON early)
- [ ] Validate schema version compatibility with current app version
- [ ] If schema version is newer than app version, show warning: "This backup was created with a newer version of the app. Import may fail or cause data loss."
- [ ] If schema version is much older, show compatibility warning
- [ ] Validate required fields exist: creation datetime, app version, schema version, data arrays
- [ ] Validate data integrity:
  - [ ] Dates are not in the future (unless reasonable for planned maintenance)
  - [ ] Numeric values are positive where applicable (costs, energy, odometer)
  - [ ] Currency codes are valid
  - [ ] Enum values (ChargerType, ExpenseType) are valid
  - [ ] References are valid (e.g., expense.carId exists in cars array)

### Pre-Import Preview
- [ ] Show preview screen before importing with:
  - [ ] Source: device name and export date
  - [ ] App version that created the export
  - [ ] Schema version
  - [ ] Data summary: count of cars, expenses, maintenance records, notifications
  - [ ] Date range of expenses (earliest to latest)
  - [ ] **Warning message**: "Importing will DELETE ALL existing data. This cannot be undone."
  - [ ] Two buttons: "Cancel" and "Import and Replace All Data" (red/destructive style)

### Safety Backup Before Import
- [ ] Create automatic safety backup of current data before wiping
- [ ] Safety backup stored in: `/documents/ev_charging_tracker/safety_backups/`
- [ ] Safety backup named: `safety_backup_before_import_YYYY-MM-DD_HH-mm-ss.json`
- [ ] Keep only the last 3 safety backups, delete older ones
- [ ] If import fails, automatically offer to restore from safety backup

### Import Process
- [ ] Use SwiftUI `fileImporter` modifier to select source file
- [ ] Support selecting from: iCloud Drive, On My iPhone, or any file provider
- [ ] Default suggested directory: `/documents/ev_charging_tracker/export_data` in iCloud Drive
- [ ] Create default directory if it doesn't exist
- [ ] Show progress indicator during import with message: "Importing data..."
- [ ] Disable all UI during import to prevent concurrent operations
- [ ] After validation passes, create safety backup
- [ ] Wipe all existing data (cars, expenses, maintenance, notifications, settings)
- [ ] Import new data
- [ ] Verify import success (data counts match expectations)
- [ ] If import fails at any step, restore from safety backup
- [ ] Show success message with imported data summary
- [ ] No partial import allowed - all or nothing

### Import Error Handling
- [ ] If JSON is malformed: "Invalid file format. Please select a valid backup file."
- [ ] If schema version incompatible: "This backup is from an incompatible version of the app."
- [ ] If validation fails: "Import failed: [specific reason]"
- [ ] If import fails mid-process: "Import failed. Restoring previous data..." then auto-restore
- [ ] All errors should be shown in user-friendly alert dialogs

## 3. Backup Data to iCloud

### Backup File Structure
The backup file should be identical in format to export files to ensure compatibility. Each backup is a JSON file containing:
- [ ] Creation datetime (ISO 8601 format)
- [ ] Current version of the app (e.g., "2026.1.1")
- [ ] Device name (e.g., "iPhone 15 Pro")
- [ ] Database schema version (integer)
- [ ] Cars array
- [ ] Expenses array
- [ ] Planned Maintenance records array
- [ ] Delayed Notifications array
- [ ] User Settings object

### Backup Storage Strategy
- [ ] Multiple versioned backups with timestamps in filename
- [ ] Backup file naming convention:
  - Production: `ev_charging_tracker_backup_YYYY-MM-DD_HH-mm-ss.json`
  - Development: `ev_charging_tracker_backup_dev_YYYY-MM-DD_HH-mm-ss.json`
- [ ] Storage location: iCloud Drive `/documents/ev_charging_tracker/backups/`
- [ ] Use `NSFileCoordinator` for safe iCloud file access to handle sync conflicts
- [ ] Maximum 5 backup files stored (oldest deleted automatically when limit exceeded)
- [ ] Automatic cleanup of backup files older than 30 days
- [ ] When both limits apply, delete whichever files are necessary to meet both constraints

### Manual Backup
- [ ] Button in Settings View to trigger manual backup
- [ ] Show progress indicator during backup: "Creating backup..."
- [ ] Disable backup button during backup operation
- [ ] On success: show timestamp label under backup section (no popup notification)
- [ ] Success label: "Last backup: [date and time]"
- [ ] On failure: show alert with error reason

### Automatic Backup
- [ ] Daily automatic backup at 12:00 AM local time
- [ ] Use `BGTaskScheduler` for background task scheduling
- [ ] Add required background modes capability in Xcode project
- [ ] If app is not running at midnight, backup runs when app next becomes active
- [ ] Automatic backups should be silent (no notifications)
- [ ] If automatic backup fails (no network, iCloud full, etc.), retry on next app launch
- [ ] Don't show error alerts for automatic backup failures (user not expecting it)

### iCloud Requirements and Error Handling
- [ ] Check if user is signed into iCloud before attempting backup
- [ ] If not signed in: "You must be signed into iCloud to use automatic backups."
- [ ] Check network connectivity before attempting backup
- [ ] If offline: "No internet connection. Backup requires network access."
- [ ] Check iCloud storage quota before backup
- [ ] If storage full: "iCloud storage is full. Please free up space or upgrade your plan."
- [ ] Handle iCloud sync conflicts gracefully (if backup modified on another device)
- [ ] All error messages should be user-friendly and actionable

## 4. Restore Data from iCloud Backup

### Restore Process (Same as Import with Additional Features)
- [ ] Button in Settings View to restore from iCloud backup
- [ ] Show list of available backups in modal sheet/dialog with:
  - [ ] Filename
  - [ ] Creation date and time
  - [ ] Device name that created the backup
  - [ ] App version
  - [ ] File size
  - [ ] Delete button for each backup (swipe-to-delete or edit mode)
- [ ] Tapping a backup shows preview screen (same as import preview in section 2)
- [ ] Follow all validation and safety backup steps from Import section
- [ ] After successful restore, show success message
- [ ] User can cancel at any point before confirmation

### Restore Error Handling
- [ ] If no backups exist: "No backups found in iCloud."
- [ ] If backup file is corrupted: "This backup file is corrupted and cannot be restored."
- [ ] If network unavailable: "Cannot access iCloud. Check your internet connection."
- [ ] All restore errors should offer option to try again or cancel

## 5. Delete Backups

### Delete Single Backup
- [ ] Swipe-to-delete on backup list
- [ ] Confirmation alert: "Are you sure you want to delete this backup? This cannot be undone."
- [ ] Two buttons: "Cancel" and "Delete" (red/destructive)

### Delete All Backups
- [ ] Button in Settings View: "Delete All Backups"
- [ ] Confirmation alert: "Are you sure you want to delete all backups? This cannot be undone."
- [ ] Two buttons: "Cancel" and "Delete All" (red/destructive)
- [ ] On success: "All backups deleted."
- [ ] Update UI to reflect no backups available

## UI/UX Guidelines

### Settings View Layout
- [ ] The backup and restore functionality should be accessible from the Settings View
- [ ] Create dedicated "Backup & Restore" section in Settings View
- [ ] Section should include:
  - [ ] Manual backup button: "Backup Now"
  - [ ] Last backup timestamp label (if backup exists)
  - [ ] View backups button: "View Backup History" → opens backup list modal
  - [ ] Delete all backups button (destructive style)
  - [ ] Automatic backup toggle: "Daily Automatic Backup"
  - [ ] Export data button: "Export Data..." → opens share sheet
  - [ ] Import data button: "Import Data..." → opens file picker

### Progress Indicators
- [ ] Show progress indicator during backup with message: "Creating backup..."
- [ ] Show progress indicator during restore with message: "Restoring data..."
- [ ] Show progress indicator during import with message: "Importing data..."
- [ ] Show progress indicator during export with message: "Preparing export..."
- [ ] Disable all buttons in the section while operation is in progress
- [ ] Use iOS standard `ProgressView` component

### Visual Feedback
- [ ] Use SF Symbols for icons:
  - [ ] Backup: `arrow.up.doc` or `icloud.and.arrow.up`
  - [ ] Restore: `arrow.down.doc` or `icloud.and.arrow.down`
  - [ ] Export: `square.and.arrow.up`
  - [ ] Import: `square.and.arrow.down`
  - [ ] Delete: `trash` (red color)
- [ ] Success states should use green checkmark or success message
- [ ] Error states should use red alert icon
- [ ] Provide haptic feedback on success/failure (`.success`, `.error`)

## Technical Requirements

### File Format and Structure
- [ ] No filesize limit for backup, export, and import files
- [ ] File format: JSON with UTF-8 encoding
- [ ] Backup file and export file MUST use identical JSON structure (100% compatible)
- [ ] Use `Codable` protocol for JSON encoding/decoding
- [ ] All dates in ISO 8601 format with timezone
- [ ] All monetary values as strings to preserve precision (avoid floating point issues)

### File Security and Protection
- [ ] No encryption required for backup/export files (user's responsibility if needed)
- [ ] Files stored in app's Documents directory should use `FileProtectionType.complete`
- [ ] This ensures files are encrypted at rest using device passcode
- [ ] Files are only accessible when device is unlocked

### iOS-Specific Implementation

#### iCloud Integration
- [ ] Use `FileManager.default.url(forUbiquityContainerIdentifier:)` to get iCloud container URL
- [ ] Specify iCloud container identifier in Xcode project capabilities
- [ ] Use `NSFileCoordinator` for all iCloud file operations to prevent conflicts
- [ ] Use `NSFilePresenter` if monitoring iCloud file changes is needed
- [ ] Handle iCloud availability changes (user signs out, disables iCloud Drive)

#### File Paths
- [ ] iCloud backup directory: `<iCloudContainer>/Documents/ev_charging_tracker/backups/`
- [ ] iCloud export directory: `<iCloudContainer>/Documents/ev_charging_tracker/export_data/`
- [ ] Local safety backup directory: `<AppDocuments>/ev_charging_tracker/safety_backups/`
- [ ] Temporary export files: `FileManager.default.temporaryDirectory`
- [ ] Create directories if they don't exist using `FileManager.createDirectory(withIntermediateDirectories:)`

#### Background Tasks
- [ ] Register background task identifier in Info.plist: `com.yourapp.daily-backup`
- [ ] Use `BGTaskScheduler` to schedule daily backup at midnight
- [ ] Request background task time when backup is scheduled
- [ ] Handle early termination gracefully if system ends background task
- [ ] Don't show UI during background backup

### Concurrency and Thread Safety
- [ ] All file operations must run on background queue (not main thread)
- [ ] UI updates must be dispatched to `@MainActor`
- [ ] Use Swift async/await for all async operations
- [ ] Prevent concurrent backup/restore/import/export operations using actor or serial queue
- [ ] Lock UI during operations to prevent user from triggering multiple operations

### Network and Connectivity
- [ ] Check network reachability before iCloud operations
- [ ] Use `Network` framework or check `FileManager.ubiquityIdentityToken`
- [ ] Handle offline mode gracefully with user-friendly error messages
- [ ] Don't retry iCloud operations excessively (avoid battery drain)

### Error Handling and Logging
- [ ] Use structured logging for all operations (os.Logger or similar)
- [ ] Log backup/restore operations with timestamp, result, file size
- [ ] Don't log sensitive user data (personal info, costs)
- [ ] Capture errors with context (file path, operation type, error description)
- [ ] Show user-friendly error messages, but log technical details

### State Management
- [ ] When operation is in progress:
  - [ ] Show progress indicator with descriptive message
  - [ ] Disable all backup/restore/import/export buttons
  - [ ] Set loading state in ViewModel
  - [ ] Prevent navigation away from Settings (optional)
- [ ] When operation completes:
  - [ ] Clear loading state
  - [ ] Re-enable buttons
  - [ ] Update last backup timestamp if applicable
  - [ ] Show success/failure message
  - [ ] Provide haptic feedback

### Data Integrity
- [ ] No partial backup/restore/import allowed - atomic operations only
- [ ] Validate data after writing to ensure file was written correctly
- [ ] Use transactions if database supports them
- [ ] Verify file exists and is readable before attempting restore/import
- [ ] Calculate and verify file checksums for critical operations (optional but recommended)

### Compatibility and Versioning
- [ ] Include schema version in every backup/export file
- [ ] Define current schema version as constant in code
- [ ] Implement schema migration logic for backwards compatibility
- [ ] Warn users if importing from newer schema version
- [ ] Consider forward compatibility: ignore unknown fields rather than failing

### Performance Considerations
- [ ] Stream large files rather than loading entirely into memory
- [ ] Show progress updates for operations taking >2 seconds
- [ ] Consider background refresh for automatic backups
- [ ] Don't block app launch with backup/restore operations
- [ ] Optimize JSON encoding/decoding for large datasets (consider JSONEncoder.outputFormatting)

## Example JSON Structure

```json
{
  "metadata": {
    "createdAt": "2026-01-11T14:30:00Z",
    "appVersion": "2026.1.1",
    "deviceName": "iPhone 15 Pro",
    "databaseSchemaVersion": 1
  },
  "cars": [
    {
      "id": 1,
      "name": "Tesla Model 3",
      "selectedForTracking": true,
      "batteryCapacity": 60.0,
      "expenseCurrency": "USD",
      "currentMileage": 15000,
      "initialMileage": 0,
      "milleageSyncedAt": "2026-01-11T12:00:00Z",
      "createdAt": "2024-06-01T10:00:00Z"
    }
  ],
  "expenses": [
    {
      "id": 1,
      "date": "2026-01-10T18:30:00Z",
      "energyCharged": 45.5,
      "chargerType": "home7kW",
      "odometer": 14950,
      "cost": "12.50",
      "notes": "Home charging overnight",
      "isInitialRecord": false,
      "expenseType": "charging",
      "currency": "USD",
      "carId": 1
    }
  ],
  "plannedMaintenance": [
    {
      "id": 1,
      "carId": 1,
      "description": "Tire rotation",
      "scheduledDate": "2026-02-15T10:00:00Z",
      "isCompleted": false
    }
  ],
  "delayedNotifications": [
    {
      "id": "notification-uuid-1",
      "title": "Maintenance reminder",
      "body": "Time for tire rotation",
      "scheduledDate": "2026-02-14T09:00:00Z"
    }
  ],
  "userSettings": {
    "preferredCurrency": "USD",
    "preferredLanguage": "en"
  }
}
```

## Testing Requirements (not in scope)

### Unit Tests
- [ ] Test JSON encoding of all data models
- [ ] Test JSON decoding of all data models
- [ ] Test schema version compatibility logic
- [ ] Test data validation (invalid dates, negative numbers, etc.)
- [ ] Test file path construction for all directories
- [ ] Test backup cleanup logic (5 file limit, 30-day retention)
- [ ] Test safety backup creation and restoration
- [ ] Test error handling for each error scenario

### Integration Tests
- [ ] Test full export flow with real data
- [ ] Test full import flow with validation and rollback
- [ ] Test manual backup to iCloud
- [ ] Test restore from iCloud backup
- [ ] Test automatic backup scheduling
- [ ] Test handling of iCloud sync conflicts
- [ ] Test offline mode behavior
- [ ] Test concurrent operation prevention

### UI Tests
- [ ] Test export button opens share sheet
- [ ] Test import button opens file picker
- [ ] Test backup list modal displays correct data
- [ ] Test progress indicators appear during operations
- [ ] Test buttons are disabled during operations
- [ ] Test error alerts display with correct messages
- [ ] Test confirmation dialogs for destructive actions

### Edge Cases to Test
- [ ] Import file with missing fields
- [ ] Import file with extra unknown fields (forward compatibility)
- [ ] Import file from newer schema version
- [ ] Import file from much older schema version
- [ ] Very large export (1000+ expenses)
- [ ] Empty database export/import
- [ ] iCloud storage full scenario
- [ ] Network loss during iCloud operation
- [ ] User signs out of iCloud during operation
- [ ] App termination during backup/restore
- [ ] Import fails halfway (ensure rollback works)
- [ ] Multiple devices creating backups simultaneously

## Implementation Checklist

### Phase 1: Core Export/Import
- [ ] Create data models with Codable conformance
- [ ] Implement JSON encoder/decoder
- [ ] Create export functionality with share sheet
- [ ] Create import functionality with file picker
- [ ] Add pre-import validation
- [ ] Add safety backup before import
- [ ] Add rollback on import failure
- [ ] Add progress indicators
- [ ] Add error handling
- [ ] Write unit tests

### Phase 2: iCloud Backup
- [ ] Enable iCloud capability in Xcode
- [ ] Create iCloud file manager service
- [ ] Implement backup creation
- [ ] Implement backup listing
- [ ] Implement restore from backup
- [ ] Add backup cleanup (5 files, 30 days)
- [ ] Add iCloud availability checks
- [ ] Add network connectivity checks
- [ ] Write integration tests

### Phase 3: Automatic Backup
- [ ] Register background task in Info.plist
- [ ] Implement BGTaskScheduler setup
- [ ] Create daily backup task
- [ ] Handle background task expiration
- [ ] Add retry logic for failed automatic backups
- [ ] Test background execution

### Phase 4: UI Implementation
- [ ] Create "Backup & Restore" section in Settings
- [ ] Add export button with share sheet
- [ ] Add import button with file picker
- [ ] Add manual backup button
- [ ] Add backup history button and modal
- [ ] Add delete all backups button
- [ ] Add automatic backup toggle
- [ ] Add last backup timestamp label
- [ ] Add progress indicators
- [ ] Add error alerts
- [ ] Add confirmation dialogs
- [ ] Add haptic feedback
- [ ] Add SF Symbol icons

### Phase 5: Localization
- [ ] Localize all UI strings
- [ ] Localize all error messages
- [ ] Localize date/time formats
- [ ] Test in all supported languages (en, ru, kk, tr, de)

### Phase 6: Testing & Polish (not in scope)
- [ ] Run all unit tests
- [ ] Run all integration tests
- [ ] Run all UI tests
- [ ] Test on physical devices (iPhone, iPad)
- [ ] Test in dark mode
- [ ] Test with VoiceOver (accessibility)
- [ ] Test with large datasets
- [ ] Test offline scenarios
- [ ] Test iCloud edge cases
- [ ] Performance testing
- [ ] Beta testing with real users

## Security and Privacy Considerations

- [ ] Don't include sensitive authentication tokens in backups
- [ ] Inform users that backup files are not encrypted (in help text)
- [ ] Files in app Documents directory are encrypted at rest by iOS
- [ ] Files in iCloud are encrypted in transit and at rest by Apple
- [ ] Don't log sensitive user data (costs, odometer readings, notes)
- [ ] Ensure temp files are cleaned up after export
- [ ] Consider adding optional password protection for exports (future enhancement)

## Accessibility

- [ ] All buttons have accessibility labels
- [ ] Progress indicators have accessibility announcements
- [ ] Error alerts are announced by VoiceOver
- [ ] Backup list is navigable with VoiceOver
- [ ] Support Dynamic Type for all text
- [ ] Ensure sufficient color contrast in both light and dark mode
- [ ] Provide haptic feedback for success/error states (benefits users with hearing impairments)
