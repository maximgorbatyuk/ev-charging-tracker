//
//  Migration_20260624_AddHybridCarSupport.swift
//  EVChargingTracker
//
//  Schema v9: hybrid car support. Adds `car_type` to cars (default "electric"
//  so existing cars behave unchanged) and the gasoline fuel columns
//  (`fuel_type`, `fuel_volume`) to the expenses table. Price-per-unit is never
//  stored — it is derived from cost / fuel_volume. See ExpenseModels.swift.
//

import SQLite
import Foundation
import os

class Migration_20260624_AddHybridCarSupport {

    private let migrationName = "20260624_AddHybridCarSupport"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "com.evchargingtracker.database", category: "Migration")

        do {
            try addCarTypeColumn(logger: logger)
            try addFuelColumns(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func addCarTypeColumn(logger: Logger) throws {
        let columnName = "car_type"

        // Fresh installs reach this migration with the column already created
        // by `CarRepository.getCreateTableCommand()`, so skip ADD COLUMN to
        // avoid a "duplicate column" error.
        if try columnExists(named: columnName, in: DatabaseManager.CarsTableName) {
            logger.debug("Column \(columnName) already exists; skipping ADD COLUMN")
            return
        }

        let carsTable = Table(DatabaseManager.CarsTableName)
        let addColumn = carsTable.addColumn(
            Expression<String>(columnName),
            defaultValue: CarType.electric.rawValue
        )
        try db.run(addColumn)
        logger.debug("\(columnName) column added to cars table successfully")
    }

    private func addFuelColumns(logger: Logger) throws {
        let expensesTable = Table(DatabaseManager.ExpensesTableName)

        // The expenses createTable() stays frozen at the v1 baseline, so these
        // columns never pre-exist and need no columnExists guard.
        try db.run(expensesTable.addColumn(Expression<String?>("fuel_type")))
        try db.run(expensesTable.addColumn(Expression<Double?>("fuel_volume")))
        logger.debug("fuel_type and fuel_volume columns added to expenses table successfully")
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
