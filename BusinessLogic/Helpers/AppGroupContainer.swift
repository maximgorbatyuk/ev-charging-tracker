//
//  AppGroupContainer.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import os

enum AppGroupContainer {

    private static let logger = Logger(subsystem: "AppGroupContainer", category: "Storage")

    static var identifier: String {
        guard let identifier = EnvironmentService.shared.getAppGroupIdentifier(),
              !identifier.isEmpty else {
            logger.error("AppGroupIdentifier not found in Info.plist")
            fatalError("AppGroupIdentifier not found in Info.plist. Check xcconfig setup.")
        }
        return identifier
    }

    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            logger.error("App Group '\(identifier)' not configured. Check entitlements.")
            fatalError("App Group '\(identifier)' not configured")
        }
        return url
    }

    static var databaseURL: URL {
        containerURL.appendingPathComponent("tesla_charging.sqlite3")
    }

    static var isConfigured: Bool {
        guard let identifier = EnvironmentService.shared.getAppGroupIdentifier(),
              !identifier.isEmpty else {
            return false
        }
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }

    // MARK: - Legacy paths (pre-migration, app-private Documents)

    static var legacyDatabaseURL: URL? {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first else {
            return nil
        }
        return URL(fileURLWithPath: documentsPath)
            .appendingPathComponent("tesla_charging.sqlite3")
    }

    static var legacyDatabaseExists: Bool {
        guard let url = legacyDatabaseURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
