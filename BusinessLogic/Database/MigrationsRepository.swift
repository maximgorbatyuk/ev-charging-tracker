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
        var migrationsList: [SqlMigration] = []
        
        do {
            for record in try db.prepare(table.order(id.desc)) {
                
                let migration = SqlMigration(
                    id: record[id],
                    date: record[date],
                )

                migrationsList.append(migration)
            }
        } catch {
            logger.error("Fetch failed: \(error)")
        }
        
        if (migrationsList.count > 0) {
            return migrationsList[0].id ?? 0
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
