//
//  Migration_20251114_CreateDelayedNotificationTable.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.11.2025.
//

@_exported import SQLite
import Foundation

final class Migration_20251114_CreateDelayedNotificationTable {
    private let migrationName = "20251114_CreateDelayedNotificationTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }
    
    func execute() {
        let plannedMaintenanceTable = Table(DatabaseManager.DelayedNotificationsTableName)
        let repository = DelayedNotificationsRepository(db: db, tableName: DatabaseManager.DelayedNotificationsTableName)

        do {
            let createCommand = repository.getCreateTableCommand()
            try db.run(createCommand)
            print("Table created successfully")
        } catch {
            print("Unable to execute migration \(migrationName): \(error)")
        }
    }
}
