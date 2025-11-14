//
//  DelayedNotificationsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.11.2025.
//

@_exported import SQLite
import Foundation

class DelayedNotificationsRepository {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let whenColumn = Expression<Date>("when")
    private let maintenanceRecordIdColumn = Expression<Int64?>("maintenance_record_id")
    private let notificationIdColumn = Expression<String>("notification_id")
    private let carIdColumn = Expression<Int64>("car_id")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection

    init(db: Connection, tableName: String) {
        self.db = db
        self.table = Table(tableName)
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(whenColumn)
            t.column(notificationIdColumn)
            t.column(maintenanceRecordIdColumn)
            t.column(carIdColumn)
            t.column(createdAtColumn)
        }
    }

    func getAllRecords(carId: Int64) -> [DelayedNotification] {
        var recordsList: [DelayedNotification] = []

        do {
            for record in try db.prepare(table.filter(carIdColumn == carId).order(id.desc)) {

                let recordItem = DelayedNotification(
                    id: record[id],
                    when: record[whenColumn],
                    notificationId: record[notificationIdColumn],
                    maintenanceRecord: record[maintenanceRecordIdColumn],
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

    func getRecordByMaintenanceId(_ maintenanceRecordId: Int64) -> DelayedNotification? {
        let query = table.filter(maintenanceRecordIdColumn == maintenanceRecordId)
        do {
            if let record = try db.pluck(query) {
                let recordItem = DelayedNotification(
                    id: record[id],
                    when: record[whenColumn],
                    notificationId: record[notificationIdColumn],
                    maintenanceRecord: record[maintenanceRecordIdColumn],
                    carId: record[carIdColumn],
                    createdAt: record[createdAtColumn]
                )
                return recordItem
            }
            return nil
        } catch {
            print("Fetch by notification ID failed: \(error)")
            return nil
        }
    }

    func insertRecord(_ record: DelayedNotification) -> Int64? {
        
        do {
            let insert = table.insert(
                whenColumn <- record.when,
                notificationIdColumn <- record.notificationId,
                maintenanceRecordIdColumn <- record.maintenanceRecord,
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

    func recordsCount() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            print("Failed to get records count: \(error)")
            return 0
        }
    }
    
    func updateRecord(_ record: DelayedNotification) -> Bool {
        let recordId = record.id ?? 0
        let recordToUpdate = table.filter(id == recordId)
        
        do {
            try db.run(recordToUpdate.update(
                whenColumn <- record.when,
                maintenanceRecordIdColumn <- record.maintenanceRecord,
            ))

            print("Updated record with id: \(recordId)")
            return true
        } catch {
            print("Update failed: \(error)")
            return false
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

    func deleteMaintenanceRelatedNotificationIfExists(maintenanceRecordId: Int64) -> Void {
        let recordToDelete = getRecordByMaintenanceId(maintenanceRecordId)
        if (recordToDelete == nil) {
            return
        }

        _ = deleteRecord(id: recordToDelete!.id!)
    }
}
