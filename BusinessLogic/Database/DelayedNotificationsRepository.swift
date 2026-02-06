//
//  DelayedNotificationsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 14.11.2025.
//

@_exported import SQLite
import Foundation
import os

protocol DelayedNotificationsRepositoryProtocol {
    func getRecordByMaintenanceId(_ maintenanceRecordId: Int64) -> DelayedNotification?
    func insertRecord(_ record: DelayedNotification) -> Int64?
    func deleteRecord(id recordId: Int64) -> Bool
}

class DelayedNotificationsRepository : DelayedNotificationsRepositoryProtocol {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let whenColumn = Expression<Date>("when")
    private let maintenanceRecordIdColumn = Expression<Int64?>("maintenance_record_id")
    private let notificationIdColumn = Expression<String>("notification_id")
    private let carIdColumn = Expression<Int64>("car_id")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "DelayedNotificationsRepository")
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
            logger.error("Fetch failed: \(error)")
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
            logger.error("Fetch by notification ID failed: \(error)")
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
            logger.info("Inserted record with id: \(rowId)")

            return rowId
        } catch {
            logger.error("Insert failed: \(error)")
            return nil
        }
    }

    func recordsCount() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to get records count: \(error)")
            return 0
        }
    }
    
    func updateRecord(_ record: DelayedNotification) -> Bool {
        guard let recordId = record.id else {
            logger.error("Update failed: record id is nil")
            return false
        }
        let recordToUpdate = table.filter(id == recordId)
        
        do {
            try db.run(recordToUpdate.update(
                whenColumn <- record.when,
                maintenanceRecordIdColumn <- record.maintenanceRecord,
            ))

            logger.info("Updated record with id: \(recordId)")
            return true
        } catch {
            logger.error("Update failed: \(error)")
            return false
        }
    }

    func deleteRecord(id recordId: Int64) -> Bool {
        let recordToDelete = table.filter(id == recordId)
        
        do {
            try db.run(recordToDelete.delete())
            logger.info("Deleted record with id: \(recordId)")
            return true
        } catch {
            logger.error("Delete failed: \(error)")
            return false
        }
    }

    func truncateTable() -> Void {
        do {
            try db.run(table.delete())
            logger.info("Table truncated successfully")
        } catch {
            logger.error("Unable to truncate table: \(error)")
        }
    }

    func deleteMaintenanceRelatedNotificationIfExists(maintenanceRecordId: Int64) -> Void {
        guard let record = getRecordByMaintenanceId(maintenanceRecordId),
              let recordId = record.id
        else {
            return
        }

        _ = deleteRecord(id: recordId)
    }
}
