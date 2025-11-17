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
    private let whenColumn = Expression<Date?>("when")
    private let odometerColumn = Expression<Int?>("odometer")
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

    func getRecordsCountForOdometerValue(carCurrentMileage: Int) -> Int {

        let query = table.filter(odometerColumn != nil && odometerColumn <= carCurrentMileage).count

        do {
            return try db.scalar(query)
        } catch {
            print("Failed to get records count: \(error)")
            return 0
        }
    }
 
    func getAllRecords(carId: Int64) -> [PlannedMaintenance] {
        var recordsList: [PlannedMaintenance] = []

        do {
            for record in try db.prepare(table.filter(carIdColumn == carId).order(id.desc)) {

                let recordItem = PlannedMaintenance(
                    id: record[id],
                    when: record[whenColumn],
                    odometer: record[odometerColumn],
                    name: record[nameColumn],
                    notes: record[notesColumn],
                    carId: record[carIdColumn],
                    createdAt: record[createdAtColumn]
                )

                recordsList.append(recordItem)
            }
        } catch {
            print("Fetch failed: \(error)")
        }

        return recordsList
    }

    func insertRecord(_ record: PlannedMaintenance) -> Int64? {
        
        do {
            let insert = table.insert(
                whenColumn <- record.when,
                odometerColumn <- record.odometer,
                nameColumn <- record.name,
                notesColumn <- record.notes,
                carIdColumn <- record.carId,
                createdAtColumn <- record.createdAt
            )

            let rowId = try db.run(insert)
            print("Inserted record with id: \(rowId)")

            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }

    func truncateTable() -> Void {
        do {
            try db.run(table.delete())
            print("Table truncated successfully")
        } catch {
            print("Unable to truncate table: \(error)")
        }
    }

    func recordsCount() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            print("Failed to get records count: \(error)")
            return 0
        }
    }

    func updateRecord(_ record: PlannedMaintenance) -> Bool {
        let recordId = record.id ?? 0
        let recordToUpdate = table.filter(id == recordId)
        
        do {
            try db.run(recordToUpdate.update(
                whenColumn <- record.when,
                odometerColumn <- record.odometer,
                nameColumn <- record.name,
                notesColumn <- record.notes
            ))
            print("Updated record with id: \(recordId)")
            return true
        } catch {
            print("Update failed: \(error)")
            return false
        }
    }

    func deleteRecordsForCar(_ carId: Int64) -> Void {
        let recordsToDelete = table.filter(carIdColumn == carId)
        do {
            try db.run(recordsToDelete.delete())
            print("Deleted records for car id: \(carId)")
        } catch {
            print("Delete failed: \(error)")
        }
    }

    func deleteRecord(id recordId: Int64) -> Bool {
        let recordToDelete = table.filter(id == recordId)
        
        do {
            try db.run(recordToDelete.delete())
            print("Deleted record with id: \(recordId)")
            return true
        } catch {
            print("Delete failed: \(error)")
            return false
        }
    }

    func getPendingMaintenanceRecords(
        carId: Int64,
        currentOdometer: Int,
        currentDate: Date) -> Int {
        var result = 0

        do {
            result = try db.scalar(
                table
                    .filter(carIdColumn == carId)
                    .filter(
                         whenColumn != nil && whenColumn <= currentDate ||
                         odometerColumn != nil && odometerColumn <= currentOdometer)
                    .count)
        } catch {
            print("Fetch failed: \(error)")
        }

        return result
    }
}
