//
//  DatabaseMigrationHelper.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import os
import SQLite

/// Handles one-time migration of the SQLite database from the app's private Documents
/// directory to the shared App Group container (required for Share Extension access).
///
/// Migration strategy (stricter than simple copy):
/// 1. Copy legacy files to temporary location inside App Group
/// 2. Validate the temporary copy can be opened and has expected schema
/// 3. Atomically move temp files to final destination
/// 4. Only clean up legacy files after validation passes
///
/// Migration marker is stored in shared `UserDefaults(suiteName:)` so both
/// the main app and the Share Extension can read it.
class DatabaseMigrationHelper {

    private static let logger = Logger(subsystem: "DatabaseMigration", category: "Migration")
    private static let migrationCompletedKey = "AppGroupMigrationCompleted"

    // MARK: - Public API

    /// Migrates database from old app container to shared App Group container.
    /// Safe to call multiple times — skips if already migrated.
    static func migrateToAppGroupIfNeeded() {
        if isMigrationCompleted() {
            logger.debug("App Group migration already completed, skipping")
            return
        }

        guard AppGroupContainer.isConfigured else {
            logger.error("App Group is not configured, cannot migrate")
            return
        }

        let fileManager = FileManager.default
        let success = migrateDatabase(fileManager: fileManager)

        if success {
            setMigrationCompleted()
            logger.info("App Group migration completed successfully")
        } else {
            logger.error("App Group migration failed — will retry on next launch")
        }
    }

    /// Whether migration has been completed (readable by both app and extension).
    static func isMigrationCompleted() -> Bool {
        return sharedDefaults?.bool(forKey: migrationCompletedKey) ?? false
    }

    /// Resets the migration flag (developer mode / QA only).
    static func resetMigrationFlag() {
        sharedDefaults?.removeObject(forKey: migrationCompletedKey)
        logger.warning("Migration flag reset — migration will run again on next launch")
    }

    // MARK: - Shared UserDefaults

    private static var sharedDefaults: UserDefaults? {
        guard let identifier = EnvironmentService.shared.getAppGroupIdentifier(),
              !identifier.isEmpty else {
            return nil
        }
        return UserDefaults(suiteName: identifier)
    }

    private static func setMigrationCompleted() {
        sharedDefaults?.set(true, forKey: migrationCompletedKey)
    }

    // MARK: - Database migration

    /// Returns `true` when the shared container is ready (migration succeeded, fresh install, or already migrated).
    /// Returns `false` only when something went wrong and migration should be retried.
    private static func migrateDatabase(fileManager: FileManager) -> Bool {
        guard let legacyURL = AppGroupContainer.legacyDatabaseURL else {
            logger.info("Could not determine legacy database path")
            return true // Nothing to migrate, safe to mark complete
        }

        let destinationURL = AppGroupContainer.databaseURL

        // No legacy database — fresh install, nothing to migrate
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            logger.info("No legacy database found at \(legacyURL.path), skipping")
            return true
        }

        // Shared DB already exists — validate it and clean up legacy if valid
        if fileManager.fileExists(atPath: destinationURL.path) {
            logger.info("Database already exists in App Group container")
            if validateDatabase(at: destinationURL) {
                cleanupLegacyFiles(fileManager: fileManager, legacyURL: legacyURL)
                return true
            } else {
                logger.error("Existing shared DB failed validation — keeping legacy DB intact")
                return false
            }
        }

        // Perform safe migration: copy to temp → validate → atomic move
        let tempURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent("tesla_charging_migration_temp.sqlite3")

        do {
            // Clean up any leftover temp files from a previous failed attempt
            removeIfExists(fileManager: fileManager, url: tempURL)
            removeIfExists(fileManager: fileManager, url: walURL(for: tempURL))
            removeIfExists(fileManager: fileManager, url: shmURL(for: tempURL))

            // Step 1: Copy legacy files to temp location
            try fileManager.copyItem(at: legacyURL, to: tempURL)
            logger.debug("Copied legacy DB to temp location")

            copyJournalFileIfExists(fileManager: fileManager,
                                    from: walURL(for: legacyURL),
                                    to: walURL(for: tempURL))
            copyJournalFileIfExists(fileManager: fileManager,
                                    from: shmURL(for: legacyURL),
                                    to: shmURL(for: tempURL))

            // Step 2: Validate temp copy
            guard validateDatabase(at: tempURL) else {
                logger.error("Temp copy failed validation — aborting migration, legacy DB untouched")
                removeIfExists(fileManager: fileManager, url: tempURL)
                removeIfExists(fileManager: fileManager, url: walURL(for: tempURL))
                removeIfExists(fileManager: fileManager, url: shmURL(for: tempURL))
                return false
            }

            // Step 3: Atomic move from temp to final destination
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            moveJournalFileIfExists(fileManager: fileManager,
                                    from: walURL(for: tempURL),
                                    to: walURL(for: destinationURL))
            moveJournalFileIfExists(fileManager: fileManager,
                                    from: shmURL(for: tempURL),
                                    to: shmURL(for: destinationURL))

            logger.info("Database migrated to App Group container")

            // Step 4: Clean up legacy files
            cleanupLegacyFiles(fileManager: fileManager, legacyURL: legacyURL)
            return true

        } catch {
            logger.error("Migration failed: \(error.localizedDescription) — legacy DB untouched")
            // Clean up any partial temp files
            removeIfExists(fileManager: fileManager, url: tempURL)
            removeIfExists(fileManager: fileManager, url: walURL(for: tempURL))
            removeIfExists(fileManager: fileManager, url: shmURL(for: tempURL))
            return false
        }
    }

    // MARK: - Validation

    /// Opens the database and checks that the `migrations` table exists as a schema marker.
    private static func validateDatabase(at url: URL) -> Bool {
        do {
            let db = try Connection(url.path, readonly: true)
            let tableCount = try db.scalar(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='migrations'"
            ) as? Int64 ?? 0

            if tableCount > 0 {
                logger.debug("Database validation passed at \(url.lastPathComponent)")
                return true
            } else {
                logger.warning("Database at \(url.lastPathComponent) missing 'migrations' table")
                return false
            }
        } catch {
            logger.error("Database validation failed at \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Journal file helpers

    private static func walURL(for dbURL: URL) -> URL {
        dbURL.appendingPathExtension("wal")
    }

    private static func shmURL(for dbURL: URL) -> URL {
        dbURL.appendingPathExtension("shm")
    }

    private static func copyJournalFileIfExists(fileManager: FileManager, from source: URL, to destination: URL) {
        guard fileManager.fileExists(atPath: source.path) else { return }
        do {
            try fileManager.copyItem(at: source, to: destination)
            logger.debug("Copied journal file: \(source.lastPathComponent)")
        } catch {
            logger.warning("Failed to copy journal file \(source.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func moveJournalFileIfExists(fileManager: FileManager, from source: URL, to destination: URL) {
        guard fileManager.fileExists(atPath: source.path) else { return }
        do {
            try fileManager.moveItem(at: source, to: destination)
            logger.debug("Moved journal file: \(source.lastPathComponent)")
        } catch {
            logger.warning("Failed to move journal file \(source.lastPathComponent): \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup

    private static func cleanupLegacyFiles(fileManager: FileManager, legacyURL: URL) {
        let files = [legacyURL, walURL(for: legacyURL), shmURL(for: legacyURL)]
        for file in files {
            removeIfExists(fileManager: fileManager, url: file)
        }
        logger.debug("Legacy database files cleaned up")
    }

    private static func removeIfExists(fileManager: FileManager, url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            logger.warning("Failed to remove \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
