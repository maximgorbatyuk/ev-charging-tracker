//
//  MigrationsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

@_exported import SQLite
import Foundation

class MigrationsRepository {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let date = Expression<Date>("date")
    
    private var db: Connection
    
    init(db: Connection, tableName: String) {
        self.db = db
        self.table = Table(tableName)
    }

    func createTableIfNotExists() -> Void {
        let command = table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(date)
        }

        do {
            try db.run(command)
            print("Table created successfully")
        } catch {
            print("Unable to create table: \(error)")
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
            print("Fetch failed: \(error)")
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
            print("Unable to insert row: \(error)")
        }
    }
}
