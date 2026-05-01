//
//  Migration_20260501_AddMeasurementSystemToCarsTable.swift
//  EVChargingTracker
//
//  Schema v8: per-car measurement system (metric vs imperial). Existing
//  rows default to "metric" so previously stored mileage values render
//  identically until the user opts into imperial. See MeasurementSystem.swift.
//

import SQLite
import Foundation
import os

class Migration_20260501_AddMeasurementSystemToCarsTable {

    private let migrationName = "20260501_AddMeasurementSystemToCarsTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let carsTable = Table(DatabaseManager.CarsTableName)
        let logger = Logger(subsystem: "com.evchargingtracker.database", category: "Migration")
        let columnName = "measurement_system"

        do {
            // Fresh installs reach this migration with the column already
            // created by `CarRepository.getCreateTableCommand()` (schema v3),
            // so we must skip ADD COLUMN to avoid a "duplicate column" error.
            if try columnExists(named: columnName, in: DatabaseManager.CarsTableName) {
                logger.debug("Column \(columnName) already exists; skipping ADD COLUMN")
            } else {
                let addColumn = carsTable.addColumn(
                    Expression<String>(columnName),
                    defaultValue: MeasurementSystem.metric.rawValue
                )
                try db.run(addColumn)
                logger.debug("\(columnName) column added to cars table successfully")
            }

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    /// PRAGMA table_info(<table>) returns one row per column with `name` in
    /// the second position (cid, name, type, notnull, dflt_value, pk).
    private func columnExists(named column: String, in table: String) throws -> Bool {
        let statement = try db.prepare("PRAGMA table_info(\(table))")
        for row in statement {
            if let name = row[1] as? String, name == column {
                return true
            }
        }
        return false
    }
}
