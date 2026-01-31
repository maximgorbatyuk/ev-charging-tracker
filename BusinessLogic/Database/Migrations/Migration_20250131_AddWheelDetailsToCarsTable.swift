//
//  Migration_20250131_AddWheelDetailsToCarsTable.swift
//  EVChargingTracker
//
//  Created on 2025-01-31.
//

import SQLite
import Foundation
import os

class Migration_20250131_AddWheelDetailsToCarsTable {

    private let migrationName = "20250131_AddWheelDetailsToCarsTable"
    private let db: Connection
    
    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let carsTable = Table(DatabaseManager.CarsTableName)
        let logger = Logger(subsystem: "com.evchargingtracker.database", category: "Migration")

        do {
            let addFrontWheelSizeCommand = carsTable.addColumn(Expression<String?>("front_wheel_size"))
            try db.run(addFrontWheelSizeCommand)
            logger.debug("front_wheel_size column added to cars table successfully")

            let addRearWheelSizeCommand = carsTable.addColumn(Expression<String?>("rear_wheel_size"))
            try db.run(addRearWheelSizeCommand)
            logger.debug("rear_wheel_size column added to cars table successfully")

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }
}
