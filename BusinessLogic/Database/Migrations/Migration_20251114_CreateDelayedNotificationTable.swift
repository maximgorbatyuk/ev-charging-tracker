//
//  Migration_20251114_CreateDelayedNotificationTable.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.11.2025.
//

@_exported import SQLite
import Foundation
import os

final class Migration_20251114_CreateDelayedNotificationTable {
    private let migrationName = "20251114_CreateDelayedNotificationTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }
    
    func execute() {
        let repository = DelayedNotificationsRepository(db: db, tableName: DatabaseManager.DelayedNotificationsTableName)
        let logger = Logger()

        do {
            let createCommand = repository.getCreateTableCommand()
            try db.run(createCommand)
            logger.info("Table created successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }
}
