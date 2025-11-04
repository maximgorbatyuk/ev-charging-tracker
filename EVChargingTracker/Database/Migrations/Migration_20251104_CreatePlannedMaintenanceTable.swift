//
//  Migration_20251104_CreatePlannedMaintenanceTable.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

@_exported import SQLite
import Foundation

final class Migration_20251104_CreatePlannedMaintenanceTable {
    private let migrationName = "20251104_CreatePlannedMaintenanceTable"
    private let db: Connection
    init(db: Connection) {
        self.db = db
    }
    
    func execute() {
        let plannedMaintenanceTable = Table(DatabaseManager.PlannedMaintenanceTableName)
        let repository = PlannedMaintenanceRepository(db: db, tableName: DatabaseManager.PlannedMaintenanceTableName)

        do {
            let createCommand = repository.getCreateTableCommand()
            try db.run(createCommand)
            print("Planned maintenance table created successfully")
        } catch {
            print("Unable to exeucte migration \(migrationName): \(error)")
        }
    }
}
