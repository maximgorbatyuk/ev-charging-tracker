//
//  PlannedMaintenanceRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 04.11.2025.
//

@_exported import SQLite
import Foundation

class PlannedMaintenanceRepository {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let nameColumn = Expression<String>("name")
    private let notesColumn = Expression<String>("notes")
    private let whenColumn = Expression<Date>("when")
    private let odometerColumn = Expression<Int>("odometer")
    private let createdAtColumn = Expression<Date>("created_at")
    private let carIdColumn = Expression<Int64>("car_id")

    private var db: Connection

    init(db: Connection, tableName: String) {
        self.db = db
        self.table = Table(tableName)
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nameColumn)
            t.column(notesColumn)
            t.column(whenColumn)
            t.column(odometerColumn)
            t.column(createdAtColumn)
            t.column(carIdColumn)
        }
            
    }
}
