//
//  Migration_20251104_CreatePlannedMaintenanceTable.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

@_exported import SQLite
import Foundation
import os

final class Migration_20251104_CreatePlannedMaintenanceTable {
    private let migrationName = "20251104_CreatePlannedMaintenanceTable"
    private let db: Connection
    init(db: Connection) {
        self.db = db
    }
    
    func execute() {
        let repository = PlannedMaintenanceRepository(db: db, tableName: DatabaseManager.PlannedMaintenanceTableName)

        let logger = Logger()
        do {
            let createCommand = repository.getCreateTableCommand()
            try db.run(createCommand)
            logger.debug("Planned maintenance table created successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }
}
