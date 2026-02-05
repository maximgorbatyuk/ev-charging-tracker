//
//  MigrationsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

@_exported import SQLite
import Foundation
import os

class MigrationsRepository {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let date = Expression<Date>("date")
    
    private var db: Connection
    private let logger: Logger
    
    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: tableName, category: "Database")
    }

    func createTableIfNotExists() -> Void {
        let command = table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(date)
        }

        do {
            try db.run(command)
        } catch {
            logger.error("Unable to create table: \(error)")
        }
    }

    func getLatestMigrationVersion() -> Int64 {
        do {
            if let row = try db.pluck(table.select(id).order(id.desc)) {
                return row[id]
            }
        } catch {
            logger.error("Fetch failed: \(error)")
        }
        return 0
    }

    func addMigrationVersion() {
        let insertCommand = table.insert(
            date <- Date()
        )
        do {
            try db.run(insertCommand)
        } catch {
            logger.error("Unable to insert row: \(error)")
        }
    }
}
