# Export/Import and Backup Features

Date: 2026-01-11

Overview: The app should have the following features:

- Export data to a file
- Import data from a file
- Backup data to iCloud
- Restore data from iCloud

## 1. Export Data to a File

The app should allow the user to export data to a file. The file should be a JSON file containing all following data:

- [ ] Creation datetime
- [ ] Current version of the app
- [ ] Device name
- [ ] Database schema version
- [ ] Cars
- [ ] Expenses
- [ ] Planned Maintenance records
- [ ] Delayed Notifications
- [ ] User Settings

## 2. Import Data from a File

Requirements:
- [ ] The app should allow the user to import data from a file.
- [ ] The file should be a JSON file describing the data in the same format as the export file.
- [ ] The import should overwrite the existing data in the app wiping out all existing data before.
- [ ] If the import file contains data that is not supported by the app, the app should ignore it.
- [ ] The file might be stored in icloud folder or iPhone folder, so there should be a way to select the source folder in the app
- [ ] Document Picker: the SwiftUI file chooser should be used to select the source file.
- [ ] By default, the folder is /documents/ev_charging_tracker/export_data in the iCloud folder. If folder does not exist, it should be created.
- [ ] No partial import is allowed. The import should overwrite the existing data in the app wiping out all existing data before.

## 3. Backup Data to iCloud

- [ ] The app should allow the user to backup data to iCloud. There should be a button on the Settings screen to trigger the backup.
- [ ] The backup should be a JSON file containing all following data:
    - [ ] Cars
    - [ ] Expenses
    - [ ] Planned Maintenance records
    - [ ] Delayed Notifications
    - [ ] User Settings
- [ ] The backup should be stored in the iCloud folder.
- [ ] The backup should be stored in a file named "ev_charging_tracker_backup.json". In case of dev environment, the file name should be "ev_charging_tracker_backup_dev.json".
- [ ] There should be a button to restore the backup from iCloud.
- [ ] There should be a button to delete the backup from iCloud.
- [ ] Backup file should have a timestamp in the file name.
- [ ] There should be automatic cleanup of backup files older than 30 days.
- [ ] There should be maximum 5 backup files stored in the iCloud folder.
- [ ] There should be an automatic backup every day at 12:00 AM.
- [ ] There should be a way to manually trigger the backup from Settings View.
- [ ] In case of iCloud storage is full, the app should show a notification to the user and stop the backup.

## UI/UX Guidelines

- [ ] The backup and respore functionality should be accessible from the Settings View.
- [ ] The backup and restore functionality should be placed to own Section in the Settings View.
- [ ] There should be a button to trigger the backup.
- [ ] There should be a button to restore the backup.
- [ ] There should be a button to delete all backups. User should be prompted for confirmation before deleting all backups.
- [ ] There should be a button to view the backup files list on modal dialog view.
- [ ] There should be a progress indicator shown during the backup and restore process.

## Technical Requirements

- [ ] Not filesize limit for the backup and import files.
- [ ] No file encryption is required for the backup and import files.
- [ ] Backup file and export file should be stored in the same JSOn format and they should be same (and compatible).
- [ ] The creation datetime of the backup/export should be a part of the JSON structure as well.
- [ ] The current version of the app should be a part of the JSON structure as well.
- [ ] The device name should be a part of the JSON structure as well.
- [ ] The database schema version should be a part of the JSON structure as well.
- [ ] The app should be able to handle the backup and import files in the same format and they should be same (and compatible).
- [ ] In case of offline mode, the app should tell about it to user and then to not do anything that user triggered.
- [ ] When app is working on backup or restore process, the app should show a progress indicator and a message to the user. In addition, buttons "Backup" and "Restore" should be disabled till the process is completed or failed.
- [ ] In case of backup/restore process is failed, the app should show a notification to the user and stop the backup. The reason of the failure should be shown to the user.
- [ ] When backup is finished successfully, the app should show label under Backup section in Settings View with success message and the timestamp of the backup. No notifications should be shown to the user.
- [ ] No partial backup/restore is allowed. The backup/restore should overwrite the existing data in the app wiping out all existing data before.
- [ ] Export file schema is JSON
