# Developer Mode Feature

## Overview
Developer Mode is a hidden feature that allows access to additional debugging tools and testing options in the app. This mode is stored in memory only and will be reset when the app is closed.

## How to Enable Developer Mode

1. Navigate to **User Settings**
2. Scroll down to the **About app** section
3. Tap on the **App version** label **15 times** consecutively
4. An alert will appear confirming that Developer Mode has been activated
5. A new "Developer Mode: Enabled" indicator will appear in the About app section
6. A new "Developer section" will appear below with testing tools

## Features Available in Developer Mode

When Developer Mode is enabled, you'll have access to:

- **Disable Developer Mode** - Turn off developer mode manually
- **Request Permission** - Test notification permission requests
- **Send Notification Now** - Send a test notification immediately
- **Schedule for 5 seconds** - Schedule a test notification for 5 seconds later
- **Add random expenses** - Populate the database with random test expenses
- **Delete car expenses** - Remove all expenses for the selected car
- **Delete all data** - Wipe all data including cars, expenses, and maintenance records

## How to Disable Developer Mode

There are two ways to disable Developer Mode:

1. **Manual:** Tap the "Disable Developer Mode" button in the Developer section
2. **Automatic:** Close and reopen the app (developer mode is not persisted)

## Technical Implementation

- **Manager:** `DeveloperModeManager` (singleton)
- **Storage:** In-memory only (lost on app termination)
- **View:** `UserSettingsView`
- **Activation:** 15 consecutive taps on the version label

## Notes

- Developer Mode is separate from the build environment's development mode
- Build development mode (`isDevelopmentMode()`) checks the build configuration
- User-activated Developer Mode (`isDeveloperModeEnabled`) is session-only
- Both modes will show the Developer section when active
- The "Disable Developer Mode" button only appears for user-activated mode, not build development mode
