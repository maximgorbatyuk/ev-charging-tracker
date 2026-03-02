//
//  IdeasRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

@_exported import SQLite
import Foundation
import os

protocol IdeasRepositoryProtocol {
    func getAllRecords(carId: Int64) -> [Idea]
    func getLatestRecords(carId: Int64, limit: Int) -> [Idea]
    func getRecordsCount(carId: Int64) -> Int
    func insertRecord(_ record: Idea) -> Int64?
    func updateRecord(_ record: Idea) -> Bool
    func deleteRecord(id recordId: Int64) -> Bool
    func deleteRecordsForCar(_ carId: Int64)
}

class IdeasRepository: IdeasRepositoryProtocol {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let carIdColumn = Expression<Int64>("car_id")
    private let titleColumn = Expression<String>("title")
    private let urlColumn = Expression<String?>("url")
    private let descriptionColumn = Expression<String?>("description")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: tableName, category: "Database")
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(carIdColumn)
            t.column(titleColumn)
            t.column(urlColumn)
            t.column(descriptionColumn)
            t.column(createdAtColumn)
            t.column(updatedAtColumn)
        }
    }

    func getCreateIndexCommands() -> [String] {
        return [
            table.createIndex(carIdColumn, ifNotExists: true),
            table.createIndex(updatedAtColumn, ifNotExists: true)
        ]
    }

    func getAllRecords(carId: Int64) -> [Idea] {
        var records: [Idea] = []
        do {
            for row in try db.prepare(table.filter(carIdColumn == carId).order(updatedAtColumn.desc)) {
                records.append(mapRow(row))
            }
        } catch {
            logger.error("Fetch all ideas failed: \(error)")
        }
        return records
    }

    func getLatestRecords(carId: Int64, limit: Int) -> [Idea] {
        var records: [Idea] = []
        do {
            let query = table
                .filter(carIdColumn == carId)
                .order(updatedAtColumn.desc)
                .limit(limit)
            for row in try db.prepare(query) {
                records.append(mapRow(row))
            }
        } catch {
            logger.error("Fetch latest ideas failed: \(error)")
        }
        return records
    }

    func getRecordsCount(carId: Int64) -> Int {
        do {
            return try db.scalar(table.filter(carIdColumn == carId).count)
        } catch {
            logger.error("Ideas count failed: \(error)")
            return 0
        }
    }

    func insertRecord(_ record: Idea) -> Int64? {
        do {
            let rowId = try db.run(table.insert(
                carIdColumn <- record.carId,
                titleColumn <- record.title,
                urlColumn <- record.url,
                descriptionColumn <- record.descriptionText,
                createdAtColumn <- record.createdAt,
                updatedAtColumn <- record.updatedAt
            ))
            return rowId
        } catch {
            logger.error("Insert idea failed: \(error)")
            return nil
        }
    }

    func updateRecord(_ record: Idea) -> Bool {
        guard let recordId = record.id else {
            logger.error("Update idea failed: id is nil")
            return false
        }
        do {
            try db.run(table.filter(id == recordId).update(
                titleColumn <- record.title,
                urlColumn <- record.url,
                descriptionColumn <- record.descriptionText,
                updatedAtColumn <- Date()
            ))
            return true
        } catch {
            logger.error("Update idea failed: \(error)")
            return false
        }
    }

    func deleteRecord(id recordId: Int64) -> Bool {
        do {
            try db.run(table.filter(id == recordId).delete())
            return true
        } catch {
            logger.error("Delete idea failed: \(error)")
            return false
        }
    }

    func deleteRecordsForCar(_ carId: Int64) {
        do {
            try db.run(table.filter(carIdColumn == carId).delete())
        } catch {
            logger.error("Delete ideas for car failed: \(error)")
        }
    }

    func truncateTable() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Truncate ideas failed: \(error)")
        }
    }

    private func mapRow(_ row: Row) -> Idea {
        Idea(
            id: row[id],
            carId: row[carIdColumn],
            title: row[titleColumn],
            url: row[urlColumn],
            descriptionText: row[descriptionColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
