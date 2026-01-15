//
//  BackgroundTaskManager.swift
//  EVChargingTracker
//
//  Created by Claude Code on 2026-01-12.
//

import Foundation
import BackgroundTasks
import os.log

/// Manages background task scheduling for automatic iCloud backups
@MainActor
final class BackgroundTaskManager: ObservableObject {

    // MARK: - Constants

    /// Background task identifier - must match Info.plist
    static let dailyBackupTaskIdentifier = "com.evchargingtracker.daily-backup"

    /// UserDefaults keys
    private enum UserDefaultsKey {
        static let automaticBackupEnabled = "automaticBackupEnabled"
        static let lastAutomaticBackupDate = "lastAutomaticBackupDate"
        static let lastBackupAttemptDate = "lastBackupAttemptDate"
        static let pendingRetry = "pendingBackupRetry"
    }

    // MARK: - Properties

    static let shared = BackgroundTaskManager()

    private let logger = Logger(subsystem: "com.evchargingtracker", category: "BackgroundTaskManager")
    private let backupService: BackupService

    @Published var isAutomaticBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutomaticBackupEnabled, forKey: UserDefaultsKey.automaticBackupEnabled)

            if isAutomaticBackupEnabled {
                scheduleNextBackup()
            } else {
                cancelAllBackupTasks()
            }
        }
    }

    @Published var lastAutomaticBackupDate: Date? {
        didSet {
            if let date = lastAutomaticBackupDate {
                UserDefaults.standard.set(date, forKey: UserDefaultsKey.lastAutomaticBackupDate)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastAutomaticBackupDate)
            }
        }
    }

    private var pendingRetry: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKey.pendingRetry) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.pendingRetry) }
    }

    // MARK: - Initialization

    private init(backupService: BackupService? = nil) {
        self.backupService = backupService ?? BackupService.shared

        // Load saved preferences
        self.isAutomaticBackupEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKey.automaticBackupEnabled)
        self.lastAutomaticBackupDate = UserDefaults.standard.object(forKey: UserDefaultsKey.lastAutomaticBackupDate) as? Date
    }

    // MARK: - Registration

    /// Register background task handler. Call this in App initialization.
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.dailyBackupTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self else {
                task.setTaskCompleted(success: false)
                return
            }

            self.logger.info("Background backup task started")

            // Handle early termination
            task.expirationHandler = {
                self.logger.warning("Background task expired before completion")
                task.setTaskCompleted(success: false)
            }

            // Perform backup
            Task { @MainActor in
                await self.handleBackgroundBackup(task: task)
            }
        }

        logger.info("Background task handler registered")
    }

    // MARK: - Scheduling

    /// Schedule the next automatic backup for midnight
    func scheduleNextBackup() {
        guard isAutomaticBackupEnabled else {
            logger.info("Automatic backup is disabled, not scheduling")
            return
        }

        // Calculate next midnight
        let calendar = Calendar.current
        let now = Date()

        // Get tomorrow's date at midnight
        guard var nextMidnight = calendar.date(byAdding: .day, value: 1, to: now) else {
            logger.error("Failed to calculate next midnight")
            return
        }

        // Set to midnight (00:00:00)
        let components = calendar.dateComponents([.year, .month, .day], from: nextMidnight)
        guard let midnight = calendar.date(from: components) else {
            logger.error("Failed to create midnight date")
            return
        }

        nextMidnight = midnight

        // Create background task request
        let request = BGAppRefreshTaskRequest(identifier: Self.dailyBackupTaskIdentifier)
        request.earliestBeginDate = nextMidnight

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled next backup for: \(nextMidnight)")
        } catch {
            logger.error("Failed to schedule background task: \(error.localizedDescription)")

            // If scheduling fails, mark for retry on next app launch
            pendingRetry = true
        }
    }

    /// Cancel all scheduled backup tasks
    func cancelAllBackupTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.dailyBackupTaskIdentifier)
        logger.info("Cancelled all scheduled backup tasks")
    }

    // MARK: - Manual Trigger

    /// Trigger an immediate automatic backup (silent, no UI feedback)
    func triggerImmediateBackup() async {
        guard isAutomaticBackupEnabled else {
            logger.info("Automatic backup is disabled, skipping immediate backup")
            return
        }

        await performSilentBackup()
    }

    // MARK: - Retry Logic

    /// Check if there's a pending retry and attempt backup if needed
    func retryIfNeeded() async {
        guard isAutomaticBackupEnabled && pendingRetry else {
            return
        }

        logger.info("Retrying failed automatic backup")
        await performSilentBackup()
    }

    // MARK: - Private Methods

    /// Handle background backup task execution
    private func handleBackgroundBackup(task: BGTask) async {
        let success = await performSilentBackup()

        // Schedule next backup
        scheduleNextBackup()

        // Mark task as completed
        task.setTaskCompleted(success: success)
    }

    /// Perform a silent automatic backup
    /// - Returns: true if backup succeeded, false otherwise
    @discardableResult
    private func performSilentBackup() async -> Bool {
        // Record attempt
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKey.lastBackupAttemptDate)

        // Check iCloud availability
        guard backupService.isiCloudAvailable() else {
            logger.warning("iCloud not available, skipping automatic backup")
            pendingRetry = true
            return false
        }

        // Perform backup
        do {
            let backupInfo = try await backupService.createiCloudBackup()

            // Update last successful backup date
            lastAutomaticBackupDate = backupInfo.createdAt
            pendingRetry = false

            logger.info("Automatic backup completed successfully: \(backupInfo.fileName)")
            return true

        } catch {
            logger.error("Automatic backup failed: \(error.localizedDescription)")
            pendingRetry = true
            return false
        }
    }
}
